import SwiftUI
import MapKit

// MARK: - Data  (verbatim from section 11 · Transfer)

struct TransferRide: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case airport, tour, intercity
        var id: String { rawValue }
        var label: LocalizedStringKey {
            switch self {
            case .airport:   "Airport"
            case .tour:      "Day tours"
            case .intercity: "Between cities"
            }
        }
    }
    enum When: String, CaseIterable, Identifiable {
        case today, weekend, onRequest
        var id: String { rawValue }
    }

    let id: String
    let title: String
    let kind: Kind
    let when: When
    let driver: String
    let car: String
    let photo: String
    /// "today 18:00", "Sat 09:00", "on request" — as TR01 prints it.
    let departs: String
    /// TR02's summary line: "Today · 18:00 · about 35 min".
    let summary: String
    let pricePerSeat: Decimal
    let wholeCar: Decimal
    let seatsLeft: Int
    /// The trailing pill: "3 seats left", "Whole car ₼160".
    let availability: String
    let rating: Double
    let ratingCount: Int
    let rides: Int
    let pickup: String
    let dropOff: String
    let departTime: String
    let arriveTime: String
    let from: CLLocationCoordinate2D
    let to: CLLocationCoordinate2D
    let order: Int   // soonest first

    static func == (l: Self, r: Self) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

enum TransferCatalog {
    private static let nizami = CLLocationCoordinate2D(latitude: 40.3777, longitude: 49.8395)
    private static let airport = CLLocationCoordinate2D(latitude: 40.4675, longitude: 50.0467)

    static let rides: [TransferRide] = [
        .init(id: "gyd", title: "Baku → Airport", kind: .airport, when: .today,
              driver: "Hasan", car: "Mercedes-AMG GT", photo: "mercedesAMGGT",
              departs: "today 18:00", summary: "Today · 18:00 · about 35 min",
              pricePerSeat: 15, wholeCar: 50, seatsLeft: 3, availability: "3 seats left",
              rating: 4.9, ratingCount: 38, rides: 128,
              pickup: "Nizami St. 12", dropOff: "Heydar Aliyev Airport, Terminal 1",
              departTime: "18:00", arriveTime: "18:35", from: nizami, to: airport, order: 0),
        .init(id: "qabala", title: "Baku → Qabala · day tour", kind: .tour, when: .weekend,
              driver: "Nigar", car: "Ford Mustang GT", photo: "fordMustangGT",
              departs: "Sat 09:00", summary: "Sat · 09:00 · about 3 h 30 min",
              pricePerSeat: 30, wholeCar: 110, seatsLeft: 2, availability: "2 seats left",
              rating: 4.8, ratingCount: 21, rides: 64,
              pickup: "Fountains Square", dropOff: "Qabala, Tufandag",
              departTime: "09:00", arriveTime: "12:30",
              from: .init(latitude: 40.3703, longitude: 49.8372),
              to: .init(latitude: 40.9814, longitude: 47.8458), order: 2),
        .init(id: "sheki", title: "Baku → Sheki", kind: .intercity, when: .weekend,
              driver: "Rashad", car: "Porsche 911 GT3 RS", photo: "porsche911GT3RS",
              departs: "Sun 08:00", summary: "Sun · 08:00 · about 4 h 30 min",
              pricePerSeat: 45, wholeCar: 160, seatsLeft: 1, availability: "Whole car ₼160",
              rating: 5.0, ratingCount: 12, rides: 40,
              pickup: "28 Mall", dropOff: "Sheki Khan’s Palace",
              departTime: "08:00", arriveTime: "12:30",
              from: .init(latitude: 40.3790, longitude: 49.8490),
              to: .init(latitude: 41.2030, longitude: 47.1920), order: 3),
        .init(id: "gobustan", title: "Gobustan & mud volcanoes", kind: .tour, when: .weekend,
              driver: "Leyla", car: "McLaren 650S", photo: "mcLaren650S",
              departs: "Sat 10:00", summary: "Sat · 10:00 · about 1 h",
              pricePerSeat: 40, wholeCar: 140, seatsLeft: 1, availability: "1 seat left",
              rating: 4.9, ratingCount: 9, rides: 31,
              pickup: "Sahil metro", dropOff: "Gobustan National Park",
              departTime: "10:00", arriveTime: "11:00",
              from: .init(latitude: 40.3712, longitude: 49.8455),
              to: .init(latitude: 40.1117, longitude: 49.3736), order: 1),
        .init(id: "gyd-in", title: "Airport → Baku", kind: .airport, when: .onRequest,
              driver: "Elvin", car: "Lamborghini Aventador", photo: "lamborghiniAventador",
              departs: "on request", summary: "On request · about 35 min",
              pricePerSeat: 25, wholeCar: 90, seatsLeft: 4, availability: "4 seats",
              rating: 4.9, ratingCount: 17, rides: 52,
              pickup: "Heydar Aliyev Airport, Terminal 1", dropOff: "Your address in Baku",
              departTime: "—", arriveTime: "—", from: airport, to: nizami, order: 4),
        .init(id: "shahdag", title: "Baku → Shahdag · mountain day", kind: .tour, when: .weekend,
              driver: "Kamran", car: "Ferrari SF90", photo: "ferrariSF90",
              departs: "Sun 07:30", summary: "Sun · 07:30 · about 3 h",
              pricePerSeat: 70, wholeCar: 130, seatsLeft: 1, availability: "1 seat left",
              rating: 5.0, ratingCount: 7, rides: 18,
              pickup: "Port Baku Towers", dropOff: "Shahdag Mountain Resort",
              departTime: "07:30", arriveTime: "10:30",
              from: .init(latitude: 40.3727, longitude: 49.8605),
              to: .init(latitude: 41.3150, longitude: 48.1320), order: 5),
    ]
}

