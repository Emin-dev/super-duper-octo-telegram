import SwiftUI

/// Tokens and metrics RULES.md specifies but `Theme.swift` never received.
///
/// Kept in an extension so the imported half of the design contract stays
/// untouched. Every value here has a named counterpart in the Figma `Theme`
/// collection, same as the rest of `Theme`.
extension Theme {

    // MARK: - Glass (RULES.md L)

    /// The darkened perimeter around glass, new in iOS 27.
    /// Light black 12%, Dark black 35%.
    static let glassEdge = Color("glassEdge")

    /// The dim behind a sheet, heavier in dark mode.
    /// Light black 28%, Dark black 45% — RULES.md T.
    static let scrim = Color("scrim")

    // MARK: - Geometry (RULES.md C)

    enum Action {
        /// An action capsule INSIDE a card is 38, not the 50 used for
        /// full-width buttons — RULES.md C.
        static let inCardHeight: CGFloat = 38
    }

    // MARK: - Shell metrics (RULES.md P)

    enum Shell {
        /// Floating tab bar height. The bottom-anchored panel arithmetic in
        /// RULES.md P is `874 - 68 - 24 - 14`, so the bar is 68 tall and sits
        /// 24 above the bottom edge.
        static let tabBarHeight: CGFloat = 68
        static let tabBarBottomInset: CGFloat = 24
    }
}

// MARK: - Liquid Glass surfaces (Emin's decision, 25 Sep 2026)
//
// Emin chose iOS 27 Liquid Glass for buttons, chips and content cards over
// Figma's solid `surface/card` / `surface/control`. Photo cards stay OPAQUE —
// glass over a photo loses legibility and ignores clipShape (RULE B2).
// Every card and control goes through these, so the choice lives in one place.

extension PrimitiveButtonStyle where Self == GlassButtonStyle {
    /// Button / Large and Button / Small — native Liquid Glass tinted with
    /// surface/card, so buttons read as the white capsules Figma draws
    /// (#FFFFFF · #1C1C1E) instead of grey glass with a rim.
    static var rentbutik: GlassButtonStyle {
        .glass(.regular.tint(Theme.card.opacity(0.4)))
    }
}

extension AnyTransition {
    /// Content revealed inside an expanding card: fades up just after the
    /// card starts to grow, and leaves quickly so a collapse never shows
    /// half-faded rows.
    static var expandContent: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: -10))
                .animation(Theme.expand.delay(0.08)),
            removal: .opacity.animation(.easeOut(duration: 0.14)))
    }
}

extension View {
    /// A content card — tiles, record rows, notification rows, grouped lists.
    ///
    /// Figma draws these as surface/card (#FFFFFF · #1C1C1E) with an 18 pt
    /// drop shadow. Plain `.regular` glass reads grey on the #F2F2F7
    /// background, so the glass is tinted with surface/card: it still
    /// refracts and reacts like Liquid Glass, but looks like the file.
    func glassCard(_ radius: CGFloat = Theme.Radius.card) -> some View {
        glassEffect(.regular.tint(Theme.card.opacity(0.35)), in: .rect(cornerRadius: radius))
            .shadow(color: Theme.Shadow.card.color, radius: Theme.Shadow.card.radius,
                    y: Theme.Shadow.card.y)
    }

    /// `Card / Glass map` — EV01 and G01 draw these see-through, the map
    /// visible behind them, so they keep plain `.regular` glass.
    /// A light surface/card tint keeps them frosted white over water too.
    func glassMapCard(_ radius: CGFloat = Theme.Radius.card) -> some View {
        modifier(ReadableMapSurface(radius: radius))
    }

    /// A tinted capsule for chips, so status colour still reads through glass.
    func glassChip(tint: Color?) -> some View {
        glassEffect(tint.map { .regular.tint($0) } ?? .regular, in: .capsule)
    }
}


private struct ReadableMapSurface: ViewModifier {
    let radius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Theme.card, in: .rect(cornerRadius: radius))
        } else {
            content.background(Theme.card.opacity(0.82), in: .rect(cornerRadius: radius))
                .glassEffect(.regular, in: .rect(cornerRadius: radius))
        }
    }
}
