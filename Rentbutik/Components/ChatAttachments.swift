import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers
import QuickLook

// MARK: - Storage

/// Copies picked media into the app's container so it outlives the picker.
nonisolated enum AttachmentStore {
    static let folder: URL = {
        let dir = URL.documentsDirectory.appending(path: "ChatAttachments", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func save(_ data: Data, ext: String) -> URL? {
        let url = folder.appending(path: "\(UUID().uuidString).\(ext)")
        return (try? data.write(to: url)) != nil ? url : nil
    }

    static func copy(_ source: URL) -> URL? {
        let secured = source.startAccessingSecurityScopedResource()
        defer { if secured { source.stopAccessingSecurityScopedResource() } }
        let target = folder.appending(path: "\(UUID().uuidString)-\(source.lastPathComponent)")
        return (try? FileManager.default.copyItem(at: source, to: target)) != nil ? target : nil
    }
}

/// A video from the Photos library, delivered as a file we own.
struct PickedMovie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { SentTransferredFile($0.url) } importing: { received in
            guard let copy = AttachmentStore.copy(received.file) else { throw CocoaError(.fileWriteUnknown) }
            return PickedMovie(url: copy)
        }
    }
}

// MARK: - Composer attach menu

/// "+" — Photo Library, Camera or Files, all system pickers.
struct AttachMenu: View {
    let onAttach: (MessageAttachment) -> Void

    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var showFiles = false
    @State private var picked: [PhotosPickerItem] = []
    @State private var taps = 0

    var body: some View {
        Menu {
            Button("Photo Library", systemImage: "photo.on.rectangle") { showLibrary = true }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera", systemImage: "camera") { showCamera = true }
            }
            Button("Files", systemImage: "doc") { showFiles = true }
        } label: {
            Image(systemName: "plus")
                .symbolEffect(.rotate.byLayer, value: taps)
        }
        .onTapGesture { taps += 1 }
        .buttonStyle(.rentbutik)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .accessibilityLabel("Attach")
        .photosPicker(isPresented: $showLibrary, selection: $picked, maxSelectionCount: 4,
                      matching: .any(of: [.images, .videos]))
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            Task {
                for item in items {
                    if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }),
                       let movie = try? await item.loadTransferable(type: PickedMovie.self) {
                        onAttach(.video(movie.url))
                    } else if let data = try? await item.loadTransferable(type: Data.self),
                              let url = AttachmentStore.save(data, ext: "jpg") {
                        onAttach(.photo(url))
                    }
                }
                picked = []
            }
        }
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.item],
                      allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            for source in urls {
                guard let copy = AttachmentStore.copy(source) else { continue }
                let bytes = (try? copy.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                let type = UTType(filenameExtension: copy.pathExtension)
                if type?.conforms(to: .image) == true {
                    onAttach(.photo(copy))
                } else if type?.conforms(to: .movie) == true {
                    onAttach(.video(copy))
                } else {
                    onAttach(.file(name: source.lastPathComponent, url: copy, bytes: bytes))
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCapture { onAttach($0) }
                .ignoresSafeArea()
        }
    }
}

/// The system camera — photos and video, captured live.
private struct CameraCapture: UIViewControllerRepresentable {
    let onCapture: (MessageAttachment) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCapture
        init(parent: CameraCapture) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let movie = info[.mediaURL] as? URL, let copy = AttachmentStore.copy(movie) {
                parent.onCapture(.video(copy))
            } else if let image = info[.originalImage] as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.85),
                      let url = AttachmentStore.save(data, ext: "jpg") {
                parent.onCapture(.photo(url))
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Bubbles

/// Photo, video or document inside a chat bubble. Tapping opens it in the
/// system viewer — Quick Look for photos and files, AVKit for video.
struct AttachmentBubble: View {
    let attachment: MessageAttachment
    let isFromMe: Bool

    @State private var preview: URL?
    @State private var playing = false

    var body: some View {
        Group {
            switch attachment {
            case .photo(let url):
                Button { preview = url } label: {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Theme.fill.overlay { ProgressView() }
                        }
                    }
                    .frame(width: 220, height: 220)
                    .clipShape(.rect(cornerRadius: 20))
                }
                .buttonStyle(PressScale(haptic: .open))
                .accessibilityLabel("Photo")

            case .video(let url):
                Button { playing = true } label: {
                    VideoThumbnail(url: url)
                        .frame(width: 220, height: 160)
                        .clipShape(.rect(cornerRadius: 20))
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(Theme.Font.title2)
                                .foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .glassEffect(.regular, in: .circle)
                        }
                }
                .buttonStyle(PressScale(haptic: .open))
                .accessibilityLabel("Video")
                .fullScreenCover(isPresented: $playing) {
                    VideoPlayerCover(url: url)
                }

            case .file(let name, let url, let bytes):
                Button { preview = url } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .font(Theme.Font.title2)
                            .foregroundStyle(Theme.goldText)
                            .frame(width: 44, height: 44)
                            .background(Theme.brandTint, in: .rect(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(Theme.Font.subheadlineSemibold)
                                .foregroundStyle(Theme.ink)
                                .lineLimit(2)
                            Text(Int64(bytes), format: .byteCount(style: .file))
                                .font(Theme.Font.footnoteRegular)
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: 260, alignment: .leading)
                    .background(isFromMe ? Theme.brandTint : Theme.card, in: .rect(cornerRadius: 20))
                }
                .buttonStyle(PressScale(haptic: .open))
            }
        }
        .quickLookPreview($preview)
    }
}

/// First frame of a video, generated off the main thread.
private struct VideoThumbnail: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Theme.ink.opacity(0.85)
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            }
        }
        .task {
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            if let frame = try? await generator.image(at: .zero).image {
                image = UIImage(cgImage: frame)
            }
        }
    }
}

private struct VideoPlayerCover: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .overlay(alignment: .topTrailing) {
                Button("Close", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .padding()
            }
            .onAppear {
                let p = AVPlayer(url: url)
                player = p
                p.play()
            }
            .onDisappear { player?.pause() }
    }
}

