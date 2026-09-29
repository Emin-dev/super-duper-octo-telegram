import SwiftUI
import MapKit

/// G01 · Select golf cart — map canvas on the Sea Breeze shore with
/// swipeable cart cards. Statuses come from Sea Breeze staff, so there is no
/// moving marker and nothing ticks here.
struct GolfMapScreen: View {
    let store: Store
    let router: AppRouter
    /// Previews open straight into a mode.
    var initialMode: GolfMode = .hourly

    @Environment(\.dismiss) private var dismiss
    @Environment(Session.self) private var session
    @State private var selection: String?
    @State private var scanning: Vehicle?
    /// Hourly lives in the carousel; Daily and With driver need more room,
    /// so the selected cart leaves the carousel as ONE card (U1).
    @State private var mode: GolfMode = .hourly
    @State private var bookingFailed = false
    @State private var paymentID = UUID().uuidString

    private var carts: [Vehicle] { store.vehicles.filter { $0.kind == .golfCart } }
    private var selected: Vehicle? { carts.first { $0.id == selection } ?? carts.first }
    /// G02: a held cart takes over the map until Start, Cancel or 0:00.
    private var held: (cart: Vehicle, hold: Store.Hold)? {
        guard let hold = store.hold, hold.kind == .golfCart,
              let cart = carts.first(where: { $0.id == hold.vehicleID }) else { return nil }
        return (cart, hold)
    }

    /// The Sea Breeze Golf desk, and where the person stands in G02.
    static let desk = CLLocationCoordinate2D(latitude: 40.5916, longitude: 49.9872)
    private static let you = CLLocationCoordinate2D(latitude: 40.5889, longitude: 49.9862)

    private var pins: [MapVehiclePin] {
        var result: [MapVehiclePin] = carts.compactMap { c in
            guard let lat = c.latitude, let lon = c.longitude else { return nil }
            // While a cart is held, the map shows only that cart and the desk.
            if let held, held.cart.id != c.id { return nil }
            return MapVehiclePin(id: c.id,
                                 coordinate: .init(latitude: lat, longitude: lon),
                                 symbol: "steeringwheel",
                                 isSelected: c.id == (held?.cart.id ?? selected?.id),
                                 caption: c.batteryPercent.map { "\($0)%" })
        }
        if held != nil {
            result.append(MapVehiclePin(id: "desk", coordinate: Self.desk, symbol: "building.2.fill"))
            result.append(MapVehiclePin(id: "you", coordinate: Self.you, symbol: "figure.walk"))
        }
        return result
    }

