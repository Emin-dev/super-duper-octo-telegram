import SwiftUI
import MapKit
import PhotosUI

// MARK: - Data — section 07 · Host

/// Everything the Host section shows, in one place, so accepting a request
/// or publishing a car updates HO01 at once.
@Observable
final class HostState {
    enum RequestStatus { case pending, accepted, declined }

    struct Car: Identifiable, Equatable {
        let id: String
        var name: String
        var photo: String?
        var pricePerDay: Decimal
        /// "Live · ₼120 / day", "On a trip with Aysel".
        var status: String
        var detail: String
        var isPaused = false
        var isOnTrip = false
        var blocked = RentalDates(pickUp: .distantPast, dropOff: .distantPast)
    }

    struct TransferOffer: Identifiable, Equatable {
        let id: String
        var route: String
        var when: String
        var car: String
        var pricePerSeat: Decimal
        var seats: Int
    }

    var paidOut: Decimal = 1240
    var upcoming: Decimal = 216
    var bookings = 6
    var views = 312

    var request: RequestStatus = .pending
    var pickupDone = false
    var returnClosed = false
    var passengerRequest: RequestStatus = .pending

    var cars: [Car] = [
        .init(id: "host-amg", name: "Mercedes-AMG GT", photo: "mercedesAMGGT", pricePerDay: 120,
              status: "Live", detail: "Availability, price and details"),
        .init(id: "host-x5", name: "BMW X5 M-Sport", photo: nil, pricePerDay: 150,
              status: "On a trip with Aysel", detail: "Returns 26 Sep, 10:00", isOnTrip: true),
    ]

    var transfers: [TransferOffer] = [
        .init(id: "tr-gyd", route: "Airport → Baku", when: "27 Sep · 10:00",
              car: "Mercedes-AMG GT", pricePerSeat: 35, seats: 1),
    ]

    /// HO03 — 2 days × ₼120, 10 % host fee.
    static let requestDays = 2
    static let hostFeeRate: Decimal = 0.10
}

private func money(_ v: Decimal, _ digits: Int = 0) -> String {
    v.formatted(.currency(code: Currency.code).precision(.fractionLength(digits)))
}

// MARK: - HO01 · Hosting

struct HostingScreen: View {
    let store: Store
    let router: AppRouter

    @State private var carSheet: HostState.Car?
    private var host: HostState { store.host }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                earnings

                HStack(spacing: 10) {
                    RentbutikPrimaryButton("Add a car") { router.push(.hostListCar) }
                    RentbutikPrimaryButton("Post a transfer") { router.push(.hostPostTransfer) }
                }

                if host.request == .pending || !host.pickupDone {
                    HostSectionTitle("Needs you")
                    if host.request == .pending {
                        HostRow(symbol: "calendar", title: "New booking request",
                                line: "Aysel · Mercedes-AMG GT",
                                detail: "24–26 Sep · you earn \(money(host.upcoming))",
                                chip: "Reply within 24 h") { router.push(.hostRequest) }
                    }
                    if !host.pickupDone {
                        HostRow(symbol: "mappin.and.ellipse", title: "Pickup today",
                                line: "Aysel · Mercedes-AMG GT",
                                detail: "Today, 10:00 · Sahil, Baku") { router.push(.hostHandoff) }
                    }
                }

                HostSectionTitle("Your cars")
                ForEach(host.cars) { car in
                    HostRow(symbol: "car.side.fill", title: LocalizedStringKey(car.name),
                            line: car.isOnTrip ? car.status
                                : car.isPaused ? String(localized: "Paused")
                                : String(localized: "Live · \(money(car.pricePerDay)) / day"),
                            detail: car.detail) {
                        if car.isOnTrip { router.push(.hostReturn) } else { carSheet = car }
                    }
                }

                HostSectionTitle("Transfers")
                HostRow(symbol: "point.topleft.down.to.point.bottomright.curvepath.fill",
                        title: "Your transfers",
                        line: String(localized: "\(host.transfers.count) live offer · \(host.passengerRequest == .pending ? 1 : 0) new request"),
                        detail: String(localized: "Post rides and tours with your car")) {
                    router.push(.hostTransfers)
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.tabBarClearance)
            .animation(Theme.smooth, value: host.request)
            .animation(Theme.smooth, value: host.pickupDone)
        }
        .background(Theme.background)
        .navigationTitle("Hosting")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $carSheet) { car in HostCarSheet(store: store, carID: car.id) }
    }

    private var earnings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Earnings · \(Date.now.formatted(.dateTime.month(.wide)))",
                  systemImage: "chart.line.uptrend.xyaxis")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .labelStyle(TightLabelStyle())
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(money(host.paidOut))
                    .font(Theme.Font.largeTitle)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text("paid out this month")
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack(spacing: 8) {
                stat(money(host.upcoming), "upcoming")
                stat("\(host.bookings)", "bookings")
                stat("\(host.views)", "views")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(Theme.Radius.card)
    }

    private func stat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.fill, in: .rect(cornerRadius: Theme.Radius.chip))
    }
}

