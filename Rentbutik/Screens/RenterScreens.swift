import SwiftUI
import MapKit

// MARK: - Data  (verbatim from section 08 · Renter)

struct RenterListing: Identifiable, Hashable {
    enum CarType: String, CaseIterable, Identifiable {
        case sedan, suv, hatchback, coupe, convertible
        var id: String { rawValue }
        var label: LocalizedStringKey {
            switch self {
            case .sedan:       "Sedan"
            case .suv:         "SUV"
            case .hatchback:   "Hatchback"
            case .coupe:       "Coupe"
            case .convertible: "Convertible"
            }
        }
        /// "Sedan, SUV" — the Car type row's summary in R01c.
        var name: String {
            switch self {
            case .sedan:       String(localized: "Sedan")
            case .suv:         String(localized: "SUV")
            case .hatchback:   String(localized: "Hatchback")
            case .coupe:       String(localized: "Coupe")
            case .convertible: String(localized: "Convertible")
            }
        }
        /// "No SUVs free on 28–29 Sep" — R01h.
        var plural: String {
            switch self {
            case .sedan:       String(localized: "sedans")
            case .suv:         String(localized: "SUVs")
            case .hatchback:   String(localized: "hatchbacks")
            case .coupe:       String(localized: "coupes")
            case .convertible: String(localized: "convertibles")
            }
        }
    }

    let id: String
    let name: String
    let host: String
    let hostFullName: String
    let photo: String
    let pricePerDay: Decimal
    let instantBook: Bool
    let rating: Double
    let ratingCount: Int
    let area: String
    let type: CarType
    let seats: Int
    let transmission: Transmission
    let fuel: FuelType
    let latitude: Double
    let longitude: Double
    let listedAt: Int      // ordering for "Newest first"
    let distanceKm: Double // ordering for "Distance"

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var bookingLabel: LocalizedStringKey { instantBook ? "Instant Book" : "By request" }
}

enum RenterCatalog {
    static let listings: [RenterListing] = [
        .init(id: "amg", name: "Mercedes-AMG GT", host: "Hasan", hostFullName: "Hasan Nabiyev",
              photo: "mercedesAMGGT", pricePerDay: 380, instantBook: true, rating: 4.9, ratingCount: 38,
              area: "Sahil", type: .coupe, seats: 2, transmission: .automatic, fuel: .petrol,
              latitude: 40.3712, longitude: 49.8455, listedAt: 3, distanceKm: 0.8),
        .init(id: "mustang", name: "Ford Mustang GT", host: "Nigar", hostFullName: "Nigar",
              photo: "fordMustangGT", pricePerDay: 220, instantBook: false, rating: 4.8, ratingCount: 21,
              area: "Nasimi", type: .coupe, seats: 4, transmission: .automatic, fuel: .petrol,
              latitude: 40.3790, longitude: 49.8300, listedAt: 5, distanceKm: 1.6),
        .init(id: "gt3rs", name: "Porsche 911 GT3 RS", host: "Rashad", hostFullName: "Rashad",
              photo: "porsche911GT3RS", pricePerDay: 650, instantBook: true, rating: 5.0, ratingCount: 12,
              area: "Yasamal", type: .coupe, seats: 2, transmission: .automatic, fuel: .petrol,
              latitude: 40.3668, longitude: 49.8580, listedAt: 4, distanceKm: 1.2),
        .init(id: "650s", name: "McLaren 650S Spider", host: "Leyla", hostFullName: "Leyla",
              photo: "mcLaren650S", pricePerDay: 700, instantBook: false, rating: 4.9, ratingCount: 9,
              area: "Sabail", type: .convertible, seats: 2, transmission: .automatic, fuel: .petrol,
              latitude: 40.3640, longitude: 49.8345, listedAt: 2, distanceKm: 2.1),
        .init(id: "aventador", name: "Lamborghini Aventador", host: "Elvin", hostFullName: "Elvin",
              photo: "lamborghiniAventador", pricePerDay: 900, instantBook: true, rating: 4.9, ratingCount: 17,
              area: "Narimanov", type: .coupe, seats: 2, transmission: .automatic, fuel: .petrol,
              latitude: 40.3835, longitude: 49.8620, listedAt: 1, distanceKm: 2.6),
        .init(id: "sf90", name: "Ferrari SF90 Stradale", host: "Kamran", hostFullName: "Kamran Huseynov",
              photo: "ferrariSF90", pricePerDay: 1100, instantBook: true, rating: 5.0, ratingCount: 7,
              area: "White City", type: .coupe, seats: 2, transmission: .automatic, fuel: .hybrid,
              latitude: 40.3790, longitude: 49.8710, listedAt: 6, distanceKm: 3.1),
    ]

