import SwiftUI

/// H01 · Home — Design-flow `8:10`.
///
/// Logo + wordmark, welcome, four modules (Transfer, Renter, Electric car,
/// Golf cart), News and Notifications. The first-ride offer is a
/// notification (Emin, 28.09.2026), not a banner. Host is no
/// longer a Home module — it lives under Profile › Hosting.
///
/// H01ev / H01golf are STATES of this view, not new screens: the module that
/// owns a running ride carries it in place (see `RentbutikTile.live`).
struct HomeScreen: View {
    let store: Store
    let session: Session
    let router: AppRouter

    @State private var openNotification: AppNotification?
    @State private var openNews: NewsItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HomeHeader()
                    .padding(.bottom, 20)

                HomeWelcome(name: session.displayName)
                    .padding(.bottom, 24)

                HomeModuleGrid(router: router,
                               activeTrip: store.activeTrip,
                               costOf: { store.rideCost($0) },
                               onEndTrip: { _ in router.tab = .trips })
                    .padding(.bottom, 32)

                HomeNewsCarousel(items: store.news) { openNews = $0 }
                    .padding(.bottom, 32)

                // H01: the latest four; "See all" opens H04 (B29).
                HomeNotificationsSection(
                    notifications: Array(store.notifications.prefix(4)),
                    onSeeAll: { router.push(.allNotifications) },
                    onOpen: {
                        store.markNotificationRead($0.id)
                        openNotification = $0
                    })
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.gap)
            .padding(.bottom, Theme.Space.tabBarClearance)
        }
        .background(Theme.background)
        .toolbarVisibility(.hidden, for: .navigationBar)
        // H02 and H03 size themselves to their text — see FittedSheet.
        .sheet(item: $openNotification) { item in
            NotificationSheet(notification: item)
                .fittedSheet()
        }
        .sheet(item: $openNews) { item in
            NewsSheet(item: item)
                .fittedSheet()
        }
    }
}

#Preview("Home") {
    NavigationStack {
        HomeScreen(store: .seeded(), session: .emin(), router: AppRouter())
    }
}

// MARK: - Header

/// The real vector mark (navy squircle, gold key) + wordmark in Title 3.
/// A plain image — it does nothing when tapped.
private struct HomeHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("rentbutikLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            Text("Rentbutik")
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

private struct HomeWelcome: View {
    let name: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let name {
                Text("Welcome, \(name)")
                    .font(Theme.Font.largeTitle)
                    .foregroundStyle(Theme.ink)
            } else {
                Text("Welcome")
                    .font(Theme.Font.largeTitle)
                    .foregroundStyle(Theme.ink)
            }
            Text("What are you here to do today?")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

// MARK: - Modules

/// Transfer, Renter, Electric car, Golf cart — in the order H01 draws them.
private struct HomeModuleGrid: View {
    let router: AppRouter
    let activeTrip: Trip?
    /// Live price of a running ride (EV: unlock + started hours, capped).
    let costOf: (Trip) -> Decimal
    let onEndTrip: (String) -> Void

    @Environment(\.zoomNamespace) private var zoom

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Space.gap),
        GridItem(.flexible(), spacing: Theme.Space.gap),
    ]

    private func live(for kind: VehicleKind) -> TileLiveState? {
        guard let trip = activeTrip, trip.vehicleKind == kind else { return nil }
        return TileLiveState(label: "Riding now", vehicleName: trip.vehicleName,
                             startedAt: trip.startDate, cost: costOf(trip))
    }

    private func endTrip(for kind: VehicleKind) -> (() -> Void)? {
        guard let trip = activeTrip, trip.vehicleKind == kind else { return nil }
        return { onEndTrip(trip.id) }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Space.gap) {
            RentbutikTile(symbol: "point.topleft.down.to.point.bottomright.curvepath.fill",
                          title: "Transfer",
                          supporting: "Rides & tours from Baku") {
                router.push(.transferList)
            }
            .zoomSource("transfer", in: zoom, cornerRadius: Theme.Radius.tile)

            RentbutikTile(symbol: "car.fill",
                          title: "Renter",
                          supporting: "Rent a car by day, week or month") {
                router.push(.renterList)
            }
            .zoomSource("renter", in: zoom, cornerRadius: Theme.Radius.tile)

            RentbutikTile(symbol: "bolt.car.fill",
                          title: "Electric car",
                          supporting: "By the minute, hour or day",
                          live: live(for: .electric),
                          onEndTrip: endTrip(for: .electric)) {
                if let trip = activeTrip, trip.vehicleKind == .electric {
                    router.push(.evActiveTrip(vehicleID: trip.vehicleID.isEmpty ? "veh-ev-6" : trip.vehicleID))
                } else {
                    router.push(.evUnlock(vehicleID: "veh-ev-6"))
                }
            }
            .zoomSource("electric", in: zoom, cornerRadius: Theme.Radius.tile)

            RentbutikTile(symbol: "steeringwheel",
                          title: "Golf cart",
                          supporting: "Available in Sea Breeze",
                          live: live(for: .golfCart),
                          onEndTrip: endTrip(for: .golfCart)) {
                router.push(.golfMap)
            }
            .zoomSource("golf", in: zoom, cornerRadius: Theme.Radius.tile)
        }
    }
}

