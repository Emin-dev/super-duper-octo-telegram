import SwiftUI

/// What a tile shows while its module has something running.
/// The tile keeps its frame and position; only the contents change.
struct TileLiveState: Equatable {
    /// "Riding now", "Arriving", "Waiting for host".
    let label: LocalizedStringKey
    /// H01ev shows the vehicle under the status: "Rentbutik EV 6".
    let vehicleName: String
    let startedAt: Date
    let cost: Decimal
}

/// The bento unit. Home modules and Profile settings are both grids of these.
/// Badge at the top, title and supporting line pinned to the bottom.
///
/// When `live` is non-nil the SAME tile becomes the live surface — badge
/// becomes a status dot, title becomes a running timer, and an End trip action
/// appears inside the tile. No second card, nothing below moves, and ending a
/// ride costs one tap from Home.
///
/// Uses `RentbutikBadge`, so the glyph is ~60% of the circle per RULES.md N.
/// Height is a `minHeight` so the tile grows with Dynamic Type rather than
/// clipping — RULE B11 matters most in Azerbaijani.
struct RentbutikTile: View {
    let symbol: String          // an SF Symbol name, verbatim
    let title: LocalizedStringKey
    let supporting: LocalizedStringKey
    var wide: Bool
    var live: TileLiveState?
    /// Shown only while live. Omit and no End trip action is offered.
    var onEndTrip: (() -> Void)?
    let action: () -> Void

    @State private var bounce = 0
    @ScaledMetric private var height: CGFloat = Theme.Size.tileHeight

    init(symbol: String,
         title: LocalizedStringKey,
         supporting: LocalizedStringKey,
         wide: Bool = false,
         live: TileLiveState? = nil,
         onEndTrip: (() -> Void)? = nil,
         action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.supporting = supporting
        self.wide = wide
        self.live = live
        self.onEndTrip = onEndTrip
        self.action = action
    }

    private var isLive: Bool { live != nil }

    @State private var taps = 0

    /// ONE glass shape for both states. Only the tint and the contents
    /// change, so going live morphs the tile instead of cross-fading two
    /// separate cards (which flashed a double layer of glass).
    var body: some View {
        ZStack(alignment: .topLeading) {
            if let live {
                liveContent(live)
                    .transition(.blurReplace)
            } else {
                idleContent
                    .transition(.blurReplace)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: height, alignment: .topLeading)
        // Native interactive glass gives the press response; H01ev's live
        // tile is the brand-tinted version of the same surface.
        .glassEffect((isLive ? Glass.regular.tint(Theme.brandSolid.opacity(0.25))
                             : Glass.regular.tint(Theme.card.opacity(0.35))).interactive(),
                     in: .rect(cornerRadius: Theme.Radius.tile))
        .shadow(color: Theme.Shadow.card.color, radius: Theme.Shadow.card.radius,
                y: Theme.Shadow.card.y)
        .contentShape(.rect(cornerRadius: Theme.Radius.tile))
        .onTapGesture {
            taps += 1
            if !isLive { bounce += 1 }
            action()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
        .animation(Theme.expand, value: isLive)
    }

    private func liveContent(_ live: TileLiveState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TileLiveHeader(label: live.label)

            Text(live.vehicleName)
                .font(Theme.Font.subheadlineRegular)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            Spacer(minLength: 2)

            TileLiveReadout(startedAt: live.startedAt, cost: live.cost)

            if let onEndTrip {
                // Native iOS 27 glass button, full tile width.
                Button {
                    Haptic.grab.fire()
                    onEndTrip()
                } label: {
                    Text("End trip")
                        .font(Theme.Font.subheadlineSemibold)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.rentbutik)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity, minHeight: height - 32, alignment: .topLeading)
    }

    /// Geometry measured from H01: 176 × 172, radius 26, padding 16, then a
    /// TOP-aligned stack — 56 pt rounded-square badge, 12, title, 4, subtitle.
    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            RentbutikBadge(symbol: symbol, size: .module, bounce: bounce)
                .padding(.bottom, 12)

            TileIdleFooter(title: title, supporting: supporting)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Honey dot + status. Honey means riding right now; gold is new or
/// upcoming (RULE F).
private struct TileLiveHeader: View {
    let label: LocalizedStringKey

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Theme.accentHoney)
                .frame(width: Theme.Size.statusDot,
                       height: Theme.Size.statusDot)
            Text(label)
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.goldText)
                .lineLimit(1)
        }
    }
}

/// Elapsed and cost share one row so the End trip capsule fits without
/// growing the tile.
private struct TileLiveReadout: View {
    let startedAt: Date
    let cost: Decimal

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Counts up on its own — no timer for us to manage.
            Text(startedAt, style: .timer)
                .font(Theme.Font.moneyRow)
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .lineLimit(1)

            Text(cost, format: .currency(code: Currency.code)
                .precision(.fractionLength(2)))
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
        }
    }
}

private struct TileIdleFooter: View {
    let title: LocalizedStringKey
    let supporting: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
            // H01 binds tile subtitles to iOS · Footnote, text/secondary.
            Text(supporting)
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
}