    var body: some View {
        MapCanvas(center: .seaBreeze,
                  span: 1300,
                  pins: pins,
                  focus: (held?.cart ?? selected).flatMap { c in
                      c.latitude.map { CLLocationCoordinate2D(latitude: $0, longitude: c.longitude ?? 0) }
                  },
                  // G01 has only Back — no recentre button.
                  trailingSymbol: nil,
                  // QR is in the card; the top back stays (the card has none).
                  showsControls: true,
                  insetPanel: false,
                  onSelectPin: { id in
                      guard held == nil, carts.contains(where: { $0.id == id }) else { return }
                      withAnimation(Theme.smooth) { selection = id }
                  },
                  route: held == nil ? [] : [Self.you, Self.desk],
                  onBack: { dismiss() }) {
            ZStack(alignment: .bottom) {
                if let held {
                    HeldGolfCard(cart: held.cart, hold: held.hold,
                                 onMessage: { openGolfDesk() },
                                 onStart: { book(held.cart, hours: held.hold.hours, total: held.hold.total) },
                                 onCancel: { withAnimation(Theme.expand) { store.releaseHold() } })
                        .padding(.horizontal, Theme.Space.screen)
                        .transition(.blurReplace)
                } else if mode == .hourly {
                    VehicleCarousel(items: carts, selection: $selection) { cart in
                        card(for: cart)
                    }
                    .transition(.opacity)
                } else if let cart = selected {
                    SingleMapCard { card(for: cart) }
                        .transition(.opacity.combined(with: .scale(0.98, anchor: .bottom)))
                }
            }
            .animation(Theme.expand, value: mode)
            .animation(Theme.expand, value: store.hold)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .alert("Cart could not be started", isPresented: $bookingFailed) {
            Button("View trips") { router.tab = .trips }
            Button("OK", role: .cancel) {}
        } message: { Text("Finish any active trip and check that Wallet or your card can cover the rental plus the ₼100 refundable deposit.") }
        .onAppear {
            if selection == nil { selection = carts.first?.id }
            mode = initialMode
        }
        .fullScreenCover(item: $scanning) { cart in
            ScanToUnlockView(vehicleName: cart.name,
                             onCancel: { scanning = nil },
                             onUnlock: {
                                 scanning = nil
                                 book(cart, hours: 2, total: (cart.pricePerHour ?? 20) * 2 - 2)
                             })
        }
    }

    private func card(for cart: Vehicle) -> some View {
        GolfCard(cart: cart, mode: $mode,
                 holdUntil: store.holdUntil(cart.id),
                 onBook: { hours, total in
                     // Book → G02 held state: free, paid only at Start (D9).
                     router.requireVerified(session, holding: cart.name) {
                         withAnimation(Theme.expand) { store.hold(cart, hours: hours, total: total) }
                     }
                 },
                 onCancelHold: { withAnimation(Theme.smooth) { store.releaseHold() } },
                 onScan: { scanning = cart },
                 onMessage: { openGolfDesk() }) { hours, total in
            book(cart, hours: hours, total: total)
        }
    }

    /// Reserves the cart: it goes live on Home's Golf tile, the desk confirms.
    private func book(_ cart: Vehicle, hours: Int, total: Decimal) {
        router.requireVerified(session, holding: cart.name) {
            guard store.bookGolfCart(cart, hours: hours, total: total, paymentID: paymentID) else {
                bookingFailed = true
                Haptic.error.fire()
                return
            }
            Haptic.celebrate.fire()
            store.bookingFollowUp(title: String(localized: "\(cart.name) is reserved"),
                                  detail: String(localized: "Pick up at the Sea Breeze Golf desk"),
                                  hostThreadID: "thr-golf")
            if let desk = Store.demoPeople.first(where: { $0.threadID == "thr-golf" }) {
                store.ensureThread(for: desk)
            }
            router.popToRoot(router.tab)
        }
    }

    /// Opens (or starts) the chat with the Sea Breeze Golf desk.
    private func openGolfDesk() {
        guard let desk = Store.demoPeople.first(where: { $0.threadID == "thr-golf" }) else { return }
        let isNew = !store.threads.contains { $0.id == desk.threadID }
        store.ensureThread(for: desk)
        if isNew { Task { await store.startConversation(with: desk) } }
        router.push(.thread(threadID: desk.threadID))
    }
}

/// G01's three rental modes.
enum GolfMode: String, CaseIterable, Identifiable {
    case hourly, daily, withDriver
    var id: String { rawValue }
}

/// Card / Glass map — G01's content: photo, name, meta, two native segmented
/// pickers, pickup note, and Start with the live price.
private struct GolfCard: View {
    typealias Mode = GolfMode

    let cart: Vehicle
    @Binding var mode: Mode
    var holdUntil: Date? = nil
    var onBook: (_ hours: Int, _ total: Decimal) -> Void = { _, _ in }
    var onCancelHold: () -> Void = {}
    var onScan: () -> Void = {}
    var onMessage: () -> Void = {}
    /// Hours booked and the total — hourly or daily.
    let onStart: (_ hours: Int, _ total: Decimal) -> Void

    @State private var hours = 2
    @State private var dates = RentalDates.fromNow

    /// G01a — ₼180 for two days.
    static let dayRate: Decimal = 90

    /// G02's breakdown: ₼40 ride − ₼2 discount for 2 hours.
    private var price: Decimal {
        switch mode {
        case .daily: RidePricing.cappedHours(Int(ceil(dates.dropOff.timeIntervalSince(dates.pickUp) / 3600)), hourly: cart.pricePerHour ?? 20, daily: GolfCard.dayRate)
        default:     (cart.pricePerHour ?? 20) * Decimal(hours) - 2
        }
    }

    private var startTitle: String {
        let total = (price + 100).formatted(.currency(code: Currency.code).precision(.fractionLength(0)))
        return mode == .daily
            ? String(localized: "Start · \(total)")
            : String(localized: "Start · \(total)")
    }