private func money(_ v: Decimal) -> String {
    v.formatted(.currency(code: Currency.code).precision(.fractionLength(0)))
}

// MARK: - TR01 · Transfers

enum TransferSort: String, CaseIterable, Identifiable {
    case soonest, priceLow, priceHigh
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .soonest:   "Departing soonest"
        case .priceLow:  "Price: Low to High"
        case .priceHigh: "Price: High to Low"
        }
    }
}

/// Tab-bar screen with the Renter layout: glass chips, photo cards that open
/// in place (TR01b), the stops sheet (TR01c) and the empty state (TR01e).
struct TransferListScreen: View {
    let store: Store
    let router: AppRouter

    @State private var kind: TransferRide.Kind?
    @State private var when: TransferRide.When?
    @State private var sort: TransferSort?
    @State private var savedOnly = false
    @State private var saved: Set<String> = ["gyd"]
    @State private var openID: String?
    @State private var routeFor: TransferRide?
    @State private var showMap = false
    @State private var searching = false
    @State private var query = ""
    @State private var notified = false

    private var results: [TransferRide] {
        let base = TransferCatalog.rides.filter {
            (kind == nil || $0.kind == kind)
                && (when == nil || $0.when == when)
                && (!savedOnly || saved.contains($0.id))
                && (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query)
                    || $0.pickup.localizedCaseInsensitiveContains(query)
                    || $0.dropOff.localizedCaseInsensitiveContains(query))
        }
        switch sort {
        case nil:        return base
        case .soonest:   return base.sorted { $0.order < $1.order }
        case .priceLow:  return base.sorted { $0.pricePerSeat < $1.pricePerSeat }
        case .priceHigh: return base.sorted { $0.pricePerSeat > $1.pricePerSeat }
        }
    }

    var body: some View {
        Group {
            if showMap {
                TransferMap(rides: results, openRoute: { routeFor = $0 })
                    .transition(.opacity)
            } else {
                list.transition(.opacity)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { chips }
        .background(Theme.background)
        .navigationTitle("Transfers")
        .navigationSubtitle("Rides & tours from Baku")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Search", systemImage: "magnifyingglass") { searching = true }
                Button(showMap ? "List" : "Map", systemImage: showMap ? "list.bullet" : "map") {
                    withAnimation(Theme.smooth) { showMap.toggle() }
                }
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .tint(Theme.ink)
        .modifier(TransferSearch(isActive: $searching, query: $query))
        .sheet(item: $routeFor) { TransferRouteSheet(ride: $0) }
        .sensoryFeedback(.selection, trigger: showMap)
        .sensoryFeedback(.selection, trigger: sort)
        .sensoryFeedback(.selection, trigger: savedOnly)
        .sensoryFeedback(.impact(weight: .light), trigger: saved)
        .animation(Theme.smooth, value: results.map(\.id))
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Space.gap) {
                if results.isEmpty { empty }
                ForEach(results) { ride in
                    PhotoListingCard(title: ride.title,
                                     subtitle: "\(ride.driver) · \(ride.car) · \(ride.departs)",
                                     photo: ride.photo,
                                     leadingPill: "\(money(ride.pricePerSeat)) / seat",
                                     trailingPill: ride.availability,
                                     isOpen: openID == ride.id,
                                     isSaved: saved.contains(ride.id),
                                     onToggle: { withAnimation(Theme.expand) { openID = openID == ride.id ? nil : ride.id } },
                                     onSave: { toggleSaved(ride.id) }) {
                        ListingDetailsBody(price: money(ride.pricePerSeat),
                                           priceSuffix: "/ seat · \(money(ride.wholeCar)) whole car",
                                           rating: ride.rating, ratingCount: ride.ratingCount,
                                           person: ride.driver,
                                           role: "Driver · \(ride.rides) rides",
                                           secondaryTitle: "Route", secondarySymbol: "info.circle",
                                           primaryTitle: "Book a seat",
                                           onMessage: { router.push(.thread(threadID: "thr-hasan")) },
                                           onSecondary: { routeFor = ride },
                                           onPrimary: { router.push(.transferBook(rideID: ride.id)) })
                    }
                    .transition(.opacity.combined(with: .scale(0.96, anchor: .top)))
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, 4)
            .padding(.bottom, Theme.Space.gap)
        }
    }

    /// TR01e when a route AND a day are chosen; otherwise the plain filters card.
    @ViewBuilder private var empty: some View {
        if let kind, let when {
            ListingEmptyCard(title: String(localized: "No \(String(localized: kindName(kind))) rides \(String(localized: whenName(when)))"),
                             detail: "We’ll tell you as soon as a driver posts this route.",
                             notifyTitle: "Get notified", notified: $notified)
        } else {
            ListingEmptyCard(title: String(localized: "No rides match your filters"),
                             detail: "Try a lower seat count or another car type, or clear your filters.",
                             notified: $notified)
        }
    }

    private func kindName(_ k: TransferRide.Kind) -> String.LocalizationValue {
        switch k { case .airport: "airport"; case .tour: "tour"; case .intercity: "intercity" }
    }
    private func whenName(_ w: TransferRide.When) -> String.LocalizationValue {
        switch w { case .today: "today"; case .weekend: "this weekend"; case .onRequest: "on request" }
    }

    private var chips: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer {
                HStack(spacing: 6) {
                    Menu {
                        Picker("Route", selection: $kind) {
                            Text("All routes").tag(TransferRide.Kind?.none)
                            ForEach(TransferRide.Kind.allCases) { Text($0.label).tag(TransferRide.Kind?.some($0)) }
                        }
                        .pickerStyle(.inline)
                    } label: { FilterChipLabel(title: "Route", symbol: "line.3.horizontal.decrease") }

                    Menu {
                        Picker("Date", selection: $when) {
                            Text("Any day").tag(TransferRide.When?.none)
                            Text("Today").tag(TransferRide.When?.some(.today))
                            Text("This weekend").tag(TransferRide.When?.some(.weekend))
                            Text("On request").tag(TransferRide.When?.some(.onRequest))
                        }
                        .pickerStyle(.inline)
                    } label: { FilterChipLabel(title: "Date", symbol: "calendar") }

                    Button { savedOnly.toggle() } label: {
                        Label("Saved", systemImage: savedOnly ? "heart.fill" : "heart")
                            .labelStyle(ChipLabelStyle(iconColor: Theme.danger))
                    }
                    .symbolEffect(.bounce, value: savedOnly)

                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(TransferSort.allCases) { Text($0.label).tag(TransferSort?.some($0)) }
                        }
                        .pickerStyle(.inline)
                    } label: { FilterChipLabel(title: "Sort", symbol: "arrow.up.arrow.down") }
                }
                .filterChipStyle()
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: kind)
        .sensoryFeedback(.selection, trigger: when)
    }

    private func toggleSaved(_ id: String) {
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
    }
}