// MARK: - News

private struct HomeNewsCarousel: View {
    let items: [NewsItem]
    let onOpen: (NewsItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gap) {
            Text("News")
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.ink)

            ScrollView(.horizontal) {
                HStack(spacing: Theme.Space.gap) {
                    ForEach(items) { item in
                        Button { onOpen(item) } label: { NewsCard(item: item) }
                            .buttonStyle(PressScale(haptic: .open))
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .padding(.horizontal, -Theme.Space.screen)
            .contentMargins(.horizontal, Theme.Space.screen, for: .scrollContent)
        }
    }
}

/// Photo + category pill. Opaque — photo cards are never glass.
private struct NewsCard: View {
    let item: NewsItem

    var body: some View {
        Color.clear
            .frame(width: 280, height: 140)
            .background { PhotoFill(photoName: item.photoName, symbol: item.symbol) }
            .overlay(alignment: .topLeading) {
                Text(item.category)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.card, in: .capsule)
                    .padding(12)
            }
            .clipShape(.rect(cornerRadius: Theme.Radius.card))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(item.headline))
    }
}

// MARK: - Notifications

private struct HomeNotificationsSection: View {
    let notifications: [AppNotification]
    let onSeeAll: () -> Void
    let onOpen: (AppNotification) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gap) {
            HStack(alignment: .firstTextBaseline) {
                Text("Notifications")
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Button { onSeeAll() } label: {
                    Text("See all")
                        .font(Theme.Font.subheadlineSemibold)
                        .foregroundStyle(Theme.goldText)
                }
                .buttonStyle(PressScale(haptic: .click))
            }

            ForEach(notifications) { n in
                Button { onOpen(n) } label: {
                    NotificationCard(symbol: n.symbol, title: n.title,
                                     detail: n.detail, date: n.date)
                }
                .buttonStyle(PressScale(haptic: .open))
            }
        }
    }
}

/// Badge, two lines in Subheadline / Medium, time in Footnote secondary.
struct NotificationCard: View {
    let symbol: String
    let title: String
    let detail: String
    let date: Date

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RentbutikBadge(symbol: symbol, size: .notification)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(title)\n\(detail)")
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(NotificationCard.timestamp(for: date))
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(Theme.Radius.tile)
    }

    /// "2 min ago" inside the hour, otherwise "18 Sep" — both locale-aware.
    static func timestamp(for date: Date) -> String {
        if Date.now.timeIntervalSince(date) < 3600 {
            return date.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

// MARK: - Sheets

/// H02 · Notification — sized to its text.
private struct NotificationSheet: View {
    let notification: AppNotification
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeader(title: "Notification") { dismiss() }

            HStack(alignment: .top, spacing: 12) {
                RentbutikBadge(symbol: notification.symbol, size: .notification)
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text(notification.detail)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.ink)
                    Text(notification.date.formatted(.dateTime.day().month(.wide).year().hour().minute()))
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(Theme.Radius.group)
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, Theme.Space.noTabBarClearance)
    }
}

/// H03 · News — photo plus headline, sized to its text.
private struct NewsSheet: View {
    let item: NewsItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeader(title: LocalizedStringKey(item.category)) { dismiss() }

            Color.clear
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .background { PhotoFill(photoName: item.photoName, symbol: item.symbol) }
                .clipShape(.rect(cornerRadius: Theme.Radius.card))

            Text(item.headline)
                .font(Theme.Font.title2)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, Theme.Space.noTabBarClearance)
    }
}

// MARK: - H04 · All notifications

/// Pushed, large title — `Nav bar / Large title`.
struct AllNotificationsScreen: View {
    let store: Store

    @State private var open: AppNotification?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                ForEach(store.notifications) { n in
                    // Same as Home: each row opens H02, sized to its text.
                    Button {
                        store.markNotificationRead(n.id)
                        open = n
                    } label: {
                        NotificationCard(symbol: n.symbol, title: n.title,
                                         detail: n.detail, date: n.date)
                    }
                    .buttonStyle(PressScale(haptic: .open))
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.tabBarClearance)
        }
        .background(Theme.background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $open) { item in
            NotificationSheet(notification: item)
                .fittedSheet()
        }
    }
}

#Preview("H02 · content height") {
    VStack {
        Spacer()
        NotificationSheet(notification: Store.seeded().notifications[0])
            .fixedSize(horizontal: false, vertical: true)
            .background(Theme.background, in: .rect(cornerRadius: Theme.Radius.card))
    }
    .background(Color.black.opacity(0.3))
}

