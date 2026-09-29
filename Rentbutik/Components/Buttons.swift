import SwiftUI

// Buttons use Apple's native iOS 27 Liquid Glass button style — no custom
// ButtonStyle, no hand-drawn capsule. The system supplies the glass, the
// press response and accessibility; haptics come from .sensoryFeedback.

/// Button / Large — every main action. Full width, capsule, large control.
/// Destructive uses the native `.destructive` role, which the system renders
/// in red.
struct RentbutikPrimaryButton: View {
    let title: LocalizedStringKey
    var symbol: String?
    var haptic: Haptic
    var destructive: Bool
    let action: () -> Void

    @State private var taps = 0

    init(_ title: LocalizedStringKey,
         symbol: String? = nil,
         haptic: Haptic = .click,
         destructive: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.haptic = haptic
        self.destructive = destructive
        self.action = action
    }

    var body: some View {
        Button(role: destructive ? .destructive : nil) {
            taps += 1
            if haptic.sensory == nil { haptic.fire() }   // sequenced feels
            action()
        } label: {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .symbolEffect(.bounce, value: taps)
                }
                Text(title)
            }
                .font(Theme.Font.headline)
                .foregroundStyle(destructive ? Theme.danger : Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.Size.button - 14)
        }
        .buttonStyle(.rentbutik)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .sensoryFeedback(trigger: taps) { _, _ in
            (destructive ? Haptic.warn : haptic).sensory
        }
    }
}

/// Button / Small — inline actions in cards. Native glass, `.small` control
/// size, capsule. `onBackground` is kept for call-site compatibility; glass
/// adapts to what is behind it, so it no longer needs a separate fill.
struct RentbutikSmallButton: View {
    let title: LocalizedStringKey
    var destructive: Bool
    var onBackground: Bool
    let action: () -> Void

    @State private var taps = 0

    init(_ title: LocalizedStringKey, destructive: Bool = false,
         onBackground: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.destructive = destructive
        self.onBackground = onBackground
        self.action = action
    }

    var body: some View {
        Button(role: destructive ? .destructive : nil) {
            taps += 1
            action()
        } label: {
            Text(title)
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(destructive ? Theme.danger : Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(.rentbutik)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .sensoryFeedback(destructive ? .warning : .selection, trigger: taps)
    }
}