private struct HostSectionTitle: View {
    let title: LocalizedStringKey
    init(_ title: LocalizedStringKey) { self.title = title }
    var body: some View {
        Text(title)
            .font(Theme.Font.title3)
            .foregroundStyle(Theme.ink)
            .padding(.top, 6)
    }
}

/// Badge, optional chip, title, two lines and a chevron — HO01's rows.
private struct HostRow: View {
    let symbol: String
    let title: LocalizedStringKey
    let line: String
    let detail: String
    var chip: LocalizedStringKey? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RentbutikBadge(symbol: symbol, size: .notification)
                VStack(alignment: .leading, spacing: 3) {
                    if let chip {
                        Text(chip)
                            .font(Theme.Font.captionSemibold)
                            .foregroundStyle(Theme.goldText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.brandTint, in: .capsule)
                    }
                    Text(title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text(line)
                        .font(Theme.Font.subheadlineRegular)
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(Theme.Radius.card)
        }
        .buttonStyle(PressScale(haptic: .open))
        .transition(.opacity.combined(with: .scale(0.97)))
    }
}

// MARK: - HO03 · Booking request

struct HostRequestScreen: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    private var subtotal: Decimal { 120 * Decimal(HostState.requestDays) }
    private var fee: Decimal { subtotal * HostState.hostFeeRate }

    var body: some View {
        HostDetailScaffold(title: "Booking request", heading: "Aysel wants to book your car") {
            HostSummaryCard(title: "Mercedes-AMG GT",
                            line: "24 Sep, 10:00 → 26 Sep, 10:00",
                            accent: "Pickup · Baku, Sahil")
            HostFactsCard(facts: [
                ("\(HostState.requestDays) days × \(money(120))", money(subtotal)),
                (String(localized: "Host service fee"), "−\(money(fee))"),
                (String(localized: "You earn"), money(subtotal - fee)),
            ])
            HostFootnote("Review the dates and pickup details before accepting.")
            RentbutikPrimaryButton(working ? "Accepting…" : "Accept request", haptic: .celebrate) {
                decide(.accepted)
            }
            .disabled(working)
            RentbutikPrimaryButton("Decline request", destructive: true) { decide(.declined) }
                .disabled(working)
        }
    }

    /// The renter's "Waiting for host" turns into Booked or Declined.
    private func decide(_ status: HostState.RequestStatus) {
        working = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(Theme.smooth) {
                store.host.request = status
                if status == .accepted { store.host.bookings += 1 } else { store.host.upcoming = 0 }
            }
            store.hostNotify(status == .accepted ? "Booking accepted" : "Booking declined",
                             detail: "Aysel · Mercedes-AMG GT · 24–26 Sep")
            dismiss()
        }
    }
}

// MARK: - HO04 · Handoff   /   HO04b · Car returned

struct HostHandoffScreen: View {
    let store: Store
    let router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HostDetailScaffold(title: "Handoff", heading: "Ready for pickup") {
            HostSummaryCard(title: "Aysel · Mercedes-AMG GT",
                            line: "Today, 10:00 · Baku, Sahil",
                            accent: store.host.request == .accepted ? "Booking accepted" : "Booked")
            HostFactsCard(facts: [
                (String(localized: "Identity & licence"), String(localized: "Checked with renter")),
                (String(localized: "Fuel level · odometer"), String(localized: "Full · 24,180 km")),
                (String(localized: "Vehicle condition"), String(localized: "Photos saved · no new damage")),
            ], stacked: true)
            HostFootnote("Confirm the condition together before handing over the keys.")
            RentbutikPrimaryButton("Confirm handoff & start rental", haptic: .celebrate) {
                withAnimation(Theme.smooth) { store.host.pickupDone = true }
                store.hostNotify("Rental started", detail: "Aysel · Mercedes-AMG GT")
                dismiss()
            }
            RentbutikSmallButton("Message Aysel") { router.push(.thread(threadID: "thr-hasan")) }
        }
    }
}

