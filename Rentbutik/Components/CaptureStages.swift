import SwiftUI
import VisionKit
import Vision

// MARK: - Guided capture (A05 documents · EV02 pre-trip photos)

/// One step of a guided capture — "ID card · front", "Front of the car".
struct CaptureStage: Identifiable, Hashable {
    let id: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    /// The strip caption — "Front", "Rear".
    let short: LocalizedStringKey
    let symbol: String
    var aspect: CGFloat = 1.6

    static func == (l: Self, r: Self) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

/// Dark camera screen: title + step, a dashed guide with the subject drawn
/// in it, the hint, a strip of steps (Added ✓ / Scanning… / Tap to scan)
/// and the shutter. Each shot "processes" briefly, like a real capture.
struct CaptureStagesView: View {
    let heading: LocalizedStringKey
    let stages: [CaptureStage]
    let hint: LocalizedStringKey
    let onCancel: () -> Void
    let onDone: () -> Void

    @State private var index = 0
    @State private var captured: Set<String> = []
    @State private var processing = false
    @State private var shots = 0
    @ScaledMetric private var shutter: CGFloat = 72

    private var stage: CaptureStage { stages[index] }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                Text(stage.title)
                    .font(Theme.Font.subheadlineSemibold)
                Text(stage.detail)
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(.secondary)
            }
            .contentTransition(.opacity)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button("Cancel", action: onCancel)
                    .font(Theme.Font.subheadlineSemibold)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, 8)

            Spacer()

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [7, 6]))
                .foregroundStyle(processing ? Theme.brandSolid : .white)
                .aspectRatio(stage.aspect, contentMode: .fit)
                .frame(maxWidth: stage.aspect < 1 ? 240 : .infinity)
                .overlay {
                    ZStack {
                        Image(systemName: stage.symbol)
                            .font(.system(size: 96))
                            .foregroundStyle(.white.opacity(0.28))
                            .contentTransition(.symbolEffect(.replace))
                        if processing {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .animation(Theme.smooth, value: stage)

            Spacer()

            Text(processing ? "Checking the photo…" : hint)
                .font(Theme.Font.subheadlineRegular)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)

            HStack(spacing: 8) {
                ForEach(Array(stages.enumerated()), id: \.element.id) { i, item in
                    Button {
                        withAnimation(Theme.smooth) { index = i }
                    } label: {
                        StageThumb(stage: item,
                                   state: captured.contains(item.id) ? .added
                                        : i == index ? .scanning : .waiting)
                    }
                    .buttonStyle(.plain)
                    .disabled(processing)
                }
            }
            .padding(8)
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.group))
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 22)

            Button(action: capture) {
                Circle()
                    .fill(.white)
                    .padding(6)
                    .overlay { Circle().strokeBorder(.white, lineWidth: 4) }
                    .frame(width: shutter, height: shutter)
                    .scaleEffect(processing ? 0.9 : 1)
            }
            .buttonStyle(PressScale(haptic: .click))
            .disabled(processing)
            .accessibilityLabel("Take photo")
            .padding(.bottom, 12)
        }
        .foregroundStyle(.white)
        .background(Color(white: 0.12))
        .environment(\.colorScheme, .dark)
        .animation(Theme.snappy, value: processing)
        .sensoryFeedback(.impact(weight: .medium), trigger: shots)
        .sensoryFeedback(.success, trigger: captured.count)
    }

    /// Shutter → a short "checking" beat → Added ✓, then the next step.
    private func capture() {
        shots += 1
        processing = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(Theme.smooth) {
                processing = false
                captured.insert(stage.id)
                if let next = stages.firstIndex(where: { !captured.contains($0.id) }) {
                    index = next
                }
            }
            if captured.count == stages.count {
                try? await Task.sleep(for: .seconds(0.4))
                onDone()
            }
        }
    }
}

private struct StageThumb: View {
    enum State { case added, scanning, waiting }

    let stage: CaptureStage
    let state: State

    private var caption: LocalizedStringKey {
        switch state {
        case .added:    "Added ✓"
        case .scanning: "Scanning…"
        case .waiting:  stage.short
        }
    }
    private var ring: Color {
        switch state {
        case .added:    Theme.success
        case .scanning: Theme.brandSolid
        case .waiting:  .clear
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: stage.symbol)
                .font(Theme.Font.body)
            Text(caption)
                .font(.system(size: 10))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white.opacity(0.8))
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(.white.opacity(0.12), in: .rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(ring, lineWidth: 2) }
        .animation(Theme.snappy, value: state == .added)
    }
}

