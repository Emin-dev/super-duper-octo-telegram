import SwiftUI

// MARK: - Data

/// One row on T01. Content verbatim from Design-flow `26:49` / `321:3475`.
struct TripRecord: Identifiable, Equatable, Codable {
    enum Kind: String, Equatable, Codable { case car, transfer, golf, electric }
    enum Amount: Equatable, Codable { case money(Decimal), refunded(Decimal), noCharge }
    enum Action: String, Equatable, Codable {
        case message, directions, receipt, findAnotherCar, start
        case cancelBooking, cancelRequest, cancel
        var isDestructive: Bool {
            switch self {
            case .cancelBooking, .cancelRequest, .cancel: true
            default: false
            }
        }
        /// T01b: most actions are Button / Small on surface/fill; "Find
        /// another car" and "Start" sit on surface/control.
        var onControl: Bool { self == .findAnotherCar || self == .start }
        var label: LocalizedStringKey {
            switch self {
            case .message:        "Message"
            case .directions:     "Directions"
            case .receipt:        "Receipt"
            case .findAnotherCar: "Find another car"
            case .start:          "Start"
            case .cancelBooking:  "Cancel booking"
            case .cancelRequest:  "Cancel request"
            case .cancel:         "Cancel"
            }
        }
    }
    struct Row: Equatable, Identifiable, Codable {
        var id: String { label }
        let label: String
        let value: String
        var emphasised = false
    }

    let id: String
    let kind: Kind
    let title: String
    var status: String
    var tone: StatusChip.Tone
    var amount: Amount
    let rows: [Row]
    var note: String?
    var actions: [Action] = []
    /// History only — the trailing rebook button.
    var rebook = false
    var rated: Bool? = nil
    var paymentID: String? = nil
    var threadID: String = "thr-support"
    var isCancelled = false

    static func == (l: TripRecord, r: TripRecord) -> Bool { l.id == r.id }

    var symbol: String {
        switch kind {
        case .car:      "car.side.fill"
        case .transfer: "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .golf:     "steeringwheel"
        case .electric: "bolt.car.fill"
        }
    }
}

enum TripsCatalog {
    static let upcoming: [TripRecord] = [
        .init(id: "up-gt3", kind: .car, title: "Porsche 911 GT3 RS",
              status: "Verifying documents", tone: .pending, amount: .money(783),
              rows: [.init(label: "When", value: "29–30 Sep · Nizami St.")],
              note: "Held for you for 30 minutes while we check your documents.",
              actions: [.cancelBooking]),
        .init(id: "up-mustang", kind: .car, title: "Ford Mustang GT",
              status: "Booked", tone: .success, amount: .money(793),
              rows: [.init(label: "When", value: "15–18 Oct · 3 days · Nizami St."),
                     .init(label: "Pickup", value: "15 Oct, 10:00 · Nizami St."),
                     .init(label: "Host", value: "Nigar Aliyeva"),
                     .init(label: "Paid", value: "₼793 · deposit ₼100 incl.")],
              actions: [.message, .directions, .cancelBooking]),
        .init(id: "up-mclaren", kind: .car, title: "McLaren 650S Spider",
              status: "Waiting for host", tone: .pending, amount: .money(1570),
              rows: [.init(label: "When", value: "02–04 Oct · 2 days · Yasamal")],
              note: "Leyla usually replies within 24 h. You’re charged only if she accepts.",
              actions: [.message, .cancelRequest]),
        .init(id: "up-sf90", kind: .car, title: "Ferrari SF90",
              status: "Declined", tone: .danger, amount: .noCharge,
              rows: [.init(label: "When", value: "05 Oct · Port Baku")],
              note: "Rashad can’t host on these dates. Nothing was charged.",
              actions: [.findAnotherCar]),
        .init(id: "up-transfer", kind: .transfer, title: "Baku → Airport",
              status: "Waiting for driver", tone: .pending, amount: .money(16),
              rows: [.init(label: "When", value: "Today 18:00 · 1 seat · Hasan")],
              note: "Hasan confirms within 30 min. Free cancellation until he accepts.",
              actions: [.cancelRequest]),
        .init(id: "up-golf", kind: .golf, title: "Golf cart 4",
              status: "Reserved", tone: .pending, amount: .money(138),
              rows: [.init(label: "When", value: "Today · 2 hours · Sea Breeze")],
              note: "Show booking G042 at the Sea Breeze Golf desk.",
              actions: [.cancel, .start]),
    ]

