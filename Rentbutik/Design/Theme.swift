import SwiftUI

/// Rentbutik design tokens.
///
/// The v2 code contract with Figma file `xHHYrk0LxIUHo0IOadFCMD`
/// ("Rentbutik v2"), collection "Rentbutik v2 / Theme", modes Light + Dark.
/// Every mode-aware colour resolves through an asset of the same meaning, so
/// light/dark is automatic. Changing one side without the other breaks the
/// contract.
///
/// Target: iOS 27. Screen baseline 402 × 874 pt.
public enum Theme {

    // MARK: - Colour

    /// text/ink. Light #1C1C1E, Dark #FFFFFF.
    public static let ink        = Color("ink")
    /// text/secondary. Light #6D6D72, Dark #EBEBF5 at 60%.
    public static let inkSoft    = Color("inkSoft")
    /// Chevrons, placeholders, disabled glyphs. tint/text-secondary-35.
    public static let inkFaint   = Color("inkSoft").opacity(0.58)
    /// text/gold — the only gold permitted as text. Light #B4640A, Dark #FFB34D.
    public static let goldText   = Color("goldText")
    /// status/danger. Light #FF3B30, Dark #FF453A.
    public static let danger     = Color("danger")
    /// status/success. Light #248A3D, Dark #30D158.
    public static let success    = Color("success")
    /// surface/card. Light #FFFFFF, Dark #1C1C1E.
    public static let card       = Color("card")
    /// surface/background. Light #F2F2F7, Dark #000000.
    public static let background = Color("background")
    /// surface/fill — Button / Small, inset fields. Light #F2F2F7, Dark #2C2C2E.
    public static let fill       = Color("fill")
    /// surface/control — Button / Large, white controls on glass.
    /// Light #FFFFFF, Dark #2C2C2E.
    public static let control    = Color("control")
    /// surface/glass-card — backing under `.glassEffect` on map cards.
    public static let glassCard  = Color("glassCard")
    /// Inset separators. tint/text-secondary-20.
    public static let hairline   = Color("hairline")

    /// brand/solid. Light #E0871F, Dark #F39A2C.
    public static let brandSolid  = Color("brandSolid")
    /// brand/tint — the cream behind every badge glyph. Light #FDEFD9, Dark #38291B.
    public static let brandTint   = Color("brandTint")
    /// Legacy accents, kept for status tints until each screen is re-read.
    public static let accentAmber = Color(hex: 0xF5A524)
    public static let accentHoney = Color(hex: 0xCE9A34)
    public static let accentBronze = Color(hex: 0xB07C16)

    /// text/on-gold — FIXED dark ink on any gold fill, both modes.
    public static let onGold      = Color(hex: 0x14161A)
    /// text/on-photo — white over photography only.
    public static let onBrand     = Color.white

