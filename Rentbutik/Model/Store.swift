import Foundation

/// In-memory data store, shaped like the eventual API so screens are wired
/// rather than static.
///
/// Every figure is real content taken from `SCREENS.md` and `BUILD-LOG.md`,
/// not placeholder text. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` makes this
/// main-actor isolated, matching how views read it.
@Observable
final class Store {
    var vehicles: [Vehicle] = []
    var trips: [Trip] = [] {
        didSet { recomputeActiveTrip() }
    }

    /// Cached rather than computed: a computed property would read the whole
    /// `trips` array, so every Home body pass would depend on all of it.
    private(set) var activeTrip: Trip?

    private func recomputeActiveTrip() {
        activeTrip = trips.first { $0.status == .ongoing }
    }

    /// Appends a message to a thread and marks it read.
    func send(_ text: String, in threadID: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = threads.firstIndex(where: { $0.id == threadID })
        else { return }
        threads[index].messages.append(
            Message(id: UUID().uuidString, text: trimmed,
                    isFromMe: true, sentAt: .now))
        threads[index].isUnread = false
        answer(in: threadID)
    }

    /// Sends a photo, video or document, with an optional caption.
    func send(_ attachment: MessageAttachment, caption: String = "", in threadID: String) {
        guard let index = threads.firstIndex(where: { $0.id == threadID }) else { return }
        threads[index].messages.append(
            Message(id: UUID().uuidString, text: caption.trimmingCharacters(in: .whitespacesAndNewlines),
                    isFromMe: true, sentAt: .now, attachment: attachment))
        answer(in: threadID)
    }

    // MARK: Live demo — on-device replies, typing and follow-ups

    /// Plays every host and Support with the on-device model.
    let agent = ChatAgent()
    /// Threads whose counterpart is "typing…".
    var typingThreadIDs: Set<String> = []
    /// Model-suggested quick replies, per thread.
    var suggestions: [String: [String]] = [:]
    /// The thread on screen — replies there don't raise badges.
    var viewingThreadID: String?

    /// Replies still being written, per thread — typing stays on until all land.
    private var pendingReplies: [String: Int] = [:]

    /// The counterpart reads, types for a believable moment, then replies.
    func answer(in threadID: String) {
        guard AppConfiguration.isDemo else { return }
        pendingReplies[threadID, default: 0] += 1
        Task {
            defer {
                pendingReplies[threadID, default: 1] -= 1
                if pendingReplies[threadID] == 0 { typingThreadIDs.remove(threadID) }
            }
            try? await Task.sleep(for: .seconds(Double.random(in: 0.6...1.2)))   // read receipt beat
            guard let thread = threads.first(where: { $0.id == threadID }) else { return }
            typingThreadIDs.insert(threadID)
            let started = Date.now
            let reply = await agent.reply(in: thread)
            // Typing time grows with the reply, like a person's would.
            let typing = min(max(Double(reply.count) / 28, 1.4), 4.5)
            let remaining = typing - Date.now.timeIntervalSince(started)
            if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
            deliver(reply, in: threadID)
            await refreshSuggestions(for: threadID)
        }
    }

    /// Appends an incoming message; badges and notifies unless it's on screen.
    func deliver(_ text: String, in threadID: String) {
        guard let index = threads.firstIndex(where: { $0.id == threadID }) else { return }
        threads[index].messages.append(
            Message(id: UUID().uuidString, text: text, isFromMe: false, sentAt: .now))
        guard viewingThreadID != threadID else { return }
        threads[index].isUnread = true
        threads[index].unreadCount += 1
        let name = threads[index].counterpartName.split(separator: " ").first.map(String.init) ?? ""
        notifications.insert(AppNotification(id: UUID().uuidString, symbol: "message.fill",
                                             title: String(localized: "\(name) sent you a message"),
                                             detail: "“\(text)”", isUnread: true, date: .now),
                             at: 0)
        LocalNotifier.shared.post(title: threads[index].counterpartName, body: text, thread: threadID)
    }

    func refreshSuggestions(for threadID: String) async {
        guard let thread = threads.first(where: { $0.id == threadID }) else { return }
        suggestions[threadID] = await agent.suggestions(for: thread)
    }

    private var liveDemoStarted = false

    /// Nothing is unread at launch. About 30 seconds in, Hasan types and
    /// sends a message. From ~3–4 minutes on, the world keeps moving: new
    /// people start chats and small events arrive every few minutes.
    func startLiveDemo() {
        guard AppConfiguration.isDemo else { return }
        guard !liveDemoStarted else { return }
        liveDemoStarted = true
        Task {
            guard (try? await Task.sleep(for: .seconds(30))) != nil else { return }
            typingThreadIDs.insert("thr-hasan")
            try? await Task.sleep(for: .seconds(2.5))
            typingThreadIDs.remove("thr-hasan")
            deliver(String(localized: "The Mercedes is ready for your trip."), in: "thr-hasan")
            await refreshSuggestions(for: "thr-hasan")

            try? await Task.sleep(for: .seconds(Double.random(in: 180...240)))
            while !Task.isCancelled {
                await nextDemoEvent()
                try? await Task.sleep(for: .seconds(Double.random(in: 150...270)))
            }
        }
    }

