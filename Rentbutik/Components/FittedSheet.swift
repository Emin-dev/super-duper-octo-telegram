import SwiftUI

/// Sizes a sheet to its content instead of a fixed `.medium` detent.
///
/// The content reports its natural height through `onGeometryChange`, and the
/// sheet uses exactly that as its only detent — a two-line notification gets a
/// short sheet, a long one a taller sheet. Never taller than `.large`.
struct FittedSheet: ViewModifier {
    @State private var height: CGFloat = 260

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { newHeight in
                height = newHeight
            }
            .presentationDetents([.height(height)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Theme.Radius.card)
            .presentationBackground(Theme.background)
    }
}

extension View {
    /// Present inside `.sheet` to size the sheet to this view's content.
    func fittedSheet() -> some View {
        modifier(FittedSheet())
    }
}

/// `Sheet header` from the Design system: centred Headline title with a gold
/// Done on the trailing edge. Used instead of a NavigationStack in fitted
/// sheets, because a NavigationStack always expands to fill.
struct SheetHeader: View {
    let title: LocalizedStringKey
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.goldText)
                    .buttonStyle(.rentbutik)
                    .buttonBorderShape(.capsule)
            }
        }
        .frame(minHeight: 44)
    }
}

