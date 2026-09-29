import SwiftUI

// Shared by Renter (R01/R01b) and Transfer (TR01/TR01b): the same photo card
// that opens in place, the same details block, the same glass filter chips.

/// Photo card, radius 30, that keeps ONE size whether open or closed.
/// Closed, the photo fills the whole card; opening shrinks the photo to the
/// top 150 pt and reveals `details` in the space it gave up — so the card
/// never changes height and nothing below it jumps.
struct PhotoListingCard<Details: View>: View {
    let title: String
    let subtitle: String
    let photo: String
    let leadingPill: String
    let trailingPill: String
    let isOpen: Bool
    let isSaved: Bool
    let onToggle: () -> Void
    let onSave: () -> Void
    @ViewBuilder let details: Details

    private let openPhotoHeight: CGFloat = 150
    /// Measured from the details block, so the card fits them exactly.
    @State private var detailsHeight: CGFloat = 190

    private var cardHeight: CGFloat { openPhotoHeight + detailsHeight }

    var body: some View {
        ZStack(alignment: .top) {
            // Details live under the photo at all times; they are revealed,
            // not inserted, so the card's size is stable.
            details
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { detailsHeight = $0 }
                .padding(.top, openPhotoHeight)
                .opacity(isOpen ? 1 : 0)
                .offset(y: isOpen ? 0 : 12)
                .allowsHitTesting(isOpen)
                .accessibilityHidden(!isOpen)

            Button(action: onToggle) {
                Color.clear
                    .frame(height: isOpen ? openPhotoHeight : cardHeight)
                    .frame(maxWidth: .infinity)
                    // The photo is drawn at full card height and cropped —
                    // never rescaled mid-animation.
                    .background(alignment: .center) {
                        PhotoFill(photoName: photo, symbol: "car.fill")
                            .frame(height: cardHeight)
                    }
                    .clipped()
                    .overlay {
                        LinearGradient(colors: [.black.opacity(0.5), .clear, .black.opacity(0.3)],
                                       startPoint: .top, endPoint: .bottom)
                    }
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(Theme.Font.title3)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(subtitle)
                                .font(Theme.Font.subheadlineRegular)
                                .opacity(0.9)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)
                        .padding(16)
                        .padding(.trailing, 50)
                    }
                    .overlay(alignment: .bottom) {
                        HStack {
                            PhotoLabel(text: leadingPill, color: Theme.ink)
                            Spacer()
                            PhotoLabel(text: trailingPill, color: Theme.goldText)
                        }
                        .padding(14)
                        .opacity(isOpen ? 0 : 1)
                    }
            }
            .buttonStyle(PressScale(haptic: .open))
            .overlay(alignment: .topTrailing) {
                Button(action: onSave) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(Theme.Font.headline)
                        .foregroundStyle(isSaved ? Theme.danger : Theme.ink)
                        .symbolEffect(.bounce, value: isSaved)
                        .frame(width: 36, height: 36)
                        .background(Theme.card, in: .circle)
                }
                .buttonStyle(.plain)
                .padding(14)
                .accessibilityLabel(isSaved ? "Remove from saved" : "Save")
            }
        }
        .frame(height: cardHeight, alignment: .top)
        .background(Theme.card)
        .clipShape(.rect(cornerRadius: Theme.Radius.card))
        .shadow(color: Theme.Shadow.card.color, radius: Theme.Shadow.card.radius, y: Theme.Shadow.card.y)
        .animation(Theme.expand, value: isOpen)
        .accessibilityElement(children: .contain)
    }
}