/// Search behind the toolbar button, attached only while searching (as R01).
private struct TransferSearch: ViewModifier {
    @Binding var isActive: Bool
    @Binding var query: String

    func body(content: Content) -> some View {
        if isActive {
            content.searchable(text: $query, isPresented: $isActive,
                               placement: .navigationBarDrawer(displayMode: .always),
                               prompt: "City, airport or address")
        } else {
            content
        }
    }
}

/// Map mode — pickup points with their seat price.
private struct TransferMap: View {
    let rides: [TransferRide]
    let openRoute: (TransferRide) -> Void

    @State private var camera: MapCameraPosition = .region(.init(
        center: .init(latitude: 40.3900, longitude: 49.8700),
        latitudinalMeters: 16000, longitudinalMeters: 16000))
    @State private var selected: String?

    var body: some View {
        Map(position: $camera) {
            ForEach(rides) { r in
                Annotation(r.title, coordinate: r.from, anchor: .center) {
                    let isOn = r.id == (selected ?? rides.first?.id)
                    Button { withAnimation(Theme.bouncy) { selected = r.id } } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "figure.wave")
                                .font(.system(size: isOn ? 20 : 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: isOn ? 50 : 36, height: isOn ? 50 : 36)
                                .background(Theme.brandSolid, in: .circle)
                                .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                            Text(money(r.pricePerSeat))
                                .font(Theme.Font.captionSemibold)
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .ignoresSafeArea(edges: .top)
        // Swipe the ride cards like EV01; the pin and camera follow.
        .safeAreaInset(edge: .bottom) {
            VehicleCarousel(items: rides, selection: $selected) { r in
                MapListingCard(title: r.title, subtitle: "\(r.driver) · \(r.car) · \(r.departs)",
                               photo: r.photo, price: "\(money(r.pricePerSeat)) / seat",
                               badge: r.availability) { openRoute(r) }
            }
            .padding(.bottom, 8)
        }
        .onAppear { if selected == nil { selected = rides.first?.id } }
        .onChange(of: selected) { _, id in
            guard let r = rides.first(where: { $0.id == id }) else { return }
            withAnimation(Theme.smooth) {
                camera = .region(.init(center: r.from, latitudinalMeters: 9000, longitudinalMeters: 9000))
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }
}

// MARK: - TR01c · Route sheet (stops)

/// A real driving route from MapKit between pickup and drop-off, with the
/// two timed stops underneath. Falls back to a straight line offline.
struct TransferRouteSheet: View {
    let ride: TransferRide
    @Environment(\.dismiss) private var dismiss
    @State private var route: MKRoute?

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                VStack(spacing: 1) {
                    Text(ride.title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text(verbatim: "\(ride.driver) · \(ride.summary)")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.goldText)
                        .buttonStyle(.rentbutik)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                }
            }

            Map(interactionModes: []) {
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(Theme.brandSolid, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                } else {
                    MapPolyline(coordinates: [ride.from, ride.to])
                        .stroke(Theme.brandSolid.opacity(0.6), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [6, 6]))
                }
                Marker("", systemImage: "figure.wave", coordinate: ride.from).tint(Theme.brandSolid)
                Marker("", systemImage: "flag.checkered", coordinate: ride.to).tint(Theme.brandSolid)
            }
            .mapStyle(.standard(emphasis: .muted))
            .frame(height: 170)
            .clipShape(.rect(cornerRadius: Theme.Radius.group))
            .animation(Theme.smooth, value: route != nil)

            GroupedCard {
                StopRow(time: ride.departTime, place: "Pickup · \(ride.pickup)", divider: true)
                StopRow(time: ride.arriveTime, place: ride.dropOff, divider: false)
            }
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .fittedSheet()
        .task { route = await Self.directions(from: ride.from, to: ride.to) }
    }

    static func directions(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: from.latitude, longitude: from.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: to.latitude, longitude: to.longitude), address: nil)
        request.transportType = .automobile
        return try? await MKDirections(request: request).calculate().routes.first
    }
}