    /// R01g · Features — the same list for every car until hosts can edit it.
    static let features: [(symbol: String, label: LocalizedStringKey)] = [
        ("snowflake", "Air conditioning"),
        ("fire.extinguisher.fill", "Fire extinguisher"),
        ("wave.3.right", "Bluetooth audio"),
        ("wrench.and.screwdriver.fill", "Tools"),
        ("cable.connector", "Audio input"),
        ("gift.fill", "Special occasion"),
        ("location.fill", "GPS"),
        ("airplane.arrival", "Airport pick-up"),
        ("road.lanes", "300 km / day included"),
        ("airplane.departure", "Airport drop-off"),
        ("cross.case.fill", "First aid kit"),
    ]
}

/// Pick-up and return, shared by R01a and R04.
struct RentalDates: Hashable {
    var pickUp: Date
    var dropOff: Date

    /// Every started 24 h counts as a day (decision D6).
    var days: Int {
        RidePricing.rentalDays(duration: dropOff.timeIntervalSince(pickUp))
    }

    /// "28–29 Sep"
    var rangeLabel: String {
        let cal = Calendar.current
        if cal.isDate(pickUp, equalTo: dropOff, toGranularity: .month) {
            return "\(pickUp.formatted(.dateTime.day()))–\(dropOff.formatted(.dateTime.day().month(.abbreviated)))"
        }
        return "\(pickUp.formatted(.dateTime.day().month(.abbreviated)))–\(dropOff.formatted(.dateTime.day().month(.abbreviated)))"
    }

    /// Two days out at 10:00, returned the next day — R01a's defaults.
    static var standard: RentalDates {
        let cal = Calendar.current
        let base = cal.date(byAdding: .day, value: 2, to: cal.startOfDay(for: .now)) ?? .now
        let start = cal.date(bySettingHour: 10, minute: 0, second: 0, of: base) ?? base
        return RentalDates(pickUp: start, dropOff: cal.date(byAdding: .day, value: 1, to: start) ?? start)
    }

    /// G01a — today → today + 2 at 22:00, picked up at the next full hour.
    static var golfDaily: RentalDates {
        let cal = Calendar.current
        let now = Date.now
        let nextHour = cal.nextDate(after: now, matching: DateComponents(minute: 0),
                                    matchingPolicy: .nextTime) ?? now
        let base = cal.date(byAdding: .day, value: 2, to: now) ?? now
        let back = cal.date(bySettingHour: 22, minute: 0, second: 0, of: base) ?? base
        return RentalDates(pickUp: nextHour, dropOff: back)
    }

    /// EV day tariff — the ride starts now; only the return is chosen.
    static var fromNow: RentalDates {
        let now = Date.now
        return RentalDates(pickUp: now, dropOff: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now)
    }
}

private func money(_ v: Decimal) -> String {
    v.formatted(.currency(code: Currency.code).precision(.fractionLength(0)))
}

// MARK: - R01 · Cars near you

enum RenterSort: String, CaseIterable, Identifiable {
    case priceLow, priceHigh, newest, distance
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .priceLow:  "Price: Low to High"
        case .priceHigh: "Price: High to Low"
        case .newest:    "Newest first"
        case .distance:  "Distance"
        }
    }
}