    /// Used only for small brand marks and map pins. `Button / Large` is NOT
    /// gold — its description says "never orange".
    public static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xFFC24B), Color(hex: 0xF5A524), Color(hex: 0xE0871F)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: - Geometry

    public enum Radius {
        public static let card: CGFloat = 30
        public static let tile: CGFloat = 26
        /// radius/group — grouped list cards inside sheets and forms.
        public static let group: CGFloat = 22
        public static let chip: CGFloat = 18
    }
    public enum Space {
        public static let gap: CGFloat = 14
        public static let screen: CGFloat = 18
        /// Tab-root scrolls end with 96 pt; screens without a tab bar end with 34.
        public static let tabBarClearance: CGFloat = 96
        public static let noTabBarClearance: CGFloat = 34
        /// Between a map card's bottom and the tab bar top.
        public static let mapCardToTabBar: CGFloat = 26
    }
    public enum Size {
        /// Button / Large — 52 pt capsule. Never grow it; shorten the copy.
        public static let button: CGFloat = 52
        /// Button / Small — 36 pt capsule, inline actions in cards.
        public static let smallButton: CGFloat = 36
        public static let iconButton: CGFloat = 44
        /// Chip / Hold countdown.
        public static let holdChip: CGFloat = 38
        public static let actionCapsule: CGFloat = 36
        public static let statusDot: CGFloat = 7
        public static let photoStrip: CGFloat = 4
        public static let pinIcon: CGFloat = 26
        public static let pinRing: CGFloat = 33
        /// Home module tile — 176 × 172, measured from H01. (The Tile / Bento
        /// component says 136; the screen draws 172, and the screen wins.)
        public static let tileHeight: CGFloat = 172
        public static let badge: CGFloat = 44
        /// List / Grouped row height.
        public static let groupedRow: CGFloat = 46
    }

    // MARK: - Shadow (effect styles)

    public enum Shadow {
        /// cardShadow — light mode only; dark cards rely on #1C1C1E.
        public static let card = (color: Color.black.opacity(0.06), radius: 9.0, y: 6.0)
        /// controlShadow — white controls on glass or maps.
        public static let control = (color: Color.black.opacity(0.10), radius: 4.0, y: 2.0)
    }

    // MARK: - Motion — Apple's own spring presets, nothing hand-tuned
    /// Map camera, re-sorts, state morphs.
    public static let smooth = Animation.smooth
    /// Presses, toggles, small changes.
    public static let snappy = Animation.snappy
    /// Arrivals, pins, new chat bubbles.
    public static let bouncy = Animation.bouncy
    /// In-place expand/collapse (T01 rows, current trip, R01b cards): one
    /// spring for height, crop and content so they move as a single gesture.
    public static let expand = Animation.smooth(extraBounce: 0.08)

    // MARK: - Type — the file's 17 iOS text styles, all Dynamic Type

    public enum Font {
        public static let largeTitle  = SwiftUI.Font.largeTitle.bold()
        public static let title1      = SwiftUI.Font.title.bold()
        public static let title2      = SwiftUI.Font.title2.bold()
        public static let title3      = SwiftUI.Font.title3.bold()
        public static let headline    = SwiftUI.Font.headline
        public static let body        = SwiftUI.Font.body
        public static let bodyBold    = SwiftUI.Font.body.bold()
        public static let callout     = SwiftUI.Font.callout
        public static let calloutSemibold = SwiftUI.Font.callout.weight(.semibold)
        /// Subheadline / Medium — tile subtitles, emphasised meta lines.
        public static let subheadline = SwiftUI.Font.subheadline.weight(.medium)
        public static let subheadlineRegular  = SwiftUI.Font.subheadline
        public static let subheadlineSemibold = SwiftUI.Font.subheadline.weight(.semibold)
        /// Footnote / Semibold — status text in cards.
        public static let footnote    = SwiftUI.Font.footnote.weight(.semibold)
        public static let footnoteRegular = SwiftUI.Font.footnote
        public static let caption     = SwiftUI.Font.caption
        public static let captionSemibold = SwiftUI.Font.caption.weight(.semibold)
        public static let caption2    = SwiftUI.Font.caption2
        /// Totals and balances.
        public static let moneyLarge  = SwiftUI.Font.largeTitle.bold()
        public static let moneyRow    = SwiftUI.Font.body.bold()
    }
}

// MARK: - Haptics
/// Every interaction has its OWN feel. This is deliberate: the app should be
/// recognisable with the screen off. All one-shot — nothing loops, nothing fires on scroll.
public enum Haptic {
    case tick, click, open, grab, gain, celebrate, ignition, warn, error

    public func fire() {
        switch self {
        case .tick:   UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
        case .click:  UISelectionFeedbackGenerator().selectionChanged()
        case .open:   UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
        case .grab:   UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .gain:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.6)
            Haptic.after(0.110) { UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 1.0) }
        case .celebrate:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            for t in [0.160, 0.280, 0.370] {
                Haptic.after(t) { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            }
        case .ignition:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            Haptic.after(0.140) { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9) }
        case .warn:  UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    /// The later beats of a sequence, on the main actor.
    private static func after(_ seconds: Double, _ beat: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            beat()
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8)  & 0xFF) / 255,
                  blue:  Double( hex        & 0xFF) / 255,
                  opacity: 1)
    }
}