private struct StopRow: View {
    let time: String
    let place: String
    let divider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text(time)
                    .font(Theme.Font.subheadlineSemibold)
                    .foregroundStyle(Theme.goldText)
                    .monospacedDigit()
                    .frame(width: 44, alignment: .leading)
                Text(place)
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 48)
            if divider { Divider().overlay(Theme.hairline) }
        }
    }
}

// MARK: - TR02 · Book a ride

struct TransferBookScreen: View {
    let ride: TransferRide
    let store: Store
    let router: AppRouter

    enum Seats: Hashable { case count(Int), wholeCar }

    @Environment(Session.self) private var session
    @State private var seats: Seats = .count(1)
    @State private var showRoute = false
    @State private var method: RenterCheckoutScreen.PayMethod = .wallet
    @State private var booked = 0

    private var subtotal: Decimal {
        switch seats {
        case .count(let n): ride.pricePerSeat * Decimal(n)
        case .wholeCar:     ride.wholeCar
        }
    }
    /// ₼1 on a ₼15 seat — about 5 %, never below ₼1.
    private var serviceFee: Decimal {
        var raw = subtotal * Decimal(0.05), rounded = Decimal()
        NSDecimalRound(&rounded, &raw, 0, .up)
        return max(rounded, 1)
    }
    private var total: Decimal { subtotal + serviceFee }

    private var seatsLabel: String {
        switch seats {
        case .count(let n): String(localized: "\(n) seat × \(money(ride.pricePerSeat))")
        case .wholeCar:     String(localized: "Whole car")
        }
    }