    static let history: [TripRecord] = [
        .init(id: "h-ev", kind: .electric, title: "Rentbutik EV 6",
              status: "Completed", tone: .neutral, amount: .money(16),
              rows: [.init(label: "When", value: "18 Sep"),
                     .init(label: "Duration", value: "60 min"),
                     .init(label: "Distance", value: "12.4 km"),
                     .init(label: "Route", value: "Sahil → 28 May street"),
                     .init(label: "Ride · hour tariff", value: "₼15.00"),
                     .init(label: "Unlock", value: "₼1.00"),
                     .init(label: "Total paid", value: "₼16.00", emphasised: true)],
              actions: [.receipt], rebook: true, rated: false),
        .init(id: "h-golf", kind: .golf, title: "Golf cart 4",
              status: "Completed", tone: .neutral, amount: .money(32),
              rows: [.init(label: "When", value: "14 Sep · Sea Breeze"),
                     .init(label: "Duration", value: "2 hours"),
                     .init(label: "Collected at", value: "Sea Breeze Golf desk"),
                     .init(label: "Ride · 2 hours", value: "₼40.00"),
                     .init(label: "Discount", value: "−₼8.00"),
                     .init(label: "Total paid", value: "₼32.00", emphasised: true)],
              actions: [.receipt], rebook: true, rated: true),
        .init(id: "h-qabala", kind: .transfer, title: "Baku → Qabala · day tour",
              status: "Completed", tone: .neutral, amount: .money(60),
              rows: [.init(label: "When", value: "10 Sep · day tour")],
              actions: [.receipt], rebook: true, rated: false),
        .init(id: "h-carrera", kind: .car, title: "Porsche 911 Carrera",
              status: "Cancelled", tone: .danger, amount: .refunded(460),
              rows: [.init(label: "Dates", value: "08 Sep · 1 day"),
                     .init(label: "Cancelled", value: "06 Sep, by you"),
                     .init(label: "Refund", value: "₼460 to Visa •••• 4242", emphasised: true)],
              rebook: true),
        .init(id: "h-amg", kind: .car, title: "Mercedes-AMG GT",
              status: "Completed", tone: .neutral, amount: .money(499),
              rows: [.init(label: "When", value: "01 Sep · 1 day · Sahil"),
                     .init(label: "Pickup & return", value: "Sahil, Baku"),
                     .init(label: "Host", value: "Hasan Nabiyev"),
                     .init(label: "Rental · 1 day", value: "₼380"),
                     .init(label: "Total paid", value: "₼499", emphasised: true)],
              actions: [.receipt], rebook: true, rated: false),
    ]
}

// MARK: - T01 · Trips

/// Tab root. Current trip card, then Upcoming and Trip history as accordion
/// rows — opening a row reveals its details IN PLACE (T01b). Nothing pushes.
struct TripsScreen: View {
    let store: Store
    let router: AppRouter
    @State private var expanded: Set<String> = []
    @State private var showAllUpcoming = false
    @State private var showAllHistory = false
    @State private var confirmCancel: TripRecord?
    @State private var receipt: TripRecord?
    @State private var returnTrip: Trip?