    var body: some View {
        VStack(spacing: 12) {
            if mode != .daily {
            HStack(spacing: 12) {
                Color.clear
                    .frame(width: 64, height: 48)
                    .background { PhotoFill(photoName: cart.photoName, symbol: "steeringwheel", glyphSize: 18) }
                    .clipShape(.rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(cart.name)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text("\(cart.seats) seats · \(cart.batteryPercent ?? 0)% · \(cart.walkMinutes ?? 2) min walk")
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 4)
                Button(action: onMessage) { Image(systemName: "message.fill") }
                    .buttonStyle(.rentbutik)
                    .buttonBorderShape(.circle)
                    .controlSize(.regular)
                    .accessibilityLabel("Message the Golf desk")
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Picker("Rental", selection: $mode) {
                Text("Hourly").tag(Mode.hourly)
                Text("Daily").tag(Mode.daily)
                Text("With driver").tag(Mode.withDriver)
            }
            .pickerStyle(.segmented)

            if mode == .hourly {
                Picker("Hours", selection: $hours) {
                    ForEach(1...4, id: \.self) { Text("\($0) h").tag($0) }
                }
                .pickerStyle(.segmented)
                .transition(.opacity)
            }

            if mode == .daily {
                // G01a — the range calendar in place of the cart details.
                RangeCalendar(dates: $dates, startLocked: true)
                    .transition(.opacity.combined(with: .scale(0.97, anchor: .top)))
            } else {
                Text("Pick up at the Sea Breeze Golf desk")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }

            if mode == .withDriver {
                Text("Driver service is confirmed by the Golf desk. Request availability before payment.").font(Theme.Font.body).foregroundStyle(Theme.inkSoft)
                Button("Request a driver", action: onMessage).buttonStyle(.rentbutik).buttonBorderShape(.capsule).controlSize(.large)
            } else {
            Label("₼100 refundable deposit · paid at Start", systemImage: "shield.lefthalf.filled")
                .font(Theme.Font.subheadlineRegular).foregroundStyle(Theme.inkSoft)
            HStack(spacing: 10) {
            ScanButton(action: onScan)
            HoldButton(until: holdUntil,
                       onBook: { onBook(mode == .daily ? max(1, Int(ceil(dates.dropOff.timeIntervalSince(dates.pickUp) / 3600))) : hours, price) },
                       onCancel: onCancelHold)
            Button {
                onStart(mode == .daily ? max(1, Int(ceil(dates.dropOff.timeIntervalSince(dates.pickUp) / 3600))) : hours, price)
            } label: {
                Text(startTitle)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 4)
            }
            .accessibilityIdentifier("golf.start.\(cart.id)")
            // Start takes its own width first; Book fills the rest.
            .layoutPriority(1)
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            }
            }
        }
        .padding(16)
        .glassMapCard()
        .animation(Theme.smooth, value: mode)
        .animation(Theme.snappy, value: hours)
        .sensoryFeedback(.selection, trigger: hours)
        .sensoryFeedback(.selection, trigger: mode)
    }
}

// MARK: - G02 · Held reservation

/// G02 (v2): the free hold. Walk to the desk, then Start pays the ride.
private struct HeldGolfCard: View {
    let cart: Vehicle
    let hold: Store.Hold
    let onMessage: () -> Void
    let onStart: () -> Void
    let onCancel: () -> Void

    @State private var confirmCancel = false

    private func money(_ v: Decimal) -> String {
        v.formatted(.currency(code: Currency.code).precision(.fractionLength(0)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Color.clear
                    .frame(width: 80, height: 60)
                    .background { PhotoFill(photoName: cart.photoName, symbol: "steeringwheel", glyphSize: 20) }
                    .clipShape(.rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(cart.name)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text("Free hold · pay at Start")
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 4)
                Button(action: onMessage) { Image(systemName: "message.fill") }
                    .buttonStyle(.rentbutik)
                    .buttonBorderShape(.circle)
                    .controlSize(.regular)
                    .accessibilityLabel("Message the Golf desk")
            }

            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(Theme.brandSolid)
                Text("Held for you ·")
                Text(timerInterval: Date.now...max(hold.until, .now), countsDown: true)
            }
            .font(Theme.Font.subheadlineSemibold)
            .foregroundStyle(Theme.ink)
            .monospacedDigit()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular.tint(Theme.brandTint), in: .capsule)

            Text("Rental \(money(hold.total)) + ₼100 refundable deposit")
                .font(Theme.Font.subheadlineRegular).foregroundStyle(Theme.inkSoft)
            Button(action: onStart) {
                Text("Start · \(money(hold.total + 100))")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)

            Button("Cancel reservation", role: .destructive) { confirmCancel = true }
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.danger)
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
        }
        .padding(16)
        .glassMapCard()
        .confirmationDialog("Cancel reservation?", isPresented: $confirmCancel, titleVisibility: .visible) {
            Button("Cancel reservation", role: .destructive, action: onCancel)
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("\(cart.name) goes back on the map for everyone.")
        }
    }
}

// MARK: - Booking

/// Photo, name, duration choice, a price breakdown, and confirm.
/// The breakdown is label → value data, so rows inside ONE card (RULE U).
struct GolfBookingScreen: View {
    let cart: Vehicle
    let store: Store
    let router: AppRouter

    enum Duration: String, CaseIterable, Identifiable {
        case oneHour, twoHours, halfDay
        var id: String { rawValue }

        var label: LocalizedStringKey {
            switch self {
            case .oneHour:  "1 hour"
            case .twoHours: "2 hours"
            case .halfDay:  "Half day"
            }
        }

        var hours: Int {
            switch self {
            case .oneHour:  1
            case .twoHours: 2
            case .halfDay:  4
            }
        }
    }