struct HostReturnScreen: View {
    let store: Store
    let router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HostDetailScaffold(title: "Return", heading: "Car is back") {
            HostSummaryCard(title: "Aysel · BMW X5 M-Sport",
                            line: "26 Sep, 10:00 · Baku, Sahil", accent: "Trip ended")
            HostFactsCard(facts: [
                (String(localized: "Fuel level · odometer"), String(localized: "Full · 31,860 km · 680 km driven")),
                (String(localized: "Extra distance"), String(localized: "80 km over 600 km · ₼28 added to Aysel")),
                (String(localized: "Vehicle condition"), String(localized: "Photos saved · no new damage")),
            ], stacked: true)
            HostFootnote("Check the car together, then close the trip.")
            RentbutikPrimaryButton("Close trip", haptic: .celebrate) {
                withAnimation(Theme.smooth) {
                    if let i = store.host.cars.firstIndex(where: { $0.id == "host-x5" }) {
                        store.host.cars[i].isOnTrip = false
                        store.host.cars[i].status = "Live"
                        store.host.cars[i].detail = String(localized: "Availability, price and details")
                    }
                    store.host.paidOut += 28
                }
                dismiss()
            }
            RentbutikSmallButton("Report a problem") { router.push(.thread(threadID: "thr-support")) }
        }
    }
}

// MARK: - HO05 · Car sheet

struct HostCarSheet: View {
    let store: Store
    let carID: String
    @Environment(\.dismiss) private var dismiss
    @State private var dates = RentalDates.golfDaily

    private var index: Int? { store.host.cars.firstIndex { $0.id == carID } }

    var body: some View {
        VStack(spacing: 14) {
            if let index {
                ZStack {
                    VStack(spacing: 1) {
                        Text(store.host.cars[index].name)
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.ink)
                        Text(store.host.cars[index].isPaused ? "Paused"
                             : "Live · \(money(store.host.cars[index].pricePerDay)) / day")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    HStack {
                        Button("Edit") {}
                            .foregroundStyle(Theme.goldText)
                            .buttonStyle(.rentbutik)
                            .buttonBorderShape(.capsule)
                        Spacer()
                        Button("Done") {
                            store.host.cars[index].blocked = dates
                            dismiss()
                        }
                        .foregroundStyle(Theme.goldText)
                        .buttonStyle(.rentbutik)
                        .buttonBorderShape(.capsule)
                    }
                }

                RangeCalendar(dates: $dates)
                HostFootnote("24–26 booked by Aysel · tap days to block")

                GroupedCard {
                    GroupedRow(label: "Pause listing", showsDivider: false) {
                        Toggle("Pause listing", isOn: Binding(
                            get: { store.host.cars[index].isPaused },
                            set: { v in withAnimation(Theme.snappy) { store.host.cars[index].isPaused = v } }))
                            .labelsHidden()
                            .tint(Theme.success)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .fittedSheet()
    }
}

// MARK: - HO06 · Your transfers   /   HO08 · Passenger request

struct HostTransfersScreen: View {
    let store: Store
    let router: AppRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Drive on your schedule")
                        .font(Theme.Font.largeTitle)
                        .foregroundStyle(Theme.ink)
                    Text("Manage your offers and passenger requests.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.inkSoft)
                }
                ForEach(store.host.transfers) { offer in
                    HostSummaryCard(title: LocalizedStringKey(offer.route), line: "\(offer.when) · \(offer.car)",
                                    accent: String(localized: "Live offer · \(offer.seats) seat · \(money(offer.pricePerSeat))"))
                }
                if store.host.passengerRequest == .pending {
                    Button { router.push(.hostPassenger) } label: {
                        HostSummaryCard(title: "Aysel sent a request",
                                        line: String(localized: "1 passenger · 1 cabin bag"),
                                        accent: String(localized: "Review pickup details"))
                    }
                    .buttonStyle(PressScale(haptic: .open))
                    .transition(.opacity.combined(with: .scale(0.97)))
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.tabBarClearance)
            .animation(Theme.smooth, value: store.host.passengerRequest)
        }
        .background(Theme.background)
        .navigationTitle("Your transfers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Post a transfer", systemImage: "plus") { router.push(.hostPostTransfer) }
            }
        }
    }
}

struct HostPassengerScreen: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HostDetailScaffold(title: "Passenger request", heading: "Aysel wants to ride with you") {
            HostSummaryCard(title: "Airport → Baku", line: "27 Sep · 10:00 · \(money(35))",
                            accent: "1 passenger · 1 cabin bag")
            HostFactsCard(facts: [
                (String(localized: "Meet at"), String(localized: "Terminal 1 · arrivals exit")),
                (String(localized: "Drop-off"), String(localized: "Baku · Sahil")),
                (String(localized: "Note from Aysel"), String(localized: "I’ll wait near the arrivals exit.")),
            ], stacked: true)
            RentbutikPrimaryButton("Accept passenger", haptic: .celebrate) { decide(.accepted) }
            RentbutikPrimaryButton("Decline request", destructive: true) { decide(.declined) }
        }
    }

    private func decide(_ status: HostState.RequestStatus) {
        withAnimation(Theme.smooth) { store.host.passengerRequest = status }
        store.hostNotify(status == .accepted ? "Passenger accepted" : "Request declined",
                         detail: "Aysel · Airport → Baku · 27 Sep")
        dismiss()
    }
}