    private var active: [Trip] { store.trips.filter { $0.status == .ongoing || $0.status == .paymentPending } }
    private var upcoming: [TripRecord] { store.bookedRecords.filter { !$0.isCancelled } }
    private var history: [TripRecord] {
        store.trips.filter { $0.status == .completed }.map(record) + store.bookedRecords.filter(\.isCancelled)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trips").font(Theme.Font.largeTitle).foregroundStyle(Theme.ink)
                TripsSectionTitle("Current trip")
                if active.isEmpty {
                    empty("No active trip", detail: "Your ride and return details will appear here.")
                }
                ForEach(active) { trip in
                    ActiveTripCard(trip: trip, store: store,
                                   onOpen: { open(trip) },
                                   onSupport: { router.push(.thread(threadID: "thr-support")) })
                }
                TripsSectionTitle("Upcoming").padding(.top, 8)
                if let hold = store.hold {
                    HoldRow(hold: hold, onCancel: { store.releaseHold() })
                }
                if upcoming.isEmpty { empty("Nothing booked yet", detail: "Explore cars, transfers and Golf from Home.") }
                TripRows(records: showAllUpcoming ? upcoming : Array(upcoming.prefix(3)), expanded: $expanded, onAction: handle)
                ShowAllButton(count: upcoming.count, isShowingAll: $showAllUpcoming)
                TripsSectionTitle("Trip history").padding(.top, 8)
                if history.isEmpty { empty("Your trips, in one place", detail: "Completed trips and cancellations appear here with their actual amounts.") }
                TripRows(records: showAllHistory ? history : Array(history.prefix(3)), expanded: $expanded, onAction: handle)
                ShowAllButton(count: history.count, isShowingAll: $showAllHistory)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.gap)
            .padding(.bottom, Theme.Space.tabBarClearance)
        }
        .background(Theme.background)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sheet(item: $receipt) { TripReceiptSheet(record: $0) }
        .fullScreenCover(item: $returnTrip) { trip in
            CaptureStagesView(heading: "Return cart", stages: ReturnPhotoStages.all,
                              hint: "Return to the Sea Breeze Golf desk. The deposit is returned in this demo after all photos.",
                              onCancel: { returnTrip = nil },
                              onDone: {
                                  returnTrip = nil
                                  if case .paid = store.endTrip(id: trip.id),
                                     let done = store.trips.first(where: { $0.id == trip.id }) { receipt = record(done) }
                              })
        }
        .alert("Cancel this booking?", item: $confirmCancel) { booking in
            Button("Cancel booking", role: .destructive) { store.cancelBooking(booking.id) }
            Button("Keep booking", role: .cancel) {}
        } message: { booking in
            Text(booking.paymentID == nil ? "No payment was taken for this request." : "The demo refund returns to the original wallet and card payment split.")
        }
    }

    private func empty(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Theme.Font.headline).foregroundStyle(Theme.ink)
            Text(detail).font(Theme.Font.body).foregroundStyle(Theme.inkSoft)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20).glassCard()
    }

    private func open(_ trip: Trip) {
        if trip.vehicleKind == .electric { router.push(.evActiveTrip(vehicleID: trip.vehicleID)) }
        else { returnTrip = trip }
    }

    private func record(_ trip: Trip) -> TripRecord {
        TripRecord(id: trip.id, kind: trip.vehicleKind == .electric ? .electric : .golf,
                   title: trip.vehicleName, status: "Completed", tone: .neutral, amount: .money(trip.total),
                   rows: [.init(label: "Started", value: trip.startDate.formatted(date: .abbreviated, time: .shortened)),
                          .init(label: "Ended", value: trip.endDate.formatted(date: .abbreviated, time: .shortened)),
                          .init(label: "Duration", value: "\(max(1, Int(ceil(trip.endDate.timeIntervalSince(trip.startDate) / 60)))) min"),
                          .init(label: "Return", value: trip.returnPlace)],
                   note: trip.depositPaymentID == nil ? "Demo payment receipt" : "Demo deposit returned to its original payment methods.",
                   actions: [.receipt])
    }

    private func handle(_ action: TripRecord.Action, _ record: TripRecord) {
        switch action {
        case .cancelBooking, .cancelRequest, .cancel: confirmCancel = record
        case .message: router.push(.thread(threadID: record.threadID))
        case .findAnotherCar: router.push(.renterList)
        case .receipt: receipt = record
        case .directions, .start: router.push(.thread(threadID: record.threadID))
        }
    }
}

private struct TripsSectionTitle: View {
    let title: LocalizedStringKey
    init(_ title: LocalizedStringKey) { self.title = title }

    var body: some View {
        Text(title)
            .font(Theme.Font.title3)
            .foregroundStyle(Theme.ink)
            .padding(.bottom, 12)
    }
}

// MARK: - Current trip

/// Photo card, radius 30, that keeps ONE size open or closed — the same
/// rule as Renter and Transfer. Closed, the photo fills the card; opening
/// crops it to the top 150 pt and reveals the details it was covering.
private struct CurrentTripCard: View {
    let isExpanded: Bool
    let onToggle: () -> Void
    var onSupport: () -> Void = {}

    private let openPhotoHeight: CGFloat = 150
    @State private var detailsHeight: CGFloat = 250
    private var cardHeight: CGFloat { openPhotoHeight + detailsHeight }

