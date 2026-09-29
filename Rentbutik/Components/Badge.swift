import SwiftUI

/// Badge / Symbol — a cream circle with one amber SF Symbol.
///
/// Fill `brand/tint`, symbol `text/gold`. Resize between 32 and 56 pt and the
/// symbol scales with it; never change its colours. Both scale with Dynamic
/// Type through `@ScaledMetric`.
struct RentbutikBadge: View {

    /// Sizes measured from Design-flow, not the component default.
    enum Size {
        case stepRow        // 32 circle
        /// "Notification icon" on H01 — 44 circle, 20 pt symbol.
        case notification
        /// Badge / Symbol component default — 44 circle.
        case tile
        case cardHead       // 52 circle
        case hero           // 56 circle
        /// "Icon badge" on H01's module tiles — 56 ROUNDED SQUARE,
        /// corner radius 22, 25 pt symbol. Not a circle.
        case module

        var side: CGFloat {
            switch self {
            case .stepRow:      32
            case .notification, .tile: 44
            case .cardHead:     52
            case .hero, .module: 56
            }
        }

        var glyph: CGFloat {
            switch self {
            case .stepRow:      15
            case .notification, .tile: 20
            case .cardHead:     24
            case .hero:         26
            case .module:       25
            }
        }

        var cornerRadius: CGFloat {
            self == .module ? 22 : side / 2
        }
    }

    let symbol: String
    var size: Size
    /// Increment to bounce the glyph — Apple's own idiom for a tapped symbol.
    var bounce: Int

    @ScaledMetric private var scale: CGFloat = 1

    init(symbol: String, size: Size = .tile, bounce: Int = 0) {
        self.symbol = symbol
        self.size = size
        self.bounce = bounce
    }

    var body: some View {
        let d = size.side * scale
        Image(systemName: symbol)
            .font(.system(size: size.glyph * scale, weight: .semibold))
            .foregroundStyle(Theme.goldText)
            .symbolEffect(.bounce, value: bounce)
            .frame(width: d, height: d)
            .background(Theme.brandTint,
                        in: .rect(cornerRadius: size.cornerRadius * scale))
    }
}

#Preview {
    HStack(spacing: Theme.Space.gap) {
        RentbutikBadge(symbol: "point.topleft.down.to.point.bottomright.curvepath.fill", size: .stepRow)
        RentbutikBadge(symbol: "car.fill", size: .notification)
        RentbutikBadge(symbol: "bolt.car.fill")
        RentbutikBadge(symbol: "steeringwheel", size: .hero)
    }
    .padding()
    .background(Theme.background)
}