// MARK: - HO02 · List your car (4 steps)

struct HostListCarScreen: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    // Step 1
    @State private var make = "Mercedes-Benz"
    @State private var model = "AMG GT"
    @State private var year = 2022
    @State private var body_ = "Sports car"
    @State private var transmission = "Automatic"
    @State private var fuel = "Petrol"
    @State private var seats = 2
    @State private var doors = 2
    @State private var mileage = "42,000 km"
    @State private var plate = "10-AB-123"
    // Step 2
    @State private var photos: [PhotosPickerItem] = []
    @State private var features: Set<String> = ["Air conditioning", "Bluetooth audio", "GPS", "First aid kit", "Fire extinguisher"]
    @State private var about = ""
    // Step 3
    @State private var instantBook = true
    @State private var availableFrom = Date.now
    // Step 4
    @State private var fullTank = true
    @State private var chauffeur = false
    @State private var decorations = false
    @State private var dailyPrice: Decimal = 120
    @State private var longStay = false
    @State private var included = "300 km / day"
    @State private var confirmed = true

    private let allFeatures = ["Air conditioning", "Bluetooth audio", "Audio input", "GPS", "First aid kit",
                               "Fire extinguisher", "Tools", "Special occasion", "Airport pick-up", "Airport drop-off"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                StepProgress(step: step, of: 4, title: stepTitle)
                Group {
                    switch step {
                    case 1: carDetails
                    case 2: photosAndFeatures
                    case 3: whereAndWhen
                    default: priceAndExtras
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 24)
            .animation(Theme.smooth, value: step)
        }
        .background(Theme.background)
        .navigationTitle("List your car")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(step > 1)
        .toolbar {
            if step > 1 {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.left") { step -= 1 }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            RentbutikPrimaryButton(step == 4 ? "Publish listing" : "Continue",
                                   haptic: step == 4 ? .celebrate : .click) {
                if step < 4 { step += 1 } else { publish() }
            }
            .disabled(step == 4 && !confirmed)
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 8)
        }
        .sensoryFeedback(.selection, trigger: step)
    }

    private var stepTitle: LocalizedStringKey {
        switch step {
        case 1: "Your car"
        case 2: "Photos & features"
        case 3: "Where & when"
        default: "Price & extras"
        }
    }

    private var carDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            HostFormTitle("Car details")
            GroupedCard {
                menuRow("Make", $make, ["Mercedes-Benz", "BMW", "Porsche", "Toyota", "Hyundai", "Kia"])
                menuRow("Model", $model, ["AMG GT", "C-Class", "E-Class", "X5", "911", "Camry"])
                stepperRow("Year", $year, 2005...2026)
                menuRow("Body type", $body_, ["Sports car", "Sedan", "SUV", "Hatchback", "Convertible"])
                menuRow("Transmission", $transmission, ["Automatic", "Manual"])
                menuRow("Fuel", $fuel, ["Petrol", "Diesel", "Hybrid", "Electric"])
                stepperRow("Seats", $seats, 2...9)
                stepperRow("Doors", $doors, 2...5)
                textRow("Mileage", $mileage)
                textRow("Plate number", $plate, last: true)
            }
        }
    }

    private var photosAndFeatures: some View {
        VStack(alignment: .leading, spacing: 8) {
            HostFormTitle("Photos")
            PhotoStrip(items: $photos)
            HostFormTitle("Features")
            FlowChips(options: allFeatures, selection: $features)
                .padding(12)
                .glassCard(Theme.Radius.group)
            HostFormTitle("Description")
            TextField("Tell renters what makes your car special, and what is and isn’t allowed in it.",
                      text: $about, axis: .vertical)
                .lineLimit(3...6)
                .font(Theme.Font.body)
                .padding(14)
                .glassCard(Theme.Radius.group)
        }
    }

    private var whereAndWhen: some View {
        VStack(alignment: .leading, spacing: 8) {
            HostFormTitle("Car location")
            VStack(spacing: 0) {
                MiniPinMap(coordinate: .init(latitude: 40.3712, longitude: 49.8455))
                GroupedCard {
                    GroupedRow(label: "Address") { valueChevron("Neftchilar Ave 12, Sahil") }
                    GroupedRow(label: "Country", showsDivider: false) { valueChevron("Azerbaijan") }
                }
            }
            HostFootnote("Move the map so the pin sits exactly where the car is parked. Renters see the pin only after booking.")
            HostFormTitle("Booking")
            GroupedCard {
                GroupedRow(label: "Instant Book") { Toggle("Instant Book", isOn: $instantBook).labelsHidden().tint(Theme.success) }
                GroupedRow(label: "Available from") {
                    DatePicker("Available from", selection: $availableFrom, in: Date.now...).labelsHidden()
                }
                GroupedRow(label: "Blocked dates", showsDivider: false) { valueChevron("None") }
            }
            HostFootnote("Instant Book: renters book right away. Turn it off to approve each request yourself.")
        }
    }

    private var priceAndExtras: some View {
        VStack(alignment: .leading, spacing: 8) {
            HostFormTitle("Extras you offer")
            GroupedCard {
                extraRow("fuelpump.fill", "Full tank", "₼50", $fullTank)
                extraRow("steeringwheel", "Chauffeur", "₼50 / day", $chauffeur)
                extraRow("sparkles", "Decorations", "₼50", $decorations, last: true)
            }
            HostFormTitle("Price")
            GroupedCard {
                GroupedRow(label: "Daily price") {
                    TextField("₼", value: $dailyPrice, format: .currency(code: Currency.code).precision(.fractionLength(0)))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: 100)
                }
                HostFootnote("Similar cars in Baku: ₼110–130").padding(.bottom, 6)
                GroupedRow(label: "Weekly & monthly prices") { Toggle("Weekly", isOn: $longStay).labelsHidden().tint(Theme.success) }
                GroupedRow(label: "Included distance") {
                    Picker("Included distance", selection: $included) {
                        ForEach(["200 km / day", "300 km / day", "Unlimited"], id: \.self) { Text($0) }
                    }
                    .tint(Theme.inkSoft)
                }
                GroupedRow(label: "Extra distance", showsDivider: false) {
                    Text(verbatim: "₼0.35 / km").foregroundStyle(Theme.inkSoft)
                }
            }
            ConfirmCheck(isOn: $confirmed,
                         text: "I confirm this car has never been written off, rebuilt or sold for scrap.")
        }
    }

    private func publish() {
        store.host.cars.insert(.init(id: UUID().uuidString, name: "\(make) \(model)", photo: nil,
                                     pricePerDay: dailyPrice, status: "Live",
                                     detail: String(localized: "Availability, price and details")), at: 0)
        store.hostNotify("Your car is live", detail: "\(make) \(model) · \(money(dailyPrice)) / day")
        dismiss()
    }

    // Row builders
    private func menuRow(_ label: LocalizedStringKey, _ value: Binding<String>, _ options: [String]) -> some View {
        GroupedRow(label: label) {
            Picker(label, selection: value) { ForEach(options, id: \.self) { Text($0) } }
                .tint(Theme.inkSoft)
                .lineLimit(1)
                .fixedSize()
        }
    }
    private func stepperRow(_ label: LocalizedStringKey, _ value: Binding<Int>, _ range: ClosedRange<Int>) -> some View {
        GroupedRow(label: label) {
            HStack(spacing: 8) {
                Text(verbatim: "\(value.wrappedValue)").foregroundStyle(Theme.inkSoft).monospacedDigit()
                Stepper(label, value: value, in: range).labelsHidden()
            }
        }
    }
    private func textRow(_ label: LocalizedStringKey, _ value: Binding<String>, last: Bool = false) -> some View {
        GroupedRow(label: label, showsDivider: !last) {
            TextField(label, text: value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Theme.inkSoft)
        }
    }
    private func extraRow(_ symbol: String, _ title: LocalizedStringKey, _ price: String,
                          _ on: Binding<Bool>, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                RentbutikBadge(symbol: symbol, size: .stepRow)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(Theme.Font.body).foregroundStyle(Theme.ink)
                    Text(price).font(Theme.Font.footnoteRegular).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Toggle(title, isOn: on).labelsHidden().tint(Theme.success)
            }
            .frame(minHeight: 52)
            if !last { Divider().overlay(Theme.hairline) }
        }
    }
    private func valueChevron(_ text: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Text(text).foregroundStyle(Theme.inkSoft)
            Image(systemName: "chevron.right").font(Theme.Font.footnote).foregroundStyle(Theme.inkFaint)
        }
    }
}