    @State private var duration: Duration = .twoHours
    @State private var bookingError = false
    @State private var bookingID = UUID().uuidString
    @ScaledMetric private var heroHeight: CGFloat = 240

    private var serviceFee: Decimal { 2 }
    private var rate: Decimal { cart.pricePerHour ?? 15 }
    private var subtotal: Decimal { rate * Decimal(duration.hours) }
    private var total: Decimal { subtotal + serviceFee }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                // RULE B2: opaque, never glass.
                // `Color.clear` bounds the frame; a bare scaledToFill image
                // reports its scaled width and drags the whole scroll content
                // wider than the screen.
                Color.clear
                    .frame(height: heroHeight)
                    .frame(maxWidth: .infinity)
                    .background {
                        PhotoFill(photoName: cart.photoName,
                                  symbol: cart.kind.symbol, glyphSize: 64)
                    }
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(cart.name)
                        .font(Theme.Font.largeTitle)
                        .foregroundStyle(Theme.ink)
                    Text("\(cart.area) · \(cart.seats) seats · 2 min walk")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, Theme.Space.screen)

                VStack(alignment: .leading, spacing: Theme.Space.gap) {
                    Text("How long?")
                        .font(Theme.Font.title3)
                        .foregroundStyle(Theme.ink)

                    HStack(spacing: 10) {
                        ForEach(Duration.allCases) { option in
                            // `.tint` style here — cream with gold text, which
                            // is what the file uses for choice chips.
                            RentbutikChip(option.label,
                                          isSelected: option == duration,
                                          style: .tint) {
                                duration = option
                            }
                        }
                    }

                    GolfPriceCard(rate: rate,
                                  hours: duration.hours,
                                  subtotal: subtotal,
                                  serviceFee: serviceFee,
                                  total: total)

                    Text("₼100 refundable deposit is collected separately with the rental.")
                        .font(Theme.Font.footnote).foregroundStyle(Theme.inkSoft)
                    // A confirmed booking is the ONLY place `celebrate` fires.
                    RentbutikPrimaryButton("Confirm booking", haptic: .celebrate) {
                        guard store.bookGolfCart(cart, hours: duration.hours, total: total, paymentID: bookingID) else { bookingError = true; return }
                        // Back to Home, where the Golf tile now carries the ride.
                        router.popToRoot(router.tab)
                    }
                }
                .padding(.horizontal, Theme.Space.screen)
            }
            .padding(.bottom, Theme.Space.gap)
        }
        .background(Theme.background)
        .navigationTitle("Booking")
        .navigationBarTitleDisplayMode(.inline)
        .animation(Theme.snappy, value: duration)
        .alert("Booking unavailable", isPresented: $bookingError) { Button("OK", role: .cancel) {} } message: { Text("Check payment for the rental plus ₼100 refundable deposit, and finish any active trip first.") }
    }
}

private struct GolfPriceCard: View {
    let rate: Decimal
    let hours: Int
    let subtotal: Decimal
    let serviceFee: Decimal
    let total: Decimal

    private var money: Decimal.FormatStyle.Currency {
        .currency(code: Currency.code).precision(.fractionLength(0))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(rate, format: money) × \(hours) hours")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 8)
                Text(subtotal, format: money)
                    .font(Theme.Font.moneyRow)
                    .foregroundStyle(Theme.ink)
            }

            HStack {
                Text("Service fee")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 8)
                Text(serviceFee, format: money)
                    .font(Theme.Font.moneyRow)
                    .foregroundStyle(Theme.ink)
            }

            Divider().overlay(Theme.hairline)

            HStack(alignment: .firstTextBaseline) {
                Text("Total")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Text(total, format: money)
                    .font(Theme.Font.moneyLarge)
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(16)
        .glassCard(Theme.Radius.card)
    }
}

#Preview("Golf booking") {
    let store = Store.seeded()
    return NavigationStack {
        GolfBookingScreen(cart: store.vehicles.first { $0.kind == .golfCart }!,
                          store: store, router: AppRouter())
    }
}

#Preview("G01 · Select golf cart") {
    NavigationStack {
        GolfMapScreen(store: .seeded(), router: AppRouter())
    }
    .environment(Session())
}

#Preview("G01a · Daily") {
    NavigationStack {
        GolfMapScreen(store: .seeded(), router: AppRouter(), initialMode: .daily)
    }
    .environment(Session())
}

#Preview("G02 · Held reservation") {
    let store = Store.seeded()
    if let cart = store.vehicles.first(where: { $0.kind == .golfCart }) {
        store.hold(cart, hours: 2, total: 40)
    }
    return NavigationStack {
        GolfMapScreen(store: store, router: AppRouter())
    }
    .environment(Session())
}