    var body: some View {
        ZStack(alignment: .top) {
            details
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { detailsHeight = $0 }
                .padding(.top, openPhotoHeight)
                .opacity(isExpanded ? 1 : 0)
                .offset(y: isExpanded ? 0 : 12)
                .allowsHitTesting(isExpanded)
                .accessibilityHidden(!isExpanded)

            Button(action: onToggle) {
                Color.clear
                    .frame(height: isExpanded ? openPhotoHeight : cardHeight)
                    .frame(maxWidth: .infinity)
                    // Drawn at full card height and cropped — never rescaled.
                    .background(alignment: .center) {
                        PhotoFill(photoName: "mercedesAMGGT", symbol: "car.fill")
                            .frame(height: cardHeight)
                    }
                    .clipped()
                    .overlay {
                        LinearGradient(colors: [.black.opacity(0.55), .clear, .black.opacity(0.35)],
                                       startPoint: .top, endPoint: .bottom)
                    }
                    .overlay(alignment: .topLeading) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: "Mercedes-AMG GT")
                                    .font(Theme.Font.title3)
                                Text(verbatim: "22 Sep 10:00 → 23 Sep 10:00")
                                    .font(Theme.Font.subheadlineRegular)
                                Text(verbatim: "Sahil, Baku")
                                    .font(Theme.Font.subheadlineSemibold)
                            }
                            .foregroundStyle(Theme.onBrand)
                            Spacer(minLength: 8)
                            StatusChip("Ongoing", tone: .onPhoto)
                        }
                        .padding(16)
                    }
                    .overlay(alignment: .bottom) {
                        HStack {
                            PhotoPill(text: "Hasan Nabiyev")
                            Spacer()
                            PhotoPill(text: Decimal(499).formatted(
                                .currency(code: Currency.code).precision(.fractionLength(0))))
                        }
                        .padding(14)
                        .opacity(isExpanded ? 0 : 1)
                    }
            }
            .buttonStyle(PressScale(haptic: .open))
            .accessibilityHint(isExpanded ? "Hides trip details" : "Shows trip details")
        }
        .frame(height: cardHeight, alignment: .top)
        .background(Theme.card)
        .clipShape(.rect(cornerRadius: Theme.Radius.card))
        .shadow(color: Theme.Shadow.card.color, radius: Theme.Shadow.card.radius, y: Theme.Shadow.card.y)
        .animation(Theme.expand, value: isExpanded)
    }

    private var details: some View {
        VStack(spacing: 14) {
            DetailLine(symbol: "mappin.and.ellipse", label: "Pickup & return", value: "Sahil, Baku")
            DetailLine(symbol: "person.fill", label: "Host", value: "Hasan Nabiyev")
            VStack(alignment: .leading, spacing: 2) {
                DetailLine(symbol: "creditcard", label: "Paid", value: "₼499")
                Text(verbatim: "Rental ₼380 · Service fee ₼19")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.leading, 26)
            }
            DetailLine(symbol: "shield", label: "Deposit included", value: "₼100")
            RentbutikPrimaryButton("Support", action: onSupport)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}

/// Footnote / Semibold on tint/surface-card-92.
private struct PhotoPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.card.opacity(0.92), in: .capsule)
    }
}

private struct DetailLine: View {
    let symbol: String
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(Theme.Font.subheadlineRegular)
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 16)
            Text(label)
                .font(Theme.Font.subheadlineRegular)
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.ink)
        }
    }
}

// MARK: - Hold row

/// N2: the free 15-minute hold, "Reserved · 12:34 left", while it runs.
private struct HoldRow: View {
    let hold: Store.Hold
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RentbutikBadge(symbol: hold.kind == .golfCart ? "steeringwheel" : "bolt.car.fill",
                           size: .notification)
            VStack(alignment: .leading, spacing: 4) {
                Text(hold.vehicleName)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("Reserved ·")
                    Text(timerInterval: Date.now...max(hold.until, .now), countsDown: true)
                        .monospacedDigit()
                    Text("left")
                }
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.goldText)
            }
            Spacer(minLength: 8)
            RentbutikSmallButton("Cancel", destructive: true, action: onCancel)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(Theme.Radius.card)
    }
}

// MARK: - Accordion rows

private struct TripRows: View {
    let records: [TripRecord]
    @Binding var expanded: Set<String>
    let onAction: (TripRecord.Action, TripRecord) -> Void