// MARK: - HO07 · Post a transfer (4 steps)

struct HostPostTransferScreen: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    @State private var photos: [PhotosPickerItem] = []
    @State private var papers: Set<String> = ["Vehicle registration", "Insurance (OSAGO)", "Driving licence ✓ (from sign-in)"]
    @State private var note = ""
    @State private var instant = true
    @State private var stops = "None"
    @State private var date = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var returnTrip = false
    @State private var repeats = "Never"
    @State private var seatsForSale = true
    @State private var seats = 3
    @State private var bigLuggage = false
    @State private var childSeat = false
    @State private var pricePerSeat: Decimal = 35
    @State private var wholeCar = true
    @State private var wholeCarPrice: Decimal = 120
    @State private var confirmed = true

    /// HO07d — "You get … after the 10 % fee", live.
    private var youGet: Decimal {
        let seatTotal = seatsForSale ? pricePerSeat * Decimal(seats) : 0
        return max(seatTotal, wholeCar ? wholeCarPrice : 0) * (1 - HostState.hostFeeRate)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                StepProgress(step: step, of: 4, title: stepTitle)
                Group {
                    switch step {
                    case 1: carCheck
                    case 2: route
                    case 3: when
                    default: seatsAndPrice
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 24)
            .animation(Theme.smooth, value: step)
        }
        .background(Theme.background)
        .navigationTitle("Post a transfer")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(step > 1)
        .toolbar {
            if step > 1 {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.left") { step -= 1 }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            RentbutikPrimaryButton(step == 1 ? "Continue to your transfer" : step == 4 ? "Publish transfer" : "Continue",
                                   haptic: step == 4 ? .celebrate : .click) {
                if step < 4 { step += 1 } else { publish() }
            }
            .disabled(step == 4 && !confirmed)
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 8)
        }
        .sensoryFeedback(.selection, trigger: step)
    }

    private var stepTitle: LocalizedStringKey {
        switch step {
        case 1: "Car check"
        case 2: "Route"
        case 3: "When"
        default: "Seats & price"
        }
    }

    private var carCheck: some View {
        VStack(alignment: .leading, spacing: 8) {
            HostFormTitle("Car photos")
            PhotoStrip(items: $photos)
            HostFormTitle("Papers")
            FlowChips(options: ["Vehicle registration", "Insurance (OSAGO)", "Technical inspection",
                                "Driving licence ✓ (from sign-in)"],
                      selection: $papers, symbol: "doc.text.fill")
                .padding(12)
                .glassCard(Theme.Radius.group)
            HostFormTitle("Note")
            Text("We check the papers within a few hours. You can post the transfer now; it goes live once approved.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.inkSoft)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(Theme.Radius.group)
        }
    }

    private var route: some View {
        VStack(alignment: .leading, spacing: 8) {
            HostFormTitle("Route")
            VStack(spacing: 0) {
                MiniPinMap(coordinate: .init(latitude: 40.4675, longitude: 50.0467))
                GroupedCard {
                    GroupedRow(label: "Pickup") { Text("Airport · Terminal 1").foregroundStyle(Theme.inkSoft) }
                    GroupedRow(label: "Destination", showsDivider: false) { Text("Baku · Sahil").foregroundStyle(Theme.inkSoft) }
                }
            }
            HostFootnote("Drag the pins to the exact pickup and drop-off points. Passengers see the pickup point after booking.")
            HostFormTitle("Booking")
            GroupedCard {
                GroupedRow(label: "Instant booking") { Toggle("Instant booking", isOn: $instant).labelsHidden().tint(Theme.success) }
                GroupedRow(label: "Stops on the way") {
                    Picker("Stops", selection: $stops) { ForEach(["None", "1 stop", "2 stops"], id: \.self) { Text($0) } }
                        .tint(Theme.inkSoft)
                }
                GroupedRow(label: "Meet point", showsDivider: false) { Text("Arrivals exit").foregroundStyle(Theme.inkSoft) }
            }
            HostFootnote("Instant booking: passengers book a seat right away. Turn it off to accept each request yourself.")
        }
    }

    private var when: some View {
        VStack(alignment: .leading, spacing: 8) {
            HostFormTitle("Departure")
            GroupedCard {
                GroupedRow(label: "Date") { DatePicker("Date", selection: $date, in: Date.now..., displayedComponents: .date).labelsHidden() }
                GroupedRow(label: "Time", showsDivider: false) { DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute).labelsHidden() }
            }
            HostFootnote("Times are Baku time. Passengers are asked to arrive 10 min early.")
            HostFormTitle("Repeat")
            GroupedCard {
                GroupedRow(label: "Return trip") { Toggle("Return trip", isOn: $returnTrip).labelsHidden().tint(Theme.success) }
                GroupedRow(label: "Repeats", showsDivider: false) {
                    Picker("Repeats", selection: $repeats) {
                        ForEach(["Never", String(localized: "Every \(date.formatted(.dateTime.weekday(.wide)))")], id: \.self) { Text($0) }
                    }
                    .tint(Theme.inkSoft)
                }
            }
            HostFootnote("Each date becomes its own ride. You can cancel one date without cancelling the rest.")
        }
    }

    private var seatsAndPrice: some View {
        VStack(alignment: .leading, spacing: 8) {
            HostFormTitle("Seats & luggage")
            GroupedCard {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        RentbutikBadge(symbol: "person.2.fill", size: .stepRow)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Seats for sale").font(Theme.Font.body).foregroundStyle(Theme.ink)
                            Text("\(seats) of 4").font(Theme.Font.footnoteRegular).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Stepper("Seats", value: $seats, in: 1...4).labelsHidden().disabled(!seatsForSale)
                        Toggle("Seats for sale", isOn: $seatsForSale).labelsHidden().tint(Theme.success)
                    }
                    .frame(minHeight: 52)
                    Divider().overlay(Theme.hairline)
                }
                toggleRow("suitcase.fill", "Big luggage", "1 bag per seat", $bigLuggage)
                toggleRow("carseat.right.fill", "Child seat", "On request", $childSeat, last: true)
            }
            HostFormTitle("Price")
            GroupedCard {
                GroupedRow(label: "Price per seat") {
                    TextField("₼", value: $pricePerSeat, format: .currency(code: Currency.code).precision(.fractionLength(0)))
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        .foregroundStyle(Theme.inkSoft).frame(maxWidth: 90)
                }
                HostFootnote("Similar rides: ₼30–40 per seat").padding(.bottom, 6)
                GroupedRow(label: "Sell the whole car too") { Toggle("Whole car", isOn: $wholeCar).labelsHidden().tint(Theme.success) }
                if wholeCar {
                    GroupedRow(label: "Whole car price") {
                        TextField("₼", value: $wholeCarPrice, format: .currency(code: Currency.code).precision(.fractionLength(0)))
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            .foregroundStyle(Theme.inkSoft).frame(maxWidth: 90)
                    }
                }
                GroupedRow(label: "Cancellation", showsDivider: false) {
                    Text("Flexible · 2 h").foregroundStyle(Theme.inkSoft)
                }
            }
            Text("You get \(money(youGet)) after the 10 % fee")
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.goldText)
                .contentTransition(.numericText())
                .animation(Theme.snappy, value: youGet)
                .padding(.horizontal, 2)
            ConfirmCheck(isOn: $confirmed, text: "I confirm I hold a valid licence and the car is insured for passengers.")
        }
    }

    private func toggleRow(_ symbol: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey,
                           _ on: Binding<Bool>, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                RentbutikBadge(symbol: symbol, size: .stepRow)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(Theme.Font.body).foregroundStyle(Theme.ink)
                    Text(detail).font(Theme.Font.footnoteRegular).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Toggle(title, isOn: on).labelsHidden().tint(Theme.success)
            }
            .frame(minHeight: 52)
            if !last { Divider().overlay(Theme.hairline) }
        }
    }

    private func publish() {
        store.host.transfers.insert(.init(id: UUID().uuidString, route: "Airport → Baku",
                                          when: date.formatted(.dateTime.day().month(.abbreviated).hour().minute()),
                                          car: "Mercedes-AMG GT", pricePerSeat: pricePerSeat, seats: seats), at: 0)
        store.hostNotify("Transfer posted", detail: "Airport → Baku · goes live once papers are approved")
        dismiss()
    }
}