struct RenterFilters: Equatable {
    enum Price: String, CaseIterable, Identifiable {
        case any, under300, from300to700, over700
        var id: String { rawValue }
        var label: LocalizedStringKey {
            switch self {
            case .any:          "Any"
            case .under300:     "Under ₼300"
            case .from300to700: "₼300–700"
            case .over700:      "Over ₼700"
            }
        }
        func matches(_ p: Decimal) -> Bool {
            switch self {
            case .any:          true
            case .under300:     p < 300
            case .from300to700: p >= 300 && p <= 700
            case .over700:      p > 700
            }
        }
    }

    var price: Price = .any
    var types: Set<RenterListing.CarType> = []
    var transmission: Transmission?
    var fuel: FuelType?
    var minSeats: Int?

    func matches(_ l: RenterListing) -> Bool {
        price.matches(l.pricePerDay)
            && (types.isEmpty || types.contains(l.type))
            && (transmission == nil || transmission == l.transmission)
            && (fuel == nil || fuel == l.fuel)
            && (minSeats.map { l.seats >= $0 } ?? true)
    }
}

/// Tab-bar screen: glass filter chips, then photo listing cards that open
/// IN PLACE (R01b). The map toggle (R01f) swaps the list for a live map.
struct RenterListScreen: View {
    let store: Store
    let router: AppRouter
    var initialOpenID: String? = nil

    @State private var filters = RenterFilters()
    /// `nil` keeps the recommended order R01 draws.
    @State private var sort: RenterSort?
    @State private var dates = RentalDates.standard
    @State private var savedOnly = false
    @State private var saved: Set<String> = ["amg"]
    @State private var openID: String?
    @State private var detailsFor: RenterListing?
    @State private var showDates = false
    @State private var showMap = false
    @State private var searching = false
    @State private var query = ""
    @State private var notified = false

    init(store: Store, router: AppRouter, initialOpenID: String? = nil) {
        self.store = store
        self.router = router
        self.initialOpenID = initialOpenID
        _openID = State(initialValue: initialOpenID)
    }

    private var results: [RenterListing] {
        let base = RenterCatalog.listings.filter {
            filters.matches($0)
                && (!savedOnly || saved.contains($0.id))
                && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)
                    || $0.area.localizedCaseInsensitiveContains(query))
        }
        switch sort {
        case nil:        return base
        case .priceLow:  return base.sorted { $0.pricePerDay < $1.pricePerDay }
        case .priceHigh: return base.sorted { $0.pricePerDay > $1.pricePerDay }
        case .newest:    return base.sorted { $0.listedAt > $1.listedAt }
        case .distance:  return base.sorted { $0.distanceKm < $1.distanceKm }
        }
    }

    private var subtitle: String {
        results.isEmpty ? String(localized: "No matches")
                        : String(localized: "\(results.count) cars in Baku")
    }

    var body: some View {
        Group {
            if showMap {
                RenterMap(listings: results, saved: $saved, openID: $openID) { id in
                    // Tapping a map card opens it in the list, in place.
                    withAnimation(Theme.smooth) { showMap = false }
                    withAnimation(Theme.expand) { openID = id }
                }
                    .transition(.opacity)
            } else {
                list
                    .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RenterChips(filters: $filters, sort: $sort, savedOnly: $savedOnly,
                        showDates: $showDates, dates: $dates, resultCount: results.count)
        }
        .background(Theme.background)
        .navigationTitle("Cars near you")
        .navigationSubtitle(subtitle)
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
        .modifier(RenterSearch(isActive: $searching, query: $query))
        .sensoryFeedback(.selection, trigger: showMap)
        .sensoryFeedback(.selection, trigger: sort)
        .sensoryFeedback(.impact(weight: .light), trigger: saved)
        .sheet(item: $detailsFor) { RenterDetailsSheet(listing: $0) }
        .animation(Theme.smooth, value: results.map(\.id))
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Space.gap) {
                if results.isEmpty {
                    RenterEmptyCard(title: emptyTitle, detail: emptyDetail,
                                    showsNotify: filters.types.count == 1, notified: $notified)
                }
                ForEach(results) { listing in
                    ListingCard(listing: listing,
                                isOpen: openID == listing.id,
                                isSaved: saved.contains(listing.id),
                                onToggle: { open(listing.id) },
                                onSave: { toggleSaved(listing.id) },
                                onMessage: { router.push(.thread(threadID: "thr-hasan")) },
                                onDetails: { detailsFor = listing },
                                onBook: { router.push(.checkout(listingID: listing.id, dates: dates)) })
                    // Saved / filters remove and restore cards without a jump.
                    .transition(.opacity.combined(with: .scale(0.96, anchor: .top)))
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, 4)
            .padding(.bottom, Theme.Space.gap)
        }
    }

    private var emptyTitle: String {
        if filters.types.count == 1, let type = filters.types.first {
            return String(localized: "No \(type.plural) free on \(dates.rangeLabel)")
        }
        return String(localized: "No cars match these filters")
    }
    private var emptyDetail: LocalizedStringKey {
        filters.types.count == 1 ? "We’ll tell you when one frees up."
            : "Try a lower seat count or another car type, or clear your filters."
    }

    private func open(_ id: String) {
        withAnimation(Theme.expand) { openID = openID == id ? nil : id }
    }
    private func toggleSaved(_ id: String) {
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
    }
}