    var body: some View {
        VStack(spacing: Theme.Space.gap) {
            ForEach(records) { record in
                TripRowCard(record: record,
                            isExpanded: expanded.contains(record.id),
                            onToggle: {
                                withAnimation(Theme.expand) {
                                    if expanded.contains(record.id) { expanded.remove(record.id) }
                                    else { expanded.insert(record.id) }
                                }
                            },
                            onAction: { onAction($0, record) })
                // Rows revealed by "Show all" slide in under the last one.
                .transition(.opacity.combined(with: .offset(y: -12)))
            }
        }
    }
}

/// Record card — 366 wide, radius 30, 14 pt padding. The header is 76 tall;
/// opening it grows the SAME card with details, note and small actions.
private struct TripRowCard: View {
    let record: TripRecord
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAction: (TripRecord.Action) -> Void

    @State private var rating = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    RentbutikBadge(symbol: record.symbol, size: .notification)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.title)
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            StatusChip(LocalizedStringKey(record.status), tone: record.tone)
                            AmountText(amount: record.amount)
                        }
                    }
                    Spacer(minLength: 8)
                    if record.rebook {
                        Image(systemName: "arrow.clockwise")
                            .font(Theme.Font.subheadlineSemibold)
                            .foregroundStyle(Theme.ink)
                            .frame(width: 36, height: 36)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .accessibilityLabel("Book again")
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(PressScale(haptic: .open))

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().overlay(Theme.hairline)
                    ForEach(record.rows) { row in
                        HStack(alignment: .firstTextBaseline) {
                            Text(row.label)
                                .font(row.emphasised ? Theme.Font.subheadlineSemibold : Theme.Font.subheadlineRegular)
                                .foregroundStyle(row.emphasised ? Theme.ink : Theme.inkSoft)
                            Spacer(minLength: 8)
                            Text(row.value)
                                .font(row.emphasised ? Theme.Font.subheadlineSemibold : Theme.Font.subheadlineRegular)
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    if let note = record.note {
                        Text(note)
                            .font(Theme.Font.footnoteRegular)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    if !record.actions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(record.actions, id: \.self) { action in
                                RentbutikSmallButton(action.label,
                                                     destructive: action.isDestructive,
                                                     onBackground: action.onControl) {
                                    onAction(action)
                                }
                            }
                        }
                    }
                    if let rated = record.rated {
                        HStack {
                            Text(rated ? "You rated this trip" : "Rate this trip")
                                .font(Theme.Font.subheadlineRegular)
                                .foregroundStyle(Theme.inkSoft)
                            Spacer()
                            StarRating(value: rated ? 5 : rating) { rating = $0 }
                        }
                    }
                }
                .padding(.top, 12)
                .transition(.expandContent)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(Theme.Radius.card)
        .geometryGroup()
    }
}

private struct AmountText: View {
    let amount: TripRecord.Amount

    private var money: Decimal.FormatStyle.Currency {
        .currency(code: Currency.code).precision(.fractionLength(0))
    }

    var body: some View {
        switch amount {
        case .money(let v):
            Text(v, format: money)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
        case .refunded(let v):
            Text("\(v, format: money) refunded")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
        case .noCharge:
            Text("No charge")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

private struct StarRating: View {
    let value: Int
    let onRate: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { n in
                Button { onRate(n) } label: {
                    Image(systemName: n <= value ? "star.fill" : "star")
                        .font(Theme.Font.headline)
                        .foregroundStyle(n <= value ? Theme.goldText : Theme.inkSoft)
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: n <= value)
                }
                .buttonStyle(PressScale(haptic: .tick))
                .accessibilityLabel("\(n) stars")
            }
        }
    }
}

/// "Show all 6 ⌄" — Subheadline / Semibold, text/gold, centred.
private struct ShowAllButton: View {
    let count: Int
    @Binding var isShowingAll: Bool

    var body: some View {
        if count > 3 {
            Button {
                withAnimation(Theme.expand) { isShowingAll.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(isShowingAll ? "Show less" : "Show all \(count)")
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isShowingAll ? 180 : 0))
                }
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.goldText)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
            }
            .buttonStyle(PressScale(haptic: .click))
        }
    }
}

#Preview("T01 · Trips") {
    NavigationStack {
        TripsScreen(store: .seeded(), router: AppRouter())
    }
}