// MARK: - EV02a · Scan to unlock

/// Live QR scanning with VisionKit's DataScanner on real hardware. For the
/// demo — there is no car QR to point at — holding steady for a few seconds
/// also "finds" the car. "Type the code" unlocks with the 6-character code.
struct ScanToUnlockView: View {
    let vehicleName: String
    let onCancel: () -> Void
    let onUnlock: () -> Void

    @State private var found = false
    @State private var typing = false
    @State private var code = ""

    var body: some View {
        ZStack {
            if DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                QRScanner { if AppConfiguration.isDemo { found = true } }
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.35).ignoresSafeArea())
            } else {
                Color(white: 0.12).ignoresSafeArea()
            }

            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("Scan to unlock").font(Theme.Font.subheadlineSemibold)
                    Text("QR code on the windscreen")
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button("Cancel", action: onCancel)
                        .font(Theme.Font.subheadlineSemibold)
                        .buttonStyle(.glass)
                        .buttonBorderShape(.capsule)
                }
                .padding(.horizontal, Theme.Space.screen)
                .padding(.top, 8)

                Spacer()

                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    .foregroundStyle(found ? Theme.success : .white.opacity(0.6))
                    .frame(width: 260, height: 170)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: found ? "checkmark.circle.fill" : "qrcode.viewfinder")
                                .font(.system(size: 72))
                                .foregroundStyle(found ? Theme.success : .white.opacity(0.4))
                                .contentTransition(.symbolEffect(.replace))
                                .symbolEffect(.pulse, options: .repeating, isActive: !found)
                            Text(found ? "\(vehicleName) found" : "Hold steady to unlock")
                                .font(Theme.Font.title3)
                                .contentTransition(.opacity)
                        }
                    }

                Text("No QR code? Type the 6-character code under it.")
                    .font(Theme.Font.subheadlineRegular)
                    .padding(.top, 14)

                Spacer()

                Button { typing = true } label: {
                    Label("Type the code", systemImage: "keyboard")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.rentbutik)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .environment(\.colorScheme, .light)
                .padding(.bottom, 24)
            }
            .foregroundStyle(.white)
        }
        .environment(\.colorScheme, .dark)
        .animation(Theme.smooth, value: found)
        .sensoryFeedback(.success, trigger: found)
        .task {
            // Demo: no physical QR — the car is "found" after holding steady.
            guard AppConfiguration.isDemo else { return }
            do { try await Task.sleep(for: .seconds(3.5)) } catch { return }
            found = true
        }
        .onChange(of: found) { _, isFound in
            guard isFound else { return }
            Task {
                do { try await Task.sleep(for: .seconds(0.9)) } catch { return }
                guard AppConfiguration.isDemo else { return }
                onUnlock()
            }
        }
        .alert("Type the code", isPresented: $typing) {
            TextField("6 characters", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            Button("Unlock") { if AppConfiguration.isDemo && code.count == 6 { found = true } }
            Button("Cancel", role: .cancel) { code = "" }
        } message: {
            Text("It’s printed under the QR code on the windscreen.")
        }
    }
}

/// VisionKit's live scanner, QR codes only. Reports the first code it sees.
private struct QRScanner: UIViewControllerRepresentable {
    let onFound: () -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])],
                                                qualityLevel: .balanced,
                                                isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onFound: onFound) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onFound: () -> Void
        init(onFound: @escaping () -> Void) { self.onFound = onFound }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if !addedItems.isEmpty { onFound() }
        }
    }
}


/// The same evidence checklist is used by EV and Golf returns.
enum ReturnPhotoStages {
    static let all: [CaptureStage] = [
        .init(id: "front", title: "Front", detail: "1 of 6", short: "Front", symbol: "car.front.waves.up.fill"),
        .init(id: "rear", title: "Rear", detail: "2 of 6", short: "Rear", symbol: "car.rear.fill"),
        .init(id: "left", title: "Left side", detail: "3 of 6", short: "Left", symbol: "car.side.fill"),
        .init(id: "right", title: "Right side", detail: "4 of 6", short: "Right", symbol: "car.side.fill"),
        .init(id: "inside", title: "Interior", detail: "5 of 6", short: "Inside", symbol: "car.fill"),
        .init(id: "parking", title: "Parking position", detail: "6 of 6", short: "Parking", symbol: "mappin.and.ellipse")
    ]
}