// MARK: - Shared pieces

/// "Step 2 of 4 · Photos & features" with a brand/solid progress bar.
private struct StepProgress: View {
    let step: Int
    let of: Int
    let title: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(step) of \(of) · \(Text(title))")
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.ink)
                .contentTransition(.opacity)
            ProgressView(value: Double(step), total: Double(of))
                .tint(Theme.brandSolid)
                .animation(Theme.smooth, value: step)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }
}

private struct HostFormTitle: View {
    let title: LocalizedStringKey
    init(_ title: LocalizedStringKey) { self.title = title }
    var body: some View {
        Text(title)
            .textCase(.uppercase)
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.inkSoft)
            .padding(.leading, 2)
            .padding(.top, 6)
    }
}

private struct HostFootnote: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        Text(text)
            .font(Theme.Font.footnoteRegular)
            .foregroundStyle(Theme.inkSoft)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Title + content + actions, the layout HO03 / HO04 / HO04b / HO08 share.
private struct HostDetailScaffold<Content: View>: View {
    let title: LocalizedStringKey
    let heading: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                Text(heading)
                    .font(Theme.Font.title1)
                    .foregroundStyle(Theme.ink)
                content
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.tabBarClearance)
        }
        .background(Theme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HostSummaryCard: View {
    let title: LocalizedStringKey
    let line: String
    let accent: String

    init(title: LocalizedStringKey, line: String, accent: String) {
        self.title = title; self.line = line; self.accent = accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Theme.Font.headline).foregroundStyle(Theme.ink)
            Text(line).font(Theme.Font.subheadlineRegular).foregroundStyle(Theme.inkSoft)
            Text(accent).font(Theme.Font.footnote).foregroundStyle(Theme.goldText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(Theme.Radius.card)
    }
}

/// Label above value (stacked) or label → value, inside one card.
private struct HostFactsCard: View {
    let facts: [(String, String)]
    var stacked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                VStack(alignment: .leading, spacing: 3) {
                    Text(fact.0)
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                    Text(fact.1)
                        .font(stacked ? Theme.Font.body : Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(Theme.Radius.card)
    }
}

/// "Add photos" tile + picked thumbnails; the first is the cover.
private struct PhotoStrip: View {
    @Binding var items: [PhotosPickerItem]
    @State private var images: [Image] = []

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                PhotosPicker(selection: $items, maxSelectionCount: 12, matching: .images) {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle.angled").font(Theme.Font.title3)
                        Text("Add photos").font(Theme.Font.footnote)
                    }
                    .foregroundStyle(Theme.goldText)
                    .frame(width: 96, height: 72)
                    .background(Theme.brandTint, in: .rect(cornerRadius: 14))
                }
                ForEach(Array((images.isEmpty ? [Image(systemName: "car.fill")] : images).enumerated()),
                        id: \.offset) { i, image in
                    image.resizable().scaledToFill()
                        .frame(width: 96, height: 72)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(alignment: .bottomLeading) {
                            if i == 0 {
                                Text("Cover")
                                    .font(Theme.Font.captionSemibold)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Theme.card, in: .capsule)
                                    .padding(6)
                            }
                        }
                }
            }
            .padding(12)
        }
        .scrollIndicators(.hidden)
        .glassCard(Theme.Radius.group)
        .onChange(of: items) { _, picked in
            Task {
                var loaded: [Image] = []
                for item in picked {
                    if let data = try? await item.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                        loaded.append(Image(uiImage: ui))
                    }
                }
                withAnimation(Theme.smooth) { images = loaded }
            }
        }
    }
}