    private func methodLabel(_ m: RenterCheckoutScreen.PayMethod) -> String {
        switch m {
        case .wallet:   String(localized: "Wallet · \(store.walletBalance.formatted(.currency(code: Currency.code).precision(.fractionLength(2))))")
        case .visa:     String(localized: "Visa •••• 4242")
        case .applePay: String(localized: "Apple Pay")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                summary

                Text("Seats")
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 4)
                Picker("Seats", selection: $seats) {
                    ForEach(1...3, id: \.self) { n in
                        Text(n == 1 ? "1 seat" : "\(n) seats").tag(Seats.count(n))
                            .selectionDisabled(n > ride.seatsLeft)
                    }
                    Text("Whole car").tag(Seats.wholeCar)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    line(seatsLabel, subtotal)
                    line(String(localized: "Service fee"), serviceFee)
                    Divider().overlay(Theme.hairline)
                    line(String(localized: "Total"), total)
                }
                .padding(16)
                .glassCard(Theme.Radius.card)
                .animation(Theme.snappy, value: seats)

                Text("Flexible cancellation: free until 2 h before. Paid after the ride — Wallet first, then your card.")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 2)

                HStack {
                    Text("Pay with")
                        .font(Theme.Font.subheadlineRegular)
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Picker("Pay with", selection: $method) {
                        ForEach(RenterCheckoutScreen.PayMethod.allCases) { Text(methodLabel($0)).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.ink)
                    .fontWeight(.semibold)
                }
                .padding(.leading, 16)
                .padding(.trailing, 4)
                .frame(minHeight: 48)
                .glassCard(Theme.Radius.card)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.gap)
        }
        .background(Theme.background)
        .navigationTitle("Book a ride")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: book) {
                Text("Book · \(money(total))")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showRoute) { TransferRouteSheet(ride: ride) }
        .sensoryFeedback(.selection, trigger: seats)
        .sensoryFeedback(.selection, trigger: method)
        .sensoryFeedback(.success, trigger: booked)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(ride.title)
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                Text(ride.summary)
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Driver").foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(verbatim: "\(ride.driver) · ★ \(ride.rating.formatted(.number.precision(.fractionLength(1))))")
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.ink)
            }
            .font(Theme.Font.subheadlineRegular)

            Button { showRoute = true } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "figure.wave")
                        .foregroundStyle(Theme.brandSolid)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pickup · \(ride.pickup)")
                            .font(Theme.Font.subheadlineRegular)
                            .foregroundStyle(Theme.ink)
                        Text("Drop-off · \(ride.dropOff)")
                            .font(Theme.Font.footnoteRegular)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(Theme.Font.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxHeight: .infinity)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(Theme.Radius.card)
    }

    private func line(_ label: String, _ value: Decimal) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(money(value))
                .fontWeight(.semibold)
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
        }
        .font(Theme.Font.subheadlineRegular)
    }

    /// Nothing is charged now — TR02 says "Paid after the ride".
    private func book() {
        guard AppConfiguration.isDemo else { return }
        router.requireVerified(session, holding: ride.title) {
            booked += 1
            store.addBooking(TripRecord(
                id: UUID().uuidString, kind: .transfer, title: ride.title,
                status: "Booked", tone: .success, amount: .money(total),
                rows: [.init(label: String(localized: "When"), value: ride.summary),
                       .init(label: String(localized: "Pickup"), value: ride.pickup),
                       .init(label: String(localized: "Driver"), value: "\(ride.driver) · \(ride.car)")],
                note: String(localized: "Paid after the ride — Wallet first, then your card."),
                actions: [.message, .cancelBooking], threadID: "thr-support"))
            store.bookingFollowUp(title: String(localized: "Your seat is booked"),
                                  detail: "\(ride.title) · \(ride.departs)")
            router.popToRoot(router.tab)
            router.tab = .trips
        }
    }
}

// MARK: - Previews

#Preview("TR01 · Transfers") {
    NavigationStack { TransferListScreen(store: .seeded(), router: AppRouter()) }
        .environment(Session())
}

#Preview("TR02 · Book a ride") {
    NavigationStack {
        TransferBookScreen(ride: TransferCatalog.rides[0], store: .seeded(), router: AppRouter())
    }
    .environment(Session())
}

#Preview("TR01c · Route") {
    Color.clear.sheet(isPresented: .constant(true)) {
        TransferRouteSheet(ride: TransferCatalog.rides[0])
    }
}