    // MARK: Demo world — people and events that arrive over time

    struct DemoPerson {
        let threadID: String
        let name: String
        let role: String
        let vehicle: String
        let presence: String
        let opener: String
    }

    static let demoPeople: [DemoPerson] = [
        .init(threadID: "thr-nigar", name: "Nigar Mammadova", role: "Host", vehicle: "Ford Mustang GT",
              presence: "Host · usually replies in 15 min",
              opener: "Hi! I saw you looking at the Mustang — it’s free this weekend if you’d like it."),
        .init(threadID: "thr-golf", name: "Sea Breeze Golf desk", role: "Golf desk", vehicle: "Golf cart 8",
              presence: "Golf desk · open 08:00–22:00",
              opener: "Good afternoon! Golf cart 8 is charged and waiting at the desk."),
        .init(threadID: "thr-rashad", name: "Rashad Karimov", role: "Driver", vehicle: "Porsche 911 GT3 RS",
              presence: "Driver · usually replies in 5 min",
              opener: "Hi, I’m driving Baku → Sheki on Sunday at 08:00. One seat left if you’re interested."),
        .init(threadID: "thr-leyla", name: "Leyla Aliyeva", role: "Host", vehicle: "McLaren 650S Spider",
              presence: "Host · usually replies in 20 min",
              opener: "Hello! The McLaren just came back from service — happy to answer any questions."),
        .init(threadID: "thr-kamran", name: "Kamran Huseynov", role: "Host", vehicle: "Ferrari SF90 Stradale",
              presence: "Host · usually replies in 10 min",
              opener: "Welcome to Rentbutik! The SF90 is available from tomorrow in White City."),
    ]

    private var demoStep = 0

    /// Alternates new conversations with small ambient events.
    func nextDemoEvent() async {
        defer { demoStep += 1 }
        let next = Store.demoPeople.first { p in !threads.contains { $0.id == p.threadID } }
        if demoStep.isMultiple(of: 2), let person = next {
            await startConversation(with: person)
            return
        }
        switch demoStep % 5 {
        case 1:
            credit(2, label: String(localized: "Cashback"), symbol: "gift.fill")
            notify(symbol: "gift.fill", title: String(localized: "₼2 cashback added"),
                   detail: String(localized: "For your last ride · now in Wallet"))
        case 3:
            notify(symbol: "bolt.car.fill", title: String(localized: "Rentbutik EV 5 is 2 min away"),
                   detail: String(localized: "95 % charged · on Nizami St."))
        case 4:
            notify(symbol: "sparkles", title: String(localized: "New car near you"),
                   detail: String(localized: "Ferrari SF90 Stradale · White City · ₼1,100 / day"))
        default:
            // Someone already in a chat follows up on their own.
            if let thread = threads.filter({ !$0.isPinned }).randomElement() {
                typingThreadIDs.insert(thread.id)
                let text = await agent.followUp(in: thread)
                try? await Task.sleep(for: .seconds(2))
                typingThreadIDs.remove(thread.id)
                deliver(text, in: thread.id)
            }
        }
    }

    /// A new person writes first — the thread appears, they type, they send.
    func startConversation(with person: DemoPerson) async {
        let thread = ensureThread(for: person)
        typingThreadIDs.insert(person.threadID)
        let opener = await agent.opener(for: thread, fallback: person.opener)
        try? await Task.sleep(for: .seconds(2.2))
        typingThreadIDs.remove(person.threadID)
        deliver(opener, in: person.threadID)
        await refreshSuggestions(for: person.threadID)
    }

    /// The person's thread, created (empty) if it doesn't exist yet.
    @discardableResult
    func ensureThread(for person: DemoPerson) -> MessageThread {
        if let existing = threads.first(where: { $0.id == person.threadID }) { return existing }
        let thread = MessageThread(id: person.threadID, counterpartName: person.name,
                                   subtitle: person.role, messages: [], isUnread: false,
                                   vehicle: person.vehicle, presence: person.presence)
        threads.insert(thread, at: min(1, threads.count))
        return thread
    }

    private func notify(symbol: String, title: String, detail: String) {
        notifications.insert(AppNotification(id: UUID().uuidString, symbol: symbol, title: title,
                                             detail: detail, isUnread: true, date: .now), at: 0)
        LocalNotifier.shared.post(title: title, body: detail, thread: "rentbutik")
    }

    /// Bookings made this session, newest first — Trips shows them in Upcoming.
    var bookedRecords: [TripRecord] = []

    func addBooking(_ record: TripRecord) {
        guard !bookedRecords.contains(where: { $0.id == record.id }) else { return }
        bookedRecords.insert(record, at: 0)
        saveSnapshot()
    }