/// Wrapping toggle chips — features and papers.
private struct FlowChips: View {
    let options: [String]
    @Binding var selection: Set<String>
    var symbol: String? = nil

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let on = selection.contains(option)
                Button {
                    if on { selection.remove(option) } else { selection.insert(option) }
                } label: {
                    HStack(spacing: 5) {
                        if let symbol { Image(systemName: on ? "checkmark.seal.fill" : symbol) }
                        Text(option)
                    }
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(on ? Theme.ink : Theme.inkSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(on ? Theme.brandTint : Theme.fill, in: .capsule)
                }
                .buttonStyle(PressScale(haptic: .tick))
            }
        }
        .animation(Theme.snappy, value: selection)
    }
}

/// Left-to-right wrapping layout for chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { x = 0; y += row + spacing; row = 0 }
            x += size.width + spacing
            row = max(row, size.height)
            maxX = max(maxX, x - spacing)
        }
        return CGSize(width: min(maxX, width), height: y + row)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, row: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += row + spacing; row = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            row = max(row, size.height)
        }
    }
}

private struct MiniPinMap: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(initialPosition: .region(.init(center: coordinate, latitudinalMeters: 900, longitudinalMeters: 900))) {
            Annotation("", coordinate: coordinate) {
                Image(systemName: "mappin.and.ellipse")
                    .font(Theme.Font.title2)
                    .foregroundStyle(Theme.goldText)
            }
        }
        .mapStyle(.standard(emphasis: .muted))
        .frame(height: 120)
        .clipShape(.rect(cornerRadius: Theme.Radius.group))
        .padding(.bottom, 6)
    }
}

private struct ConfirmCheck: View {
    @Binding var isOn: Bool
    let text: LocalizedStringKey

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(Theme.Font.title3)
                    .foregroundStyle(isOn ? Theme.brandSolid : Theme.inkSoft)
                    .contentTransition(.symbolEffect(.replace))
                Text(text)
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .sensoryFeedback(.selection, trigger: isOn)
    }
}

// MARK: - Previews

#Preview("HO01 · Hosting") {
    NavigationStack { HostingScreen(store: .seeded(), router: AppRouter()) }
}

#Preview("HO02 · List your car") {
    NavigationStack { HostListCarScreen(store: .seeded()) }
}

#Preview("HO03 · Booking request") {
    NavigationStack { HostRequestScreen(store: .seeded()) }
}

#Preview("HO07 · Post a transfer") {
    NavigationStack { HostPostTransferScreen(store: .seeded()) }
}

