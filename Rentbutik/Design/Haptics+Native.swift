import SwiftUI

extension Haptic {
    /// The native SwiftUI equivalent of each feel in the RULES.md E vocabulary.
    ///
    /// `celebrate`, `gain` and `ignition` are multi-beat sequences —
    /// success + a three-beat tail, medium then 1.0 at 110ms, heavy then rigid
    /// at 140ms. `SensoryFeedback` plays one shot per trigger change and cannot
    /// express them, so those three return `nil` and stay on `fire()`.
    var sensory: SensoryFeedback? {
        switch self {
        case .tick:  .impact(weight: .light, intensity: 0.7)
        case .click: .selection
        case .open:  .impact(flexibility: .soft, intensity: 0.8)
        case .grab:  .impact(flexibility: .rigid)
        case .warn:  .warning
        case .error: .error
        case .celebrate, .gain, .ignition: nil
        }
    }
}

/// The app's one button style: press scale on `Theme.snappy` plus the haptic
/// for that interaction.
///
/// Centralising feedback here is what makes "every tap has a feel" true by
/// construction — a button cannot forget it. Fires on press-down, which is
/// where the feel belongs.
struct PressScale: ButtonStyle {
    var haptic: Haptic = .click

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
            .sensoryFeedback(trigger: configuration.isPressed) { wasPressed, isPressed in
                isPressed && !wasPressed ? haptic.sensory : nil
            }
            .onChange(of: configuration.isPressed) { wasPressed, isPressed in
                // The three sequenced feels, which SensoryFeedback cannot play.
                if isPressed, !wasPressed, haptic.sensory == nil {
                    haptic.fire()
                }
            }
    }
}