    /// After a booking: a confirmation notification, then the host writes.
    func bookingFollowUp(title: String, detail: String, hostThreadID: String = "thr-hasan") {
        Task {
            try? await Task.sleep(for: .seconds(2))
            notifications.insert(AppNotification(id: UUID().uuidString, symbol: "checkmark.seal.fill",
                                                 title: title, detail: detail,
                                                 isUnread: true, date: .now), at: 0)
            try? await Task.sleep(for: .seconds(4))
            typingThreadIDs.insert(hostThreadID)
            try? await Task.sleep(for: .seconds(2.5))
            typingThreadIDs.remove(hostThreadID)
            deliver(String(localized: "Thanks for booking! I’ll have everything ready — message me if you need anything before pickup."),
                    in: hostThreadID)
        }
    }

    /// Opening a thread reads it — clears the row badge and the Chats tab badge.
    func markNotificationRead(_ id: String) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isUnread = false
    }

    func markRead(_ threadID: String) {
        guard let index = threads.firstIndex(where: { $0.id == threadID }) else { return }
        threads[index].isUnread = false
        threads[index].unreadCount = 0
    }

    /// Starts a keyless ride. The matching Home tile becomes the live surface
    /// on its own, because `activeTrip` becomes non-nil.
    @discardableResult
    func startRide(vehicleID: String, name: String, kind: VehicleKind,
                   until: Date? = nil, tariff: RideTariff = .hour) -> Bool {
        guard activeTrip == nil, !trips.contains(where: { $0.status == .paymentPending }),
              AppConfiguration.isDemo else { return false }
        releaseHold()
        trips.insert(Trip(id: UUID().uuidString, vehicleName: name, vehicleKind: kind,
                          status: .ongoing, startDate: .now,
                          endDate: until ?? .now.addingTimeInterval(tariff == .minute ? 0 : 3600),
                          total: 0, photoName: vehicles.first { $0.id == vehicleID }?.photoName,
                          vehicleID: vehicleID, tariff: tariff), at: 0)
        saveSnapshot()
        return true
    }

    @discardableResult
    func bookGolfCart(_ cart: Vehicle, hours: Int, total: Decimal,
                      paymentID: String = UUID().uuidString) -> Bool {
        guard activeTrip == nil, !trips.contains(where: { $0.status == .paymentPending }),
              AppConfiguration.isDemo else { return false }
        let depositID = paymentID + "-deposit"
        guard canCover(total + 100) else { return false }
        guard charge(total, label: cart.name, idempotencyKey: paymentID) != .declined else { return false }
        guard charge(100, label: "Refundable Golf deposit", idempotencyKey: depositID) != .declined else {
            refundPayment(paymentID, label: cart.name)
            return false
        }
        releaseHold()
        trips.insert(Trip(id: paymentID, vehicleName: cart.name, vehicleKind: .golfCart,
                          status: .ongoing, startDate: .now,
                          endDate: .now.addingTimeInterval(TimeInterval(hours) * 3600),
                          total: total, photoName: cart.photoName, vehicleID: cart.id,
                          depositPaymentID: depositID, returnPlace: "Sea Breeze Golf desk"), at: 0)
        saveSnapshot()
        return true
    }

    enum Settlement { case paid, paymentNeeded, unavailable }

    /// Stop billing once. A declined payment stays visible and retryable at a frozen fare.
    @discardableResult
    func endTrip(id: String) -> Settlement {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { return .unavailable }
        if trips[index].status == .completed { return .paid }
        guard trips[index].status == .ongoing || trips[index].status == .paymentPending else { return .unavailable }
        if trips[index].billingStoppedAt == nil {
            let now = Date.now
            let quote = rideQuote(trips[index], at: now)
            trips[index].total = quote.total
            trips[index].billingStoppedAt = now
            trips[index].reservedPlanMinutes = quote.planMinutes
            if quote.planMinutes > 0 { evPlan?.usedMinutes += quote.planMinutes }
            trips[index].endDate = now
        }
        if trips[index].vehicleKind == .electric,
           charge(trips[index].total, label: trips[index].vehicleName, symbol: "bolt.car.fill",
                  idempotencyKey: "ride-" + id) == .declined {
            trips[index].status = .paymentPending
            saveSnapshot()
            return .paymentNeeded
        }
        if let depositID = trips[index].depositPaymentID {
            refundPayment(depositID, label: "Golf deposit returned")
        }
        trips[index].status = .completed
        saveSnapshot()
        return .paid
    }

    static let evUnlockFee = RidePricing.unlock
    static let evHourRate = RidePricing.hour
    static let evDayCap = RidePricing.day

    func paidHours(_ trip: Trip, at now: Date = .now) -> Int {
        max(1, Int(ceil(max(now, trip.endDate).timeIntervalSince(trip.startDate) / 3600)))
    }

    func rideQuote(_ trip: Trip, at now: Date = .now) -> RideQuote {
        guard trip.vehicleKind == .electric, trip.billingStoppedAt == nil else {
            return RideQuote(total: trip.total, planMinutes: 0)
        }
        let minutes: Int
        if let plan = evPlan, plan.until > now {
            minutes = max(0, plan.option.minutes - plan.usedMinutes)
        } else { minutes = 0 }
        return RidePricing.quote(tariff: trip.tariff, elapsed: now.timeIntervalSince(trip.startDate),
                                 booked: trip.endDate.timeIntervalSince(trip.startDate), availableMinutes: minutes)
    }

    func rideCost(_ trip: Trip, at now: Date = .now) -> Decimal { rideQuote(trip, at: now).total }

    /// EV06 — adds an hour to the booked block; the ride keeps going.
    func extendRide(id: String) {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { return }
        guard trips[index].status == .ongoing, trips[index].tariff != .minute else { return }
        trips[index].endDate = trips[index].endDate.addingTimeInterval(3600)
        saveSnapshot()
    }

    var listings: [Listing] = []
    var threads: [MessageThread] = []
    var notifications: [AppNotification] = []
    var transactions: [Transaction] = []
    var news: [NewsItem] = []
    var walletBalance: Decimal = 0

    // MARK: Ledger (K1) — every payment in the app goes through here

    enum ChargeResult: Equatable {
        case paid(fromWallet: Decimal, fromCard: Decimal)
        case declined
    }

    /// W03 History reads this, newest first.
    var ledger: [WalletActivity] = []
    var defaultCard = "Visa •••• 4242"
    /// Demo switch: makes the card decline, to reach EV07 / G02a.
    var cardDeclines = false

    /// True when Wallet + the default card can pay `amount`.
    func canCover(_ amount: Decimal) -> Bool {
        amount <= max(walletBalance, 0) || !cardDeclines
    }

    /// Wallet first, the rest on the default card; records the charge.
    /// Returns `.declined` (and changes nothing) when neither covers it.
    private(set) var paymentBook = PaymentBook()

    @discardableResult
    func charge(_ amount: Decimal, label: String, symbol: String = "creditcard.fill",
                kind: WalletActivity.Kind = .rides, walletFirst: Bool = true,
                idempotencyKey: String = UUID().uuidString) -> ChargeResult {
        guard AppConfiguration.isDemo else { return .declined }
        let existing = paymentBook.receipts[idempotencyKey]
        var balance = walletBalance
        let result = paymentBook.charge(id: idempotencyKey, amount: amount, walletBalance: &balance,
                                        walletFirst: walletFirst, cardLabel: defaultCard, cardDeclines: cardDeclines)
        guard case .paid(let receipt) = result else { return .declined }
        walletBalance = balance
        if existing == nil, amount > 0 {
            let how = receipt.card == 0 ? "Wallet" : receipt.wallet == 0 ? receipt.cardLabel : "Wallet + " + receipt.cardLabel
            record(kind: kind, symbol: symbol, title: label, detail: how, amount: -amount)
        }
        saveSnapshot()
        return .paid(fromWallet: receipt.wallet, fromCard: receipt.card)
    }

    @discardableResult
    func refundPayment(_ id: String, label: String) -> Decimal {
        var balance = walletBalance
        guard let receipt = paymentBook.refund(id: id, walletBalance: &balance) else { return 0 }
        walletBalance = balance
        let amount = receipt.wallet + receipt.card
        record(kind: .refunds, symbol: "arrow.uturn.backward", title: label,
               detail: receipt.card > 0 ? "Demo refund · original Wallet / " + receipt.cardLabel : "Returned to Wallet",
               amount: amount)
        saveSnapshot()
        return amount
    }

    func cancelBooking(_ id: String) {
        guard let index = bookedRecords.firstIndex(where: { $0.id == id }), !bookedRecords[index].isCancelled else { return }
        let record = bookedRecords[index]
        let amount = record.paymentID.map { refundPayment($0, label: record.title) } ?? 0
        bookedRecords[index].isCancelled = true
        bookedRecords[index].status = "Cancelled"
        bookedRecords[index].tone = .danger
        bookedRecords[index].amount = amount > 0 ? .refunded(amount) : .noCharge
        bookedRecords[index].note = amount > 0 ? "Returned to the original payment method in this demo." : "No payment was taken."
        bookedRecords[index].actions = [.receipt]
        saveSnapshot()
    }

    /// Money back: to Wallet at once, or to the card in 3–5 days.
    func refund(_ amount: Decimal, label: String, toWallet: Bool = false) {
        guard amount > 0 else { return }
        if toWallet { walletBalance += amount }
        record(kind: .refunds, symbol: "arrow.uturn.backward", title: label,
               detail: toWallet ? String(localized: "To Wallet") : String(localized: "To \(defaultCard) · 3–5 days"),
               amount: amount)
    }

    /// Top-ups, promo codes and cashback all land in Wallet.
    func credit(_ amount: Decimal, label: String, symbol: String = "plus.circle.fill") {
        guard amount > 0, AppConfiguration.isDemo else { return }
        walletBalance += amount
        record(kind: .topUps, symbol: symbol, title: label, detail: String(localized: "Wallet"), amount: amount)
        saveSnapshot()
    }

    private func record(kind: WalletActivity.Kind, symbol: String, title: String, detail: String, amount: Decimal) {
        let day = Date.now.formatted(.dateTime.day().month(.abbreviated))
        ledger.insert(WalletActivity(id: UUID().uuidString, kind: kind, symbol: symbol,
                                     title: title, detail: "\(day) · \(detail)", amount: amount), at: 0)
    }

    /// EV08a — the minute package the person has, if any.
    var evPlan: EVPlan?

    /// EV08 — buys a package from Wallet; it starts now.
    @discardableResult
    func takePlan(_ option: EVPlanOption) -> Bool {
        guard !trips.contains(where: { $0.status == .paymentPending }) else { return false }
        guard charge(option.price, label: String(localized: "EV plan · \(option.minutes) min"),
                     symbol: "tag.fill") != .declined else { return false }
        let until = Calendar.current.date(byAdding: .day, value: option.period.days, to: .now) ?? .now
        evPlan = EVPlan(option: option, until: until, usedMinutes: 0)
        saveSnapshot()
        return true
    }

    // MARK: Host — section 07

    let host = HostState()

    func hostNotify(_ title: String, detail: String) {
        notify(symbol: "key.fill", title: String(localized: String.LocalizationValue(title)), detail: detail)
    }

    // MARK: Booking hold — EV01 / G02 "Held for you · 14:59"

    /// The one free 15-minute hold (D9) — across EV and golf, never two.
    struct Hold: Equatable {
        let vehicleID: String
        let vehicleName: String
        let kind: VehicleKind
        let until: Date
        /// Golf: what Start will charge once the person is at the desk.
        var hours = 0
        var total: Decimal = 0
    }

    private(set) var hold: Hold?
    static let holdLength: TimeInterval = 15 * 60

    /// When this vehicle's hold runs out, if it is the held one.
    func holdUntil(_ vehicleID: String) -> Date? {
        hold?.vehicleID == vehicleID ? hold?.until : nil
    }

    /// Holds the vehicle for 15 minutes, replacing any other hold. A reminder
    /// fires at 5:00 left and the hold simply lapses at 0:00 — no alert
    /// (handoff EV01).
    func hold(_ vehicle: Vehicle, hours: Int = 0, total: Decimal = 0) {
        let until = Date.now.addingTimeInterval(Store.holdLength)
        let new = Hold(vehicleID: vehicle.id, vehicleName: vehicle.name, kind: vehicle.kind,
                       until: until, hours: hours, total: total)
        hold = new
        Task {
            try? await Task.sleep(for: .seconds(Store.holdLength - 5 * 60))
            guard hold == new else { return }
            notify(symbol: "clock.fill", title: String(localized: "5 minutes left on your hold"),
                   detail: String(localized: "\(vehicle.name) is held for 5 more minutes"))
            try? await Task.sleep(for: .seconds(5 * 60))
            if hold == new { hold = nil }
        }
    }

    /// Cancel, or the ride starting — the car goes back on the map.
    func releaseHold() {
        hold = nil
    }

    /// L01 · Places — one list for the whole app; every place picker reads it.
    var places: [SavedPlace] = []
    /// The place last chosen in any picker ("Deliver to", pickup, …).
    var selectedPlaceID: String?

    var selectedPlace: SavedPlace? {
        places.first { $0.id == selectedPlaceID } ?? places.first
    }

    func addPlace(name: String, address: String) {
        let place = SavedPlace(id: UUID().uuidString, name: name, address: address, symbol: "mappin")
        places.append(place)
        selectedPlaceID = place.id
    }

    var unreadNotificationCount: Int {
        notifications.count { $0.isUnread }
    }

    @ObservationIgnored private var snapshotURL: URL?
    private(set) var persistenceError: String?

    init() {}

    private struct Snapshot: Codable {
        var version = 1
        let trips: [Trip]
        let bookings: [TripRecord]
        let balance: Decimal
        let payments: PaymentBook
        let ledger: [WalletActivity]
        let plan: EVPlan?
        let redeemedPromos: Set<String>
        let defaultCard: String?
    }

    func saveSnapshot() {
        guard let snapshotURL else { return }
        do {
            let snapshot = Snapshot(trips: trips, bookings: bookedRecords, balance: walletBalance,
                                    payments: paymentBook, ledger: ledger, plan: evPlan, redeemedPromos: redeemedPromos,
                                    defaultCard: defaultCard)
            try JSONEncoder().encode(snapshot).write(to: snapshotURL, options: [.atomic, .completeFileProtection])
        } catch { persistenceError = "Changes could not be saved on this device." }
    }

    var redeemedPromos: Set<String> = []

    static func live(snapshotURL suppliedURL: URL? = nil) -> Store {
        let store = AppConfiguration.isDemo ? seeded() : Store()
        store.trips = []
        store.ledger = []
        store.notifications = []
        store.transactions = []
        guard AppConfiguration.isDemo else { return store }
        do {
            let url: URL
            if let suppliedURL {
                url = suppliedURL
            } else {
                let folder = try FileManager.default.url(for: .applicationSupportDirectory,
                                                        in: .userDomainMask, appropriateFor: nil, create: true)
                url = folder.appendingPathComponent("rentbutik-v2-demo.json")
            }
            store.snapshotURL = url
            if FileManager.default.fileExists(atPath: url.path) {
                let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: url))
                guard snapshot.version == 1 else { throw CocoaError(.fileReadCorruptFile) }
                store.trips = snapshot.trips
                store.bookedRecords = snapshot.bookings
                store.walletBalance = snapshot.balance
                store.paymentBook = snapshot.payments
                store.ledger = snapshot.ledger
                store.evPlan = snapshot.plan
                store.redeemedPromos = snapshot.redeemedPromos
                store.defaultCard = snapshot.defaultCard ?? "Visa •••• 4242"
            }
        } catch {
            store.snapshotURL = nil // Preserve unreadable data for recovery; never overwrite it.
            store.persistenceError = "Saved demo data could not be loaded. This session will not be saved."
        }
        return store
    }

    // MARK: - Seed

    static func seeded() -> Store {
        let store = Store()
        store.vehicles = seedVehicles
        store.trips = seedTrips
        store.listings = seedListings
        store.threads = seedThreads
        store.notifications = seedNotifications
        store.transactions = seedTransactions
        store.news = seedNews
        store.walletBalance = 537.45
        store.places = [
            SavedPlace(id: "home", name: "Home", address: "Nizami St. 12", symbol: "house.fill"),
            SavedPlace(id: "work", name: "Work", address: "Port Baku Towers", symbol: "briefcase.fill",
                       latitude: 40.3727, longitude: 49.8605),
            SavedPlace(id: "airport", name: "Airport", address: "Heydar Aliyev, T1", symbol: "mappin.and.ellipse",
                       latitude: 40.4675, longitude: 50.0467),
        ]
        store.selectedPlaceID = "home"
        return store
    }

    private static func september(_ day: Int, hour: Int = 10) -> Date {
        let components = DateComponents(year: 2026, month: 9, day: day, hour: hour)
        return Calendar(identifier: .gregorian).date(from: components) ?? .now
    }

    /// August 2026, matching the dates on the real Trips screen.
    private static func august(_ day: Int, hour: Int = 10) -> Date {
        let components = DateComponents(year: 2026, month: 8, day: day, hour: hour)
        return Calendar(identifier: .gregorian).date(from: components) ?? .now
    }

    private static let seedVehicles: [Vehicle] = [
        Vehicle(id: "veh-amg-gt", name: "Mercedes-AMG GT", kind: .car,
                seats: 4, transmission: .automatic, fuel: .petrol,
                rating: 4.9, ratingCount: 80, area: "Sahil",
                pricePerDay: 380, pricePerHour: nil, pricePerMinute: nil,
                photoName: "mercedesAMGGT", batteryPercent: nil, rangeKm: nil),

        Vehicle(id: "veh-x5", name: "BMW X5 M-Sport", kind: .car,
                seats: 5, transmission: .automatic, fuel: .diesel,
                rating: 4.8, ratingCount: 42, area: "Yasamal",
                pricePerDay: 150, pricePerHour: nil, pricePerMinute: nil,
                photoName: nil, batteryPercent: nil, rangeKm: nil),

        Vehicle(id: "veh-civic", name: "Honda Civic", kind: .car,
                seats: 5, transmission: .manual, fuel: .petrol,
                rating: 4.7, ratingCount: 31, area: "Nizami",
                pricePerDay: 90, pricePerHour: nil, pricePerMinute: nil,
                photoName: nil, batteryPercent: nil, rangeKm: nil),

        Vehicle(id: "veh-ev-6", name: "Rentbutik EV 6", kind: .electric,
                seats: 5, transmission: .automatic, fuel: .electric,
                rating: 4.8, ratingCount: 64, area: "Nəsimi",
                pricePerDay: nil, pricePerHour: 15, pricePerMinute: 0.25,
                photoName: "evRentbutik", batteryPercent: 87, rangeKm: 380,
                latitude: 40.3767, longitude: 49.8480, walkMinutes: 1),

        Vehicle(id: "veh-ev-3", name: "Rentbutik EV 3", kind: .electric,
                seats: 5, transmission: .automatic, fuel: .electric,
                rating: 4.7, ratingCount: 41, area: "Nəsimi",
                pricePerDay: nil, pricePerHour: 15, pricePerMinute: 0.25,
                photoName: "evSuv", batteryPercent: 64, rangeKm: 280,
                latitude: 40.3810, longitude: 49.8390, walkMinutes: 4),

        Vehicle(id: "veh-ev-9", name: "Rentbutik EV 9", kind: .electric,
                seats: 5, transmission: .automatic, fuel: .electric,
                rating: 4.9, ratingCount: 22, area: "Sahil",
                pricePerDay: nil, pricePerHour: 15, pricePerMinute: 0.25,
                photoName: "evSuv", batteryPercent: 92, rangeKm: 410,
                latitude: 40.3705, longitude: 49.8560, walkMinutes: 6),

        Vehicle(id: "veh-ev-2", name: "Rentbutik EV 2", kind: .electric,
                seats: 5, transmission: .automatic, fuel: .electric,
                rating: 4.8, ratingCount: 37, area: "Baku",
                pricePerDay: nil, pricePerHour: 15, pricePerMinute: 0.25,
                photoName: "evRentbutik", batteryPercent: 71, rangeKm: 300,
                latitude: 40.3742, longitude: 49.8528, walkMinutes: 3),

        Vehicle(id: "veh-ev-5", name: "Rentbutik EV 5", kind: .electric,
                seats: 5, transmission: .automatic, fuel: .electric,
                rating: 4.9, ratingCount: 58, area: "Baku",
                pricePerDay: nil, pricePerHour: 15, pricePerMinute: 0.25,
                photoName: "evSuv", batteryPercent: 95, rangeKm: 420,
                latitude: 40.3688, longitude: 49.8412, walkMinutes: 5),

        Vehicle(id: "veh-ev-7", name: "Rentbutik EV 7", kind: .electric,
                seats: 5, transmission: .automatic, fuel: .electric,
                rating: 4.6, ratingCount: 19, area: "Baku",
                pricePerDay: nil, pricePerHour: 15, pricePerMinute: 0.25,
                photoName: "evRentbutik", batteryPercent: 48, rangeKm: 210,
                latitude: 40.3795, longitude: 49.8575, walkMinutes: 7),

        Vehicle(id: "veh-ev-11", name: "Rentbutik EV 11", kind: .electric,
                seats: 5, transmission: .automatic, fuel: .electric,
                rating: 4.8, ratingCount: 26, area: "Baku",
                pricePerDay: nil, pricePerHour: 15, pricePerMinute: 0.25,
                photoName: "evSuv", batteryPercent: 83, rangeKm: 360,
                latitude: 40.366, longitude: 49.85, walkMinutes: 8),

        // Photo identified by LOOKING: a white cart on grass.
        Vehicle(id: "veh-golf-4", name: "Golf cart 4", kind: .golfCart,
                seats: 4, transmission: .automatic, fuel: .electric,
                rating: 4.9, ratingCount: 18, area: "SeaBreeze",
                pricePerDay: nil, pricePerHour: 20, pricePerMinute: nil,
                photoName: "golfCartVIP", batteryPercent: 92, rangeKm: nil,
                latitude: 40.5912, longitude: 49.9858, walkMinutes: 2),

        // The photo previously mis-filed as "bmwX5" is a Ventura cart.
        Vehicle(id: "veh-golf-ventura", name: "Golf cart 6", kind: .golfCart,
                seats: 6, transmission: .automatic, fuel: .electric,
                rating: 4.8, ratingCount: 11, area: "SeaBreeze",
                pricePerDay: nil, pricePerHour: 18, pricePerMinute: nil,
                photoName: "golfCartVentura", batteryPercent: 78, rangeKm: nil,
                latitude: 40.5896, longitude: 49.9912, walkMinutes: 4),

        Vehicle(id: "veh-golf-2", name: "Golf cart 2", kind: .golfCart,
                seats: 4, transmission: .automatic, fuel: .electric,
                rating: 4.9, ratingCount: 24, area: "SeaBreeze",
                pricePerDay: nil, pricePerHour: 18, pricePerMinute: nil,
                photoName: "golfCartGrey", batteryPercent: 88, rangeKm: nil,
                latitude: 40.5918, longitude: 49.9876, walkMinutes: 1),

        Vehicle(id: "veh-golf-8", name: "Golf cart 8", kind: .golfCart,
                seats: 6, transmission: .automatic, fuel: .electric,
                rating: 5.0, ratingCount: 9, area: "SeaBreeze",
                pricePerDay: nil, pricePerHour: 24, pricePerMinute: nil,
                photoName: "golfCartClubCar", batteryPercent: 95, rangeKm: nil,
                latitude: 40.5903, longitude: 49.984, walkMinutes: 3),

        Vehicle(id: "veh-golf-9", name: "Golf cart 9", kind: .golfCart,
                seats: 4, transmission: .automatic, fuel: .electric,
                rating: 4.8, ratingCount: 14, area: "SeaBreeze",
                pricePerDay: nil, pricePerHour: 20, pricePerMinute: nil,
                photoName: "golfCartSunset", batteryPercent: 67, rangeKm: nil,
                latitude: 40.5889, longitude: 49.9893, walkMinutes: 5),

        Vehicle(id: "veh-golf-12", name: "Golf cart 12", kind: .golfCart,
                seats: 4, transmission: .automatic, fuel: .electric,
                rating: 4.7, ratingCount: 31, area: "SeaBreeze",
                pricePerDay: nil, pricePerHour: 16, pricePerMinute: nil,
                photoName: "golfCartFleet", batteryPercent: 99, rangeKm: nil,
                latitude: 40.591, longitude: 49.9928, walkMinutes: 6),
    ]

    private static let seedTrips: [Trip] = [
        // No ongoing ride by default: Home and the maps must not start a
        // timer on launch. A ride appears only after Start on EV01.
        Trip(id: "trip-1", vehicleName: "Mercedes-AMG GT", vehicleKind: .car, status: .upcoming,
             startDate: august(21), endDate: august(21, hour: 19),
             total: 380, photoName: "mercedesAMGGT"),
        Trip(id: "trip-2", vehicleName: "Rentbutik EV 6", vehicleKind: .electric, status: .completed,
             startDate: august(18), endDate: august(18, hour: 12),
             total: 120, photoName: "evSuv"),
        Trip(id: "trip-3", vehicleName: "Golf cart 4", vehicleKind: .golfCart, status: .completed,
             startDate: august(14), endDate: august(14, hour: 13),
             total: 45, photoName: "golfCartVIP"),
        Trip(id: "trip-4", vehicleName: "Porsche 911 Carrera", vehicleKind: .car, status: .cancelled,
             startDate: august(8), endDate: august(8, hour: 18),
             total: 460, photoName: nil),
    ]

    private static let seedListings: [Listing] = [
        Listing(id: "lst-1", vehicleName: "BMW X5 M-Sport", year: 2023,
                pricePerDay: 150, isActive: true, views: 142),
        Listing(id: "lst-2", vehicleName: "Honda Civic", year: 2021,
                pricePerDay: 90, isActive: true, views: 88),
        Listing(id: "lst-3", vehicleName: "Mercedes-AMG GT", year: 2024,
                pricePerDay: 380, isActive: false, views: 19),
        Listing(id: "lst-4", vehicleName: "Golf cart 4", year: 2022,
                pricePerDay: 45, isActive: false, views: 7),
    ]

    /// Copy verbatim from C01 / C02 in Design-flow.
    private static let seedThreads: [MessageThread] = [
        MessageThread(id: "thr-support", counterpartName: "Rentbutik Support",
                      subtitle: "Support · Here for you",
                      messages: [
                        Message(id: "m-1", text: "How can we help with your trip?",
                                isFromMe: false, sentAt: .now.addingTimeInterval(-40 * 60)),
                      ],
                      isUnread: false, isPinned: true,
                      presence: "Support · usually replies in a few minutes"),
        MessageThread(id: "thr-hasan", counterpartName: "Hasan Nabiyev",
                      subtitle: "Host",
                      messages: [
                        Message(id: "m-2", text: "Hi! The car is available. We can arrange a time to meet at the pickup point.",
                                isFromMe: false, sentAt: .now.addingTimeInterval(-9 * 60)),
                      ],
                      isUnread: false, vehicle: "Mercedes-AMG GT", unreadCount: 0,
                      presence: "Host · usually replies in 10 min"),
        MessageThread(id: "thr-nizami", counterpartName: "Nizami Aliyev",
                      subtitle: "Host",
                      messages: [
                        Message(id: "m-4", text: "Thanks, see you at the pickup point.",
                                isFromMe: false, sentAt: .now.addingTimeInterval(-26 * 3600)),
                      ],
                      isUnread: false, vehicle: "BMW X5",
                      presence: "Host · usually replies in an hour"),
    ]

    /// Copy verbatim from H01 Home in Design-flow.
    private static let seedNotifications: [AppNotification] = [
        // Emin, 28.09.2026: the first-ride offer is a notification, not a
        // Home banner.
        AppNotification(id: "ntf-first-ride", symbol: "gift.fill",
                        title: "First ride ₼5 off",
                        detail: "Applied automatically · any module",
                        isUnread: true, date: .now.addingTimeInterval(-60)),
        AppNotification(id: "ntf-1", symbol: "checkmark.seal.fill",
                        title: "Your booking is confirmed",
                        detail: "Mercedes-AMG GT · 22–23 Sep",
                        isUnread: false, date: .now.addingTimeInterval(-2 * 3600)),
        // Hasan's "The Mercedes is ready" is not seeded — it arrives live,
        // ~30 s after launch (see `startLiveDemo`).
        AppNotification(id: "ntf-3", symbol: "wallet.bifold.fill",
                        title: "Wallet top-up completed",
                        detail: "₼50 added to your balance",
                        isUnread: false, date: september(18, hour: 11)),
        AppNotification(id: "ntf-4", symbol: "bolt.fill",
                        title: "Electric ride completed",
                        detail: "Rentbutik EV 6 · 60 min · ₼16",
                        isUnread: false, date: september(18, hour: 15)),
        AppNotification(id: "ntf-5", symbol: "steeringwheel",
                        title: "Golf ride completed",
                        detail: "Golf cart 4 · 2 hours · ₼32",
                        isUnread: false, date: september(14, hour: 12)),
    ]

    private static let seedTransactions: [Transaction] = [
        Transaction(id: "txn-1", label: "Golf cart 4", amount: -45, date: august(14)),
        Transaction(id: "txn-2", label: "Rentbutik EV 6", amount: -120, date: august(18)),
        Transaction(id: "txn-3", label: "Top up", amount: 200, date: august(15)),
        Transaction(id: "txn-4", label: "Hosting payout", amount: 440, date: august(12)),
    ]

    private static let seedNews: [NewsItem] = [
        NewsItem(id: "news-1", category: "Welcome",
                 headline: "Welcome to Rentbutik",
                 photoName: "mercedesAMGGT", symbol: "car.fill"),
        NewsItem(id: "news-2", category: "Hosting",
                 headline: "Earn by hosting your car",
                 photoName: "hostingNews", symbol: "house.fill"),
        NewsItem(id: "news-3", category: "Electric",
                 headline: "Electric fleet expands across Baku",
                 photoName: "evSuv", symbol: "bolt.car.fill"),
        NewsItem(id: "news-4", category: "Golf",
                 headline: "Golf carts now in SeaBreeze",
                 photoName: "golfCartVIP", symbol: "steeringwheel"),
    ]
}