/// Search lives behind the toolbar button, as R01 draws it. The native field
/// is attached under the title only while searching, because iOS 27 would
/// otherwise park a permanent search bar at the bottom of the screen.
private struct RenterSearch: ViewModifier {
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

// MARK: Chips · Filters (R01c/d) · Dates (R01a) · Saved · Sort (R01e)

private struct RenterChips: View {
    @Binding var filters: RenterFilters
    @Binding var sort: RenterSort?
    @Binding var savedOnly: Bool
    @Binding var showDates: Bool
    @Binding var dates: RentalDates
    let resultCount: Int

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer {
                HStack(spacing: 6) {
                    Menu {
                        filterMenu
                    } label: {
                        chip("Filters", symbol: "line.3.horizontal.decrease", chevron: true)
                    }
                    .menuActionDismissBehavior(.disabled)

                    Button { showDates = true } label: {
                        chip("Dates", symbol: "calendar", chevron: true)
                    }
                    .popover(isPresented: $showDates, arrowEdge: .top) {
                        DatesPopover(dates: $dates, resultCount: resultCount) { showDates = false }
                            .presentationCompactAdaptation(.popover)
                    }

                    Button { savedOnly.toggle() } label: {
                        Label("Saved", systemImage: savedOnly ? "heart.fill" : "heart")
                            .labelStyle(ChipLabelStyle(iconColor: Theme.danger))
                    }
                    .symbolEffect(.bounce, value: savedOnly)

                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(RenterSort.allCases) { Text($0.label).tag(RenterSort?.some($0)) }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        chip("Sort", symbol: "arrow.up.arrow.down", chevron: true)
                    }
                }
                .buttonStyle(.rentbutik)
                .buttonBorderShape(.capsule)
                .controlSize(.mini)
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: savedOnly)
        .sensoryFeedback(.selection, trigger: filters)
    }

    private func chip(_ title: LocalizedStringKey, symbol: String, chevron: Bool) -> some View {
        HStack(spacing: 3) {
            Label(title, systemImage: symbol)
                .labelStyle(ChipLabelStyle(iconColor: Theme.ink))
            if chevron {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    /// Native nested menu — each row shows its current value underneath.
    @ViewBuilder private var filterMenu: some View {
        Menu {
            Picker("Price range", selection: $filters.price) {
                ForEach(RenterFilters.Price.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.inline)
        } label: {
            Text("Price range")
            Text(filters.price.label)
        }

        Menu {
            ForEach(RenterListing.CarType.allCases) { type in
                Toggle(isOn: Binding(
                    get: { filters.types.contains(type) },
                    set: { on in
                        if on { filters.types.insert(type) } else { filters.types.remove(type) }
                    })) { Text(type.label) }
            }
        } label: {
            Text("Car type")
            Text(typeSummary)
        }

        Menu {
            Picker("Transmission", selection: $filters.transmission) {
                Text("Any").tag(Transmission?.none)
                Text(Transmission.automatic.label).tag(Transmission?.some(.automatic))
                Text(Transmission.manual.label).tag(Transmission?.some(.manual))
            }
            .pickerStyle(.inline)
        } label: {
            Text("Transmission")
            Text(filters.transmission.map { String(localized: $0.label) } ?? String(localized: "Any"))
        }

        Menu {
            Picker("Fuel type", selection: $filters.fuel) {
                Text("Any").tag(FuelType?.none)
                ForEach([FuelType.petrol, .diesel, .hybrid, .electric], id: \.self) {
                    Text($0.label).tag(FuelType?.some($0))
                }
            }
            .pickerStyle(.inline)
        } label: {
            Text("Fuel type")
            Text(filters.fuel.map { String(localized: $0.label) } ?? String(localized: "Any"))
        }

        Menu {
            Picker("Seats", selection: $filters.minSeats) {
                Text("Any").tag(Int?.none)
                ForEach([2, 4, 5, 7], id: \.self) { Text("\($0)+ seats").tag(Int?.some($0)) }
            }
            .pickerStyle(.inline)
        } label: {
            Text("Seats")
            Text(filters.minSeats.map { String(localized: "\($0)+ seats") } ?? String(localized: "Any"))
        }

        if filters != RenterFilters() {
            Divider()
            Button("Clear filters", systemImage: "xmark.circle", role: .destructive) {
                filters = RenterFilters()
            }
        }
    }

    private var typeSummary: String {
        if filters.types.isEmpty { return String(localized: "Any") }
        return RenterListing.CarType.allCases
            .filter(filters.types.contains)
            .map(\.name)
            .formatted(.list(type: .and, width: .narrow))
    }
}

/// R01a — native calendar in a popover. A tap sets pick-up, a second tap sets
/// return, and every day between is filled in so the range reads at a glance.
private struct DatesPopover: View {
    @Binding var dates: RentalDates
    let resultCount: Int
    let onShow: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            RangeCalendar(dates: $dates)

            Button(action: onShow) {
                Text("Show \(resultCount) cars · \(dates.rangeLabel)")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
        .padding(16)
        .frame(width: 360)
    }
}

// MARK: Listing card (R01 closed · R01b open)

private struct ListingCard: View {
    let listing: RenterListing
    let isOpen: Bool
    let isSaved: Bool
    let onToggle: () -> Void
    let onSave: () -> Void
    let onMessage: () -> Void
    let onDetails: () -> Void
    let onBook: () -> Void

    var body: some View {
        PhotoListingCard(title: listing.name,
                         subtitle: "\(listing.host) · Baku",
                         photo: listing.photo,
                         leadingPill: "\(money(listing.pricePerDay)) / day",
                         trailingPill: String(localized: listing.instantBook ? "Instant Book" : "By request"),
                         isOpen: isOpen, isSaved: isSaved,
                         onToggle: onToggle, onSave: onSave) {
            ListingDetailsBody(price: money(listing.pricePerDay),
                               priceSuffix: "/ day · \(listing.area), Baku",
                               rating: listing.rating, ratingCount: listing.ratingCount,
                               person: listing.host,
                               role: listing.instantBook ? "Host · Instant Book" : "Host · By request",
                               secondaryTitle: "Details", secondarySymbol: "info.circle",
                               primaryTitle: listing.instantBook ? "Book instantly" : "Request to book",
                               onMessage: onMessage, onSecondary: onDetails, onPrimary: onBook)
        }
    }
}

// MARK: R01h · No cars

private struct RenterEmptyCard: View {
    let title: String
    let detail: LocalizedStringKey
    let showsNotify: Bool
    @Binding var notified: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.inkSoft)
            if showsNotify {
                Button {
                    notified.toggle()
                } label: {
                    Label(notified ? "We’ll notify you" : "Notify me",
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

// MARK: R01f · Map

private struct RenterMap: View {
    let listings: [RenterListing]
    @Binding var saved: Set<String>
    @Binding var openID: String?
    let onOpen: (String) -> Void

    @State private var camera: MapCameraPosition = .region(.init(
        center: .init(latitude: 40.3740, longitude: 49.8470),
        latitudinalMeters: 4200, longitudinalMeters: 4200))
    @State private var selected: String?

    private var current: RenterListing? {
        listings.first { $0.id == selected } ?? listings.first
    }

    var body: some View {
        Map(position: $camera) {
            ForEach(listings) { l in
                Annotation(l.name, coordinate: l.coordinate, anchor: .center) {
                    let isOn = l.id == current?.id
                    Button {
                        withAnimation(Theme.bouncy) { selected = l.id }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "car.fill")
                                .font(.system(size: isOn ? 20 : 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: isOn ? 50 : 36, height: isOn ? 50 : 36)
                                .background(Theme.brandSolid, in: .circle)
                                .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                            Text(money(l.pricePerDay))
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
        // Swipe the cards like EV01; the pin and camera follow.
        .safeAreaInset(edge: .bottom) {
            VehicleCarousel(items: listings, selection: $selected) { l in
                MapListingCard(title: l.name, subtitle: "\(l.host) · \(l.area), Baku",
                               photo: l.photo, price: "\(money(l.pricePerDay)) / day",
                               badge: String(localized: l.instantBook ? "Instant Book" : "By request")) {
                    onOpen(l.id)
                }
            }
            .padding(.bottom, 8)
        }
        .onAppear { if selected == nil { selected = listings.first?.id } }
        .sensoryFeedback(.selection, trigger: selected)
        .onChange(of: selected) { _, id in
            guard let l = listings.first(where: { $0.id == id }) else { return }
            withAnimation(Theme.smooth) {
                camera = .region(.init(center: l.coordinate,
                                       latitudinalMeters: 4200, longitudinalMeters: 4200))
            }
        }
    }
}

// MARK: - R01g · Car details sheet

private struct RenterDetailsSheet: View {
    let listing: RenterListing
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), alignment: .leading),
                           GridItem(.flexible(), alignment: .leading)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                VStack(spacing: 1) {
                    Text(listing.name)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text("Specs & features")
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

            HStack(spacing: 8) {
                SpecChip(symbol: "person.2.fill", text: String(localized: "\(listing.seats) seats"))
                SpecChip(symbol: "gearshift.layout.sixspeed", text: String(localized: listing.transmission.label))
                SpecChip(symbol: "fuelpump.fill", text: String(localized: listing.fuel.label))
            }

            Text("Features")
                .font(Theme.Font.captionSemibold)
                .foregroundStyle(Theme.inkSoft)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(Array(RenterCatalog.features.enumerated()), id: \.offset) { _, feature in
                    Label {
                        Text(feature.label)
                            .font(Theme.Font.subheadlineRegular)
                            .foregroundStyle(Theme.ink)
                    } icon: {
                        Image(systemName: feature.symbol)
                            .foregroundStyle(Theme.goldText)
                            .frame(width: 22)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .fittedSheet()
    }
}

private struct SpecChip: View {
    let symbol: String
    let text: String
    var body: some View {
        Label(text, systemImage: symbol)
            .labelStyle(TightLabelStyle())
            .font(Theme.Font.footnoteRegular)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassChip(tint: nil)
            .symbolRenderingMode(.hierarchical)
            .tint(Theme.goldText)
    }
}

// MARK: - R04 · Checkout

struct RenterCheckoutScreen: View {
    let listing: RenterListing
    let dates: RentalDates
    let store: Store
    let router: AppRouter

    enum Extra: String, CaseIterable, Identifiable {
        case fullTank, chauffeur, decorations
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .fullTank:    "fuelpump.fill"
            case .chauffeur:   "steeringwheel"
            case .decorations: "sparkles"
            }
        }
        var title: LocalizedStringKey {
            switch self {
            case .fullTank:    "Full tank"
            case .chauffeur:   "Chauffeur"
            case .decorations: "Decorations"
            }
        }
        var perDay: Bool { self == .chauffeur }
    }

    enum PayMethod: String, CaseIterable, Identifiable {
        case wallet, visa, applePay
        var id: String { rawValue }
    }

    @Environment(Session.self) private var session
    @State private var extras: Set<Extra> = []
    @State private var method: PayMethod = .wallet
    @State private var showCover = false
    @State private var lowBalance = false
    @State private var paid = 0
    @State private var bookingID = UUID().uuidString
    @State private var submitted = false

    private let deposit: Decimal = 100
    private var rental: Decimal { listing.pricePerDay * Decimal(dates.days) }
    /// 5 % — ₼19 on ₼380, as R04 shows.
    private var serviceFee: Decimal {
        var raw = rental * Decimal(0.05), rounded = Decimal()
        NSDecimalRound(&rounded, &raw, 0, .plain)
        return rounded
    }
    private func price(_ e: Extra) -> Decimal { e.perDay ? 50 * Decimal(dates.days) : 50 }
    private var extrasTotal: Decimal { extras.reduce(0) { $0 + price($1) } }
    private var total: Decimal { rental + serviceFee + deposit + extrasTotal }

    private func methodLabel(_ m: PayMethod) -> String {
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

                Text("Extras")
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 4)
                HStack(spacing: 10) {
                    ForEach(Extra.allCases) { extra in
                        ExtraTile(symbol: extra.symbol, title: extra.title,
                                  price: extra.perDay ? "+\(money(50)) / day" : "+\(money(50))",
                                  isOn: extras.contains(extra)) {
                            withAnimation(Theme.snappy) {
                                if extras.contains(extra) { extras.remove(extra) } else { extras.insert(extra) }
                            }
                        }
                    }
                }

                breakdown
                Text(listing.instantBook ? "Includes a ₼100 refundable deposit. Review cover terms before paying." : "No charge now. You pay only after the host accepts your request.")
                    .font(Theme.Font.subheadlineRegular).foregroundStyle(Theme.inkSoft)

                Text("Meet \(listing.hostFullName) to collect the keys.")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 2)

                HStack {
                    Text("Pay with")
                        .font(Theme.Font.subheadlineRegular)
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Picker("Pay with", selection: $method) {
                        ForEach(PayMethod.allCases) { Text(methodLabel($0)).tag($0) }
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
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: pay) {
                Text(listing.instantBook ? "Confirm & pay \(money(total))" : "Request booking · \(money(total))")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("renter.confirm")
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 8)
        }
        .sensoryFeedback(.selection, trigger: extras)
        .sensoryFeedback(.selection, trigger: method)
        .sensoryFeedback(.success, trigger: paid)
        .alert("Basic cover", isPresented: $showCover) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(money(deposit)) deposit, refunded. Cover terms must be confirmed with \(listing.host) before payment")
        }
        .alert("Not enough in Wallet", isPresented: $lowBalance) {
            Button("Pay with Visa •••• 4242") { method = .visa; pay() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Top up your Wallet or pay with a card.")
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(listing.name)
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                Text(verbatim: "\(dates.rangeLabel) · \(String(localized: "\(dates.days) day"))")
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Text("Host")
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(listing.hostFullName)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.ink)
            }
            .font(Theme.Font.subheadlineRegular)

            Button { showCover = true } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(Theme.brandSolid)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Basic cover · \(money(deposit)) deposit, refunded")
                            .font(Theme.Font.subheadlineRegular)
                            .foregroundStyle(Theme.ink)
                        Text("Cover terms must be confirmed with \(listing.host) before payment")
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

    private var breakdown: some View {
        VStack(spacing: 12) {
            PriceLine(label: "Rental · \(dates.days) day", value: rental)
            PriceLine(label: "Service fee", value: serviceFee)
            PriceLine(label: "Deposit", value: deposit)
            ForEach(Extra.allCases.filter(extras.contains)) { extra in
                PriceLine(label: extra.title, value: price(extra))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            Divider().overlay(Theme.hairline)
            PriceLine(label: "Total", value: total)
        }
        .padding(16)
        .glassCard(Theme.Radius.card)
    }

    private func pay() {
        guard !submitted else { return }
        if listing.instantBook, method == .wallet, store.walletBalance < total {
            lowBalance = true
            return
        }
        router.requireVerified(session, holding: listing.name) {
            guard !submitted else { return }
            guard !listing.instantBook || store.charge(total, label: listing.name, symbol: "car.side.fill",
                               walletFirst: method == .wallet, idempotencyKey: bookingID) != .declined else {
                lowBalance = true
                return
            }
            submitted = true
            paid += 1
            let threadID = "host-" + listing.id
            if !store.threads.contains(where: { $0.id == threadID }) {
                store.threads.append(MessageThread(id: threadID, counterpartName: listing.hostFullName,
                                                  subtitle: "Host", messages: [], isUnread: false, vehicle: listing.name))
            }
            store.addBooking(TripRecord(
                id: bookingID, kind: .car, title: listing.name,
                status: listing.instantBook ? "Booked" : "Waiting for host",
                tone: listing.instantBook ? .success : .pending,
                amount: .money(total),
                rows: [.init(label: String(localized: "When"), value: "\(dates.rangeLabel) · \(dates.days) day · \(listing.area)"),
                       .init(label: String(localized: "Host"), value: listing.hostFullName),
                       .init(label: listing.instantBook ? "Paid" : "Estimated total", value: "\(money(total)) · deposit \(money(deposit)) incl.")],
                note: listing.instantBook ? "Refunds return to the original payment method." : "No charge now. Host acceptance and payment confirmation are required.",
                actions: [.message, .cancelBooking], paymentID: listing.instantBook ? bookingID : nil, threadID: threadID))
            store.bookingFollowUp(title: listing.instantBook ? "Your booking is confirmed" : "Request sent to host",
                                  detail: "\(listing.name) · \(dates.rangeLabel)", hostThreadID: threadID)
            router.popToRoot(router.tab)
            router.tab = .trips
        }
    }
}

private struct PriceLine: View {
    let label: LocalizedStringKey
    let value: Decimal
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(money(value))
                .fontWeight(.semibold)
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
        }
        .font(Theme.Font.subheadlineRegular)
    }
}

private struct ExtraTile: View {
    let symbol: String
    let title: LocalizedStringKey
    let price: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : symbol)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.goldText)
                    .contentTransition(.symbolEffect(.replace))
                Text(title)
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(price)
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(isOn ? .regular.tint(Theme.brandTint).interactive() : .regular.interactive(),
                         in: .rect(cornerRadius: Theme.Radius.group))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - R05 · Rental complete

struct RentalCompleteScreen: View {
    let router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Theme.Font.title3)
                        .foregroundStyle(Theme.brandSolid)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your return is recorded")
                            .font(Theme.Font.title2)
                            .foregroundStyle(Theme.ink)
                        Text(verbatim: "Mercedes-AMG GT · 22–23 Sep")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    VStack(spacing: 12) {
                        CompleteLine(label: "Rental", value: String(localized: "Completed"))
                        CompleteLine(label: "Total paid", value: money(499))
                        CompleteLine(label: "Deposit", value: String(localized: "\(money(100)) · In review"))
                    }
                    Text("Any deposit update will appear in Wallet and your trip record.")
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(Theme.Radius.card)

                RentbutikPrimaryButton("Done") { dismiss() }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, 8)
        }
        .background(Theme.background)
        .navigationTitle("Rental complete")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CompleteLine: View {
    let label: LocalizedStringKey
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(Theme.ink)
        }
        .font(Theme.Font.subheadlineRegular)
    }
}

// MARK: - Previews

#Preview("R01 · Cars near you") {
    NavigationStack {
        RenterListScreen(store: .seeded(), router: AppRouter())
    }
    .environment(Session())
}

#Preview("R01b · Car open") {
    NavigationStack {
        RenterListScreen(store: .seeded(), router: AppRouter(), initialOpenID: "amg")
    }
    .environment(Session())
}

#Preview("R04 · Checkout") {
    NavigationStack {
        RenterCheckoutScreen(listing: RenterCatalog.listings[0], dates: .standard,
                             store: .seeded(), router: AppRouter())
    }
    .environment(Session())
}

#Preview("R05 · Rental complete") {
    NavigationStack { RentalCompleteScreen(router: AppRouter()) }
}

#Preview("R01g · Details") {
    Color.clear.sheet(isPresented: .constant(true)) {
        RenterDetailsSheet(listing: RenterCatalog.listings[0])
    }
}