/// R01b / TR01b — price line with rating, person row, secondary + primary.
struct ListingDetailsBody: View {
    let price: String
    let priceSuffix: String
    let rating: Double
    let ratingCount: Int
    let person: String
    let role: LocalizedStringKey
    let secondaryTitle: LocalizedStringKey
    let secondarySymbol: String
    let primaryTitle: LocalizedStringKey
    let onMessage: () -> Void
    let onSecondary: () -> Void
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(price)
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                Text(priceSuffix)
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Label {
                    Text(verbatim: "\(rating.formatted(.number.precision(.fractionLength(1)))) (\(ratingCount))")
                } icon: {
                    Image(systemName: "star.fill").foregroundStyle(Theme.goldText)
                }
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
                .labelStyle(TightLabelStyle())
            }

            HStack(spacing: 12) {
                Text(verbatim: String(person.prefix(1)))
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.goldText)
                    .frame(width: 36, height: 36)
                    .background(Theme.brandTint, in: .circle)
                VStack(alignment: .leading, spacing: 1) {
                    Text(person)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text(role)
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Button("Message \(person)", systemImage: "message.fill", action: onMessage)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Theme.ink)
                    .buttonStyle(.rentbutik)
                    .buttonBorderShape(.circle)
            }

            GlassEffectContainer {
                HStack(spacing: 10) {
                    Button(action: onSecondary) {
                        Label(secondaryTitle, systemImage: secondarySymbol)
                            .padding(.horizontal, 4)
                    }
                    Button(action: onPrimary) {
                        Text(primaryTitle)
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .buttonStyle(.rentbutik)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                // White on a white card: controlShadow lifts them.
                .shadow(color: Theme.Shadow.control.color, radius: Theme.Shadow.control.radius,
                        y: Theme.Shadow.control.y)
            }
        }
        .padding(16)
    }
}

/// Footnote / Semibold on white-92 — price and status pills on photos.
struct PhotoLabel: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(Theme.Font.footnote)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.card.opacity(0.92), in: .capsule)
    }
}

struct TightLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) { configuration.icon; configuration.title }
    }
}

struct ChipLabelStyle: LabelStyle {
    let iconColor: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(iconColor)
            configuration.title
        }
    }
}

/// "Filters ⌄" — icon, title and a small chevron inside a glass chip.
struct FilterChipLabel: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        HStack(spacing: 3) {
            Label(title, systemImage: symbol)
                .labelStyle(ChipLabelStyle(iconColor: Theme.ink))
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

extension View {
    /// The chip row's shared look: native glass capsules, mini control.
    func filterChipStyle() -> some View {
        buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.mini)
            .font(Theme.Font.subheadlineSemibold)
            .foregroundStyle(Theme.ink)
    }
}

/// R01h / TR01e — the empty state card, with an optional notify action.
struct ListingEmptyCard: View {
    let title: String
    let detail: LocalizedStringKey
    var notifyTitle: LocalizedStringKey? = nil
    @Binding var notified: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.inkSoft)
            if let notifyTitle {
                Button {
                    notified.toggle()
                } label: {
                    Label(notified ? "We’ll notify you" : notifyTitle,
                          systemImage: notified ? "bell.fill" : "bell")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.rentbutik)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .padding(.top, 8)
                .sensoryFeedback(.success, trigger: notified)
            }
        }
        .multilineTextAlignment(.center)
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassCard(Theme.Radius.card)
    }
}

/// Map-mode card (R01f / TR map): photo thumb, title, one line, price and a
/// chevron, on frosted map glass. Swiped in a `VehicleCarousel` like EV01.
struct MapListingCard: View {
    let title: String
    let subtitle: String
    let photo: String
    let price: String
    let badge: String
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Color.clear
                    .frame(width: 96, height: 72)
                    .background { PhotoFill(photoName: photo, symbol: "car.fill", glyphSize: 20) }
                    .clipShape(.rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(price)
                            .font(Theme.Font.subheadlineSemibold)
                            .foregroundStyle(Theme.ink)
                        Text(badge)
                            .font(Theme.Font.captionSemibold)
                            .foregroundStyle(Theme.goldText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.brandTint, in: .capsule)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(12)
            .glassMapCard()
        }
        .buttonStyle(PressScale(haptic: .open))
    }
}

