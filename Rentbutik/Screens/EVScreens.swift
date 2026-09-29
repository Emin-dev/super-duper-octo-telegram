import SwiftUI
import MapKit

// MARK: - EV01 · Select vehicle

/// Map canvas with swipeable glass cards — one per nearby EV. Swiping moves
/// the camera to that car and enlarges its pin. Nothing ticks until Start:
/// no hold countdown in the resting state (Emin, 25 Sep).
struct EVSelectScreen: View {
    let store: Store
    let router: AppRouter
    let initialID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(Session.self) private var session
    @State private var selection: String?
    /// EV01e — the same screen with the card swapped for the delivery panel.
    @State private var delivering: Vehicle?
    @State private var showPlaces = false
    @State private var requested: Vehicle?
    /// EV05 — insurance replaces the card in place.
    @State private var insuranceFor: Vehicle?
    @State private var showPlan = false
    /// EV01d — the with-driver request, same card.
    @State private var driverFlow = false
    @State private var tariff: EVCard.Tariff = .hour
    /// The car we're talking to — "Unlocking…" on its Start button.
    @State private var unlockingID: String?
    @State private var scanning: Vehicle?
    @State private var photosFor: Vehicle?
    /// The day tariff's return time, carried through unlock and photos.
    @State private var rideUntil: Date?
    /// EV07 — Wallet can't cover unlock + hold.
    @State private var paymentFailed = false
    @State private var showWallet = false
    @State private var rideConflict = false

    private var fleet: [Vehicle] { store.vehicles.filter { $0.kind == .electric } }
    private var selected: Vehicle? { fleet.first { $0.id == selection } ?? fleet.first }

    private var placeCoordinate: CLLocationCoordinate2D? {
        store.selectedPlace.map { .init(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var pins: [MapVehiclePin] {
        var result = fleet.compactMap { v -> MapVehiclePin? in
            guard let lat = v.latitude, let lon = v.longitude else { return nil }
            return MapVehiclePin(id: v.id,
                                 coordinate: .init(latitude: lat, longitude: lon),
                                 symbol: "bolt.car.fill",
                                 isSelected: v.id == selected?.id,
                                 isHeld: store.holdUntil(v.id) != nil)
        }
        // EV01e drops a person pin where the car is going.
        if delivering != nil, let placeCoordinate {
            result.append(MapVehiclePin(id: "place", coordinate: placeCoordinate,
                                        symbol: "person.fill", isSelected: true))
        }
        return result
    }

    var body: some View {
        MapCanvas(center: .baku,
                  span: 1800,
                  pins: pins,
                  focus: delivering != nil ? placeCoordinate : selected.flatMap { v in
                      v.latitude.map { CLLocationCoordinate2D(latitude: $0, longitude: v.longitude ?? 0) }
                  },
                  trailingSymbol: nil,
                  // QR lives in the card. The top back shows while the card
                  // has no back of its own, and hides when a sub-panel opens.
                  showsControls: !(delivering != nil || insuranceFor != nil || driverFlow || paymentFailed),
                  insetPanel: false,
                  onSelectPin: { id in
                      guard fleet.contains(where: { $0.id == id }) else { return }
                      withAnimation(Theme.smooth) { selection = id }
                  },
                  onBack: {
                      if delivering != nil || insuranceFor != nil || driverFlow || paymentFailed {
                          withAnimation(Theme.expand) {
                              delivering = nil; insuranceFor = nil; driverFlow = false; paymentFailed = false
                          }
                      } else {
                          dismiss()
                      }
                  }) {
            ZStack(alignment: .bottom) {
                if paymentFailed {
                    PaymentFailedPanel(onAddCard: { showWallet = true },
                                       onBack: { withAnimation(Theme.expand) { paymentFailed = false } })
                        .padding(.horizontal, Theme.Space.screen)
                        .transition(.blurReplace)
                } else if driverFlow {
                    DriverPanel(store: store,
                                onChoosePlace: { showPlaces = true },
                                onFinish: { withAnimation(Theme.expand) { driverFlow = false } },
                                onBack: { withAnimation(Theme.expand) { driverFlow = false } })
                        .padding(.horizontal, Theme.Space.screen)
                        .transition(.blurReplace)
                } else if let vehicle = insuranceFor {
                    InsurancePanel(vehicle: vehicle) {
                        withAnimation(Theme.expand) { insuranceFor = nil }
                    }
                    .padding(.horizontal, Theme.Space.screen)
                    .transition(.blurReplace)
                } else if let vehicle = delivering {
                    DeliverPanel(vehicle: vehicle,
                                 place: store.selectedPlace,
                                 onChoosePlace: { showPlaces = true },
                                 onRequest: {
                                     router.requireVerified(session, holding: vehicle.name) {
                                         requested = vehicle
                                         store.bookingFollowUp(title: String(localized: "Delivery requested"),
                                                               detail: "\(vehicle.name) · about 25 min",
                                                               hostThreadID: "thr-support")
                                         withAnimation(Theme.expand) { delivering = nil }
                                     }
                                 },
                                 onBack: { withAnimation(Theme.expand) { delivering = nil } })
                        .padding(.horizontal, Theme.Space.screen)
                        .transition(.blurReplace)
                } else {
                    // The day tariff needs the calendar: that car leaves the
                    // carousel as one card, never clipped (U1).
                    if tariff == .day, let vehicle = selected {
                        SingleMapCard { evCard(for: vehicle) }
                            .transition(.opacity.combined(with: .scale(0.98, anchor: .bottom)))
                    } else {
                        VehicleCarousel(items: fleet, selection: $selection) { vehicle in
                            evCard(for: vehicle)
                        }
                        .transition(.blurReplace)
                    }
                }
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .animation(Theme.expand, value: tariff)
        .onAppear { if selection == nil { selection = initialID } }
        .sheet(isPresented: $showPlaces) { PlacesSheet(store: store) }
        .sheet(isPresented: $showPlan) { EVPlanSheet(store: store) }
        .sheet(isPresented: $showWallet) { WalletSheet(store: store) }
        .fullScreenCover(item: $scanning) { vehicle in
            ScanToUnlockView(vehicleName: vehicle.name,
                             onCancel: { scanning = nil },
                             onUnlock: {
                                 scanning = nil
                                 start(vehicle, alreadyUnlocked: true)
                             })
        }
        .fullScreenCover(item: $photosFor) { vehicle in
            CaptureStagesView(heading: "Pre-trip photos",
                              stages: EVSelectScreen.preTripStages,
                              hint: "Keep the whole car in the frame.",
                              onCancel: { photosFor = nil },
                              onDone: {
                                  photosFor = nil
                                  guard store.startRide(vehicleID: vehicle.id, name: vehicle.name,
                                                        kind: .electric, until: rideUntil,
                                                        tariff: RideTariff(rawValue: tariff.rawValue) ?? .hour) else {
                                      rideConflict = true
                                      return
                                  }
                                  router.push(.evActiveTrip(vehicleID: vehicle.id))
                              })
        }
        .alert("Finish your current trip first", isPresented: $rideConflict) {
            Button("View trips") { router.tab = .trips }
            Button("OK", role: .cancel) {}
        } message: { Text("Complete the active trip or settle its outstanding payment before starting another.") }
        .sensoryFeedback(.warning, trigger: paymentFailed)
        .sensoryFeedback(.selection, trigger: delivering?.id)
        .alert("Delivery requested", item: $requested) { _ in
            Button("OK", role: .cancel) {}
        } message: { vehicle in
            Text("\(vehicle.name) is on its way to \(store.selectedPlace?.name ?? "you") — about 25 min.")
        }
    }
}

extension EVSelectScreen {
    func evCard(for vehicle: Vehicle) -> some View {
        EVCard(vehicle: vehicle,
               tariff: $tariff,
               onDeliver: { withAnimation(Theme.expand) { delivering = vehicle } },
               onInsurance: { withAnimation(Theme.expand) { insuranceFor = vehicle } },
               onPlan: { showPlan = true },
               onDriver: { withAnimation(Theme.expand) { driverFlow = true } },
               onMessage: { router.push(.thread(threadID: "thr-support")) },
               onDirections: { openWalkingDirections(to: vehicle) },
               onScan: { scanning = vehicle },
               holdUntil: store.holdUntil(vehicle.id),
               onBook: {
                   router.requireVerified(session, holding: vehicle.name) {
                       withAnimation(Theme.smooth) { store.hold(vehicle) }
                   }
               },
               onCancelHold: { withAnimation(Theme.smooth) { store.releaseHold() } },
               isUnlocking: unlockingID == vehicle.id) { dates in
            start(vehicle, alreadyUnlocked: false, until: dates?.dropOff)
        }
    }

    /// EV02 — five photos before the first metre.
    static let preTripStages: [CaptureStage] = [
        .init(id: "front", title: "Front of the car", detail: "1 of 5 · Front of the car", short: "Front", symbol: "car.front.waves.up.fill"),
        .init(id: "rear", title: "Rear of the car", detail: "2 of 5 · Rear", short: "Rear", symbol: "car.rear.fill"),
        .init(id: "left", title: "Left side", detail: "3 of 5 · Left", short: "Left", symbol: "car.side.fill"),
        .init(id: "right", title: "Right side", detail: "4 of 5 · Right", short: "Right", symbol: "car.side.fill"),
        .init(id: "selfie", title: "Selfie by the car", detail: "5 of 5 · You next to the car", short: "Selfie", symbol: "person.crop.circle.fill", aspect: 0.8),
    ]

    /// Gate → Wallet check (EV07) → ~3 s talking to the car → EV02 photos.
    func start(_ vehicle: Vehicle, alreadyUnlocked: Bool, until: Date? = nil) {
        guard store.activeTrip == nil, !store.trips.contains(where: { $0.status == .paymentPending }) else {
            rideConflict = true
            return
        }
        rideUntil = until
        // Sign in appears here, at the first trip — never earlier.
        router.requireVerified(session, holding: vehicle.name) {
            let needed = Store.evUnlockFee
            // EV07 only when neither Wallet nor the card can cover it (B16).
            guard store.canCover(needed) else {
                withAnimation(Theme.expand) { paymentFailed = true }
                return
            }
            Task {
                if !alreadyUnlocked {
                    withAnimation(Theme.snappy) { unlockingID = vehicle.id }
                    try? await Task.sleep(for: .seconds(Double.random(in: 2.8...3.8)))
                    withAnimation(Theme.snappy) { unlockingID = nil }
                }
                Haptic.ignition.fire()
                photosFor = vehicle
            }
        }
    }

    /// Real Apple Maps walking directions to the car.
    func openWalkingDirections(to vehicle: Vehicle) {
        guard let lat = vehicle.latitude, let lon = vehicle.longitude else { return }
        let item = MKMapItem(location: CLLocation(latitude: lat, longitude: lon), address: nil)
        item.name = vehicle.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

/// EV07 · Payment failed — in place of the card.
private struct PaymentFailedPanel: View {
    let onAddCard: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CardBackButton(action: onBack)
                Image(systemName: "creditcard.trianglebadge.exclamationmark")
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.danger)
                    .symbolEffect(.wiggle, options: .nonRepeating)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment failed")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text("Your wallet is empty and Visa •••• 4242 was declined.")
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            RentbutikPrimaryButton("Add a new card", symbol: "plus", action: onAddCard)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassMapCard()
    }
}

/// EV01e · Deliver to me — When / Deliver to / Car, then Request delivery.
private struct DeliverPanel: View {
    let vehicle: Vehicle
    let place: SavedPlace?
    let onChoosePlace: () -> Void
    let onRequest: () -> Void
    let onBack: () -> Void

    @State private var taps = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
            CardBackButton(action: onBack)
            VStack(alignment: .leading, spacing: 2) {
                Text("Deliver the car to me")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                Text("We bring \(vehicle.name) to your door.")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            }

            VStack(spacing: 0) {
                row("When") {
                    Text("Now · about 25 min").foregroundStyle(Theme.inkSoft)
                }
                Divider().overlay(Theme.hairline)
                Button(action: onChoosePlace) {
                    row("Deliver to") {
                        HStack(spacing: 6) {
                            Text(verbatim: "\(place?.name ?? "") · \(place?.address ?? "")")
                                .foregroundStyle(Theme.inkSoft)
                                .lineLimit(1)
                                .contentTransition(.opacity)
                            Image(systemName: "chevron.right")
                                .font(Theme.Font.footnote)
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                Divider().overlay(Theme.hairline)
                row("Car") {
                    HStack(spacing: 6) {
                        Text(verbatim: "\(vehicle.name) · \(vehicle.batteryPercent ?? 0) %")
                            .foregroundStyle(Theme.inkSoft)
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Theme.goldText)
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(Theme.fill.opacity(0.7), in: .rect(cornerRadius: Theme.Radius.group))

            Button {
                taps += 1
                onRequest()
            } label: {
                Text("Request delivery · \(Decimal(5), format: .currency(code: Currency.code).precision(.fractionLength(0)))")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .sensoryFeedback(.impact(weight: .medium), trigger: taps)
        }
        .padding(16)
        .glassMapCard()
    }

    private func row<Trailing: View>(_ label: LocalizedStringKey,
                                     @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.ink)
            Spacer(minLength: 8)
            trailing()
        }
        .font(Theme.Font.body)
        .frame(minHeight: 46)
    }
}

/// Card / Glass map — EV01's card content.
private struct EVCard: View {
    enum Tariff: String, CaseIterable, Identifiable {
        case minute, hour, day, driver
        var id: String { rawValue }
    }

    let vehicle: Vehicle
    @Binding var tariff: Tariff
    var onDeliver: () -> Void = {}
    var onInsurance: () -> Void = {}
    var onPlan: () -> Void = {}
    var onDriver: () -> Void = {}
    var onMessage: () -> Void = {}
    var onDirections: () -> Void = {}
    var onScan: () -> Void = {}
    /// EV01's "🕒 14:59" free hold.
    var holdUntil: Date? = nil
    var onBook: () -> Void = {}
    var onCancelHold: () -> Void = {}
    /// "Unlocking…" while the phone talks to the car.
    var isUnlocking = false
    /// `nil` for a pay-as-you-go ride, dates for the ₼60/day tariff.
    let onStart: (RentalDates?) -> Void

    @State private var starts = 0
    @State private var moreOptions = false
    /// The ride starts now; the calendar picks the return (B03).
    @State private var dates = RentalDates.fromNow

    private func money(_ v: Decimal, _ digits: Int = 0) -> String {
        v.formatted(.currency(code: Currency.code).precision(.fractionLength(digits)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(holdUntil == nil ? vehicle.name : String(localized: "\(vehicle.name) · held"))
                        .font(Theme.Font.title2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.opacity)
                    // Tapping the walk opens Apple Maps walking directions (N2).
                    Button(action: onDirections) {
                        Text("\(vehicle.walkMinutes ?? 1) min walk · \(vehicle.rangeKm ?? 0) km")
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Walking directions in Maps")
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 4)
                BatteryRing(percent: vehicle.batteryPercent ?? 0, diameter: 44)
                Button(action: onMessage) { Image(systemName: "message.fill") }
                    .buttonStyle(.rentbutik)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .accessibilityLabel("Message support")
            }

            // Native segmented picker for the four tariffs.
            Picker("Tariff", selection: $tariff) {
                Text(verbatim: "\(money(vehicle.pricePerMinute ?? 0.25, 2))/min").tag(Tariff.minute)
                Text(verbatim: "\(money(vehicle.pricePerHour ?? 15))/hour").tag(Tariff.hour)
                Text(verbatim: "\(money(60))/day").tag(Tariff.day)
                Text("Driver").tag(Tariff.driver)
            }
            .pickerStyle(.segmented)
            .sensoryFeedback(.selection, trigger: tariff)
            // "Driver" is a different product — EV01d takes over the card.
            .onChange(of: tariff) { _, new in
                guard new == .driver else { return }
                onDriver()
                tariff = .hour
            }

            if tariff == .day {
                RangeCalendar(dates: $dates, startLocked: true)
                    .transition(.opacity.combined(with: .scale(0.97, anchor: .top)))
            } else {
                Text("\(money(1)) unlock · pay when your ride ends")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }

            DisclosureGroup("Options & cover", isExpanded: $moreOptions) {
                VStack(alignment: .leading, spacing: 14) {
                    Button("Insurance & fines", action: onInsurance)
                    deliverLabel
                    planLabel
                }
                .font(Theme.Font.subheadlineSemibold)
                .padding(.top, 8)
            }
            .font(Theme.Font.subheadlineSemibold)
            .tint(Theme.goldText)

            HStack(spacing: 10) {
                ScanButton(action: onScan)

                HoldButton(until: holdUntil, title: "Book · 15 min", onBook: onBook, onCancel: onCancelHold)

                Button {
                    starts += 1
                    onStart(tariff == .day ? dates : nil)
                } label: {
                    HStack(spacing: 8) {
                        if isUnlocking {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "bolt.fill").symbolEffect(.bounce, value: starts)
                        }
                        Text(isUnlocking ? String(localized: "Unlocking…")
                             : tariff == .day ? String(localized: "Start · \(money(RidePricing.quote(tariff: .day, elapsed: 0, booked: dates.dropOff.timeIntervalSince(dates.pickUp)).total))")
                             : String(localized: "Start"))
                            .contentTransition(.opacity)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 4)
                }
                .disabled(isUnlocking)
                .accessibilityIdentifier("ev.start.\(vehicle.id)")
                // Start takes its own width first; Book fills the rest.
                .layoutPriority(1)
                .buttonStyle(.rentbutik)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }
        }
        .padding(16)
        .glassMapCard()
    }
}

extension EVCard {
    fileprivate var deliverLabel: some View {
        Button(action: onDeliver) {
            Label("Deliver to me · \(money(5))", systemImage: "location.fill").lineLimit(1)
        }
        .buttonStyle(.plain)
    }
    fileprivate var planLabel: some View {
        Button(action: onPlan) {
            Label("EV plan · −30 %", systemImage: "tag.fill").lineLimit(1)
        }
        .buttonStyle(.plain)
    }
}

/// Title first, chevron after — "Insurance & fines ›".
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}

// MARK: - EV03 · Active ride  (EV03a locked · EV06 extend · EV04 summary)

/// One map screen, one glass card. Its states are the file's "(state)"
/// frames — they morph in place and never push:
/// riding ⇄ locked, → extend (EV06), → ride complete (EV04).
struct EVActiveTripScreen: View {
    let vehicle: Vehicle
    let store: Store
    let router: AppRouter

    enum Phase: Equatable { case riding, extending, complete(Trip) }

    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .riding
    @State private var isLocked = false
    @State private var showReport = false

    @State private var showPayment = false
    @State private var takingReturnPhotos = false
    private var trip: Trip? {
        store.trips.first { $0.vehicleID == vehicle.id && ($0.status == .ongoing || $0.status == .paymentPending) }
    }

    var body: some View {
        MapCanvas(center: vehicleCoordinate,
                  span: 1200,
                  pins: [MapVehiclePin(id: vehicle.id, coordinate: vehicleCoordinate,
                                       symbol: "bolt.car.fill", isSelected: true)],
                  trailingSymbol: nil,
                  onBack: { dismiss() }) {
            ZStack(alignment: .bottom) {
                switch phase {
                case .riding:
                    if let trip, trip.status == .paymentPending {
                        PaymentRecoveryCard(total: trip.total,
                                            onPayment: { showPayment = true },
                                            onRetry: settle)
                    } else if let trip {
                        RidingPanel(vehicle: vehicle, trip: trip, store: store,
                                    isLocked: $isLocked,
                                    onExtend: { withAnimation(Theme.expand) { phase = .extending } },
                                    onChat: { router.push(.thread(threadID: "thr-support")) },
                                    onReport: { showReport = true },
                                    onEnd: end)
                            .transition(.blurReplace)
                    }
                case .extending:
                    if let trip {
                        ExtendPanel(trip: trip, store: store,
                                    onAdd: {
                                        store.extendRide(id: trip.id)
                                        withAnimation(Theme.expand) { phase = .riding }
                                    },
                                    onBack: { withAnimation(Theme.expand) { phase = .riding } })
                            .transition(.blurReplace)
                    }
                case .complete(let done):
                    SummaryPanel(trip: done, vehicle: vehicle) {
                        router.popToRoot(router.tab)
                    }
                    .transition(.blurReplace)
                }
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPayment) { WalletSheet(store: store, initialRoute: .methods) }
        .fullScreenCover(isPresented: $takingReturnPhotos) {
            CaptureStagesView(heading: "Return photos", stages: ReturnPhotoStages.all,
                              hint: "Park in the permitted return area and photograph the car.",
                              onCancel: { takingReturnPhotos = false },
                              onDone: { takingReturnPhotos = false; settle() })
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isLocked)
        .confirmationDialog("Report a problem", isPresented: $showReport, titleVisibility: .visible) {
            ForEach(["Damage on the car", "Low battery", "Can’t lock the car", "Something else"], id: \.self) { issue in
                Button(LocalizedStringKey(issue)) { report(issue) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var vehicleCoordinate: CLLocationCoordinate2D {
        vehicle.latitude.map { .init(latitude: $0, longitude: vehicle.longitude ?? 0) } ?? .baku
    }

    private func end() { takingReturnPhotos = true }

    private func settle() {
        guard let trip else { return }
        if case .paid = store.endTrip(id: trip.id),
           let done = store.trips.first(where: { $0.id == trip.id }) {
            withAnimation(Theme.expand) { phase = .complete(done) }
        }
    }

    /// Reports go to Support as a real message — the on-device agent answers.
    private func report(_ issue: String) {
        store.send("\(issue) — \(vehicle.name)", in: "thr-support")
        router.push(.thread(threadID: "thr-support"))
    }
}

/// EV03 / EV03a — status, live price, lock + extend, chat, report, slide to end.
private struct RidingPanel: View {
    let vehicle: Vehicle
    let trip: Trip
    let store: Store
    @Binding var isLocked: Bool
    let onExtend: () -> Void
    let onChat: () -> Void
    let onReport: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isLocked ? Theme.inkSoft : Theme.brandSolid)
                    .frame(width: 8, height: 8)
                Text(isLocked ? "Car locked" : "Riding now")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.opacity)
                Spacer(minLength: 8)
                Text(verbatim: "\(vehicle.name) · ABC123")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }

            // The price ticks as hours start — TimelineView, no Combine timer.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.rideCost(trip, at: context.date),
                         format: .currency(code: Currency.code).precision(.fractionLength(2)))
                        .font(Theme.Font.largeTitle)
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                        .animation(Theme.snappy, value: store.rideCost(trip, at: context.date))
                    Text(trip.tariff == .minute ? "Minute tariff · plan minutes applied first" : "Hour/day tariff · ₼60 cap per 24 hours + ₼1 unlock")
                        .font(Theme.Font.subheadlineRegular)
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(Theme.snappy) { isLocked.toggle() }
                } label: {
                    Label(isLocked ? "Locked" : "Unlocked",
                          systemImage: isLocked ? "lock.fill" : "lock.open.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass(.regular.tint(isLocked ? Theme.fill : Theme.brandTint)))
                .foregroundStyle(isLocked ? Theme.ink : Theme.goldText)

                Button(action: onExtend) {
                    Label("Extend", systemImage: "clock.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.rentbutik)
                .foregroundStyle(Theme.ink)
                .disabled(trip.tariff == .minute)
            }
            .font(Theme.Font.subheadlineSemibold)
            .buttonBorderShape(.capsule)
            .controlSize(.large)

            HStack(spacing: 10) {
                Button("Chat with support", systemImage: "message.fill", action: onChat)
                    .foregroundStyle(Theme.goldText)
                    .buttonStyle(.glass(.regular.tint(Theme.brandTint)))
                Button("Report a problem", systemImage: "exclamationmark.triangle.fill", action: onReport)
                    .foregroundStyle(Theme.danger)
                    .buttonStyle(.rentbutik)
                SlideToEnd(onEnd: onEnd)
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .controlSize(.large)
        }
        .padding(16)
        .glassMapCard()
    }
}

/// "› Slide to end" — a drag across a glass capsule. There is no native
/// slide-to-confirm control, so this is the one small gesture we own.
/// Releasing early springs back; VoiceOver gets a plain button action.
private struct SlideToEnd: View {
    var title: LocalizedStringKey = "Slide to end"
    var symbol = "chevron.right"
    var symbolColor: Color = Theme.ink
    let onEnd: () -> Void

    @State private var offset: CGFloat = 0
    @State private var done = false
    private let knob: CGFloat = 44

    var body: some View {
        GeometryReader { geo in
            let travel = max(geo.size.width - knob - 8, 1)
            ZStack(alignment: .leading) {
                Text(title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, knob / 2)
                    .opacity(1 - Double(offset / travel) * 1.4)
                Image(systemName: symbol)
                    .font(Theme.Font.headline)
                    .foregroundStyle(symbolColor)
                    .frame(width: knob, height: knob)
                    .glassEffect(.regular.tint(Theme.card.opacity(0.95)).interactive(), in: .circle)
                    .shadow(color: Theme.Shadow.control.color, radius: Theme.Shadow.control.radius,
                            y: Theme.Shadow.control.y)
                    .padding(4)
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { offset = min(max($0.translation.width, 0), travel) }
                            .onEnded { _ in
                                if offset > travel * 0.85 {
                                    offset = travel
                                    done = true
                                    onEnd()
                                } else {
                                    withAnimation(Theme.bouncy) { offset = 0 }
                                }
                            })
            }
            .frame(height: knob + 8)
            .glassEffect(.regular.tint(Theme.card.opacity(0.7)), in: .capsule)
        }
        .frame(height: knob + 8)
        .sensoryFeedback(.success, trigger: done)
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onEnd() }
    }
}

/// EV06 · Add an hour — same card, the ride keeps running.
private struct ExtendPanel: View {
    let trip: Trip
    let store: Store
    let onAdd: () -> Void
    let onBack: () -> Void

    private func money(_ v: Decimal) -> String {
        v.formatted(.currency(code: Currency.code).precision(.fractionLength(0)))
    }

    var body: some View {
        let extended = Trip(id: trip.id, vehicleName: trip.vehicleName, vehicleKind: trip.vehicleKind,
                            status: trip.status, startDate: trip.startDate,
                            endDate: trip.endDate.addingTimeInterval(3600),
                            total: trip.total, photoName: trip.photoName)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CardBackButton(action: onBack)
                Text("Add an hour")
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
            }
            Text("New end time · \(extended.endDate.formatted(.dateTime.hour().minute()))")
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.ink)
            Text("\(money(Store.evHourRate)) extra · New ride total \(money(store.rideCost(extended)))")
                .font(Theme.Font.subheadlineRegular)
                .foregroundStyle(Theme.ink)
            Text("Your ride continues while you extend it.")
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
            RentbutikPrimaryButton("Add 1 hour · \(money(Store.evHourRate))", action: onAdd)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassMapCard()
    }
}

/// EV04 · Ride complete — duration, distance, total, and the Wallet charge.
private struct SummaryPanel: View {
    let trip: Trip
    let vehicle: Vehicle
    let onDone: () -> Void

    private var minutes: Int { max(Int(trip.endDate.timeIntervalSince(trip.startDate) / 60), 1) }
    /// City driving averages ~12 km an hour in EV04.
    private var km: Double { Double(minutes) * 12.4 / 60 }

    private func money(_ v: Decimal) -> String {
        v.formatted(.currency(code: Currency.code).precision(.fractionLength(2)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ride complete")
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                Text(verbatim: "\(vehicle.name) · Sahil → 28 May street")
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
            }

            HStack(spacing: 8) {
                stat("\(minutes) min", "Duration")
                stat(km.formatted(.number.precision(.fractionLength(1))) + " km", "Distance")
                stat(money(trip.total), "Total")
            }

            VStack(spacing: 8) {
                line("Ride · hour tariff", money(trip.total - Store.evUnlockFee), bold: false)
                line("Unlock", money(Store.evUnlockFee), bold: false)
                line("Total paid from Wallet", money(trip.total), bold: true)
            }

            RentbutikPrimaryButton("Done", action: onDone)
        }
        .padding(16)
        .glassMapCard()
    }

    private func stat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.chip))
    }

    private func line(_ label: LocalizedStringKey, _ value: String, bold: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
        .font(bold ? Theme.Font.subheadlineSemibold : Theme.Font.subheadlineRegular)
        .foregroundStyle(bold ? Theme.ink : Theme.inkSoft)
    }
}

#Preview("EV01 · Select vehicle") {
    NavigationStack {
        EVSelectScreen(store: .seeded(), router: AppRouter(), initialID: "veh-ev-6")
    }
    .environment(Session())
}

#Preview("EV01h · Held") {
    let store = Store.seeded()
    if let ev = store.vehicles.first(where: { $0.id == "veh-ev-6" }) { store.hold(ev) }
    return NavigationStack {
        EVSelectScreen(store: store, router: AppRouter(), initialID: "veh-ev-6")
    }
    .environment(Session())
}

#Preview("EV03 · Active ride") {
    let store = Store.seeded()
    store.startRide(vehicleID: "veh-ev-6", name: "Rentbutik EV 6", kind: .electric)
    return NavigationStack {
        EVActiveTripScreen(vehicle: store.vehicles.first { $0.id == "veh-ev-6" }!,
                           store: store, router: AppRouter())
    }
}

// MARK: - EV05 · Insurance & fines  (in place of the vehicle card)

private struct InsurancePanel: View {
    let vehicle: Vehicle
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                CardBackButton(action: onBack)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insurance & fines")
                        .font(Theme.Font.title3)
                        .foregroundStyle(Theme.ink)
                    Text(verbatim: "\(vehicle.name) · ABC123")
                        .font(Theme.Font.subheadlineRegular)
                        .foregroundStyle(Theme.ink)
                }
            }
            section("Collision & theft",
                    "₼500 excess per claim. Coverage is subject to the rental agreement.")
            section("Parking & additional charges",
                    "Missing an AzParking sign photo: ₼20. Traffic and parking fines are charged at cost.")
            RentbutikPrimaryButton("Back to vehicle", action: onBack)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassMapCard()
    }

    private func section(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.ink)
            Text(body)
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

// MARK: - EV08 · EV plan  (EV08b weekly · EV08c yearly · EV08a active)

struct EVPlanSheet: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var period: EVPlanPeriod = .monthly
    @State private var choice: EVPlanOption = .suggested(for: .monthly)
    @State private var confirmCancel = false
    @State private var bought = 0

    private func money(_ v: Decimal, _ digits: Int = 0) -> String {
        v.formatted(.currency(code: Currency.code).precision(.fractionLength(digits)))
    }

    var body: some View {
        VStack(spacing: 14) {
            SheetHeader(title: "EV plan") { dismiss() }
            if let plan = store.evPlan {
                active(plan).transition(.blurReplace)
            } else {
                picker.transition(.blurReplace)
            }
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .animation(Theme.expand, value: store.evPlan)
        .fittedSheet()
        .sensoryFeedback(.selection, trigger: period)
        .sensoryFeedback(.selection, trigger: choice)
        .sensoryFeedback(.success, trigger: bought)
        .alert("Cancel plan?", isPresented: $confirmCancel) {
            Button("Cancel plan", role: .destructive) { store.evPlan = nil }
            Button("Keep plan", role: .cancel) {}
        } message: {
            Text("Unused minutes are lost. You go back to pay-as-you-go.")
        }
    }

    private var picker: some View {
        VStack(spacing: 12) {
            Text("The more minutes you take, the less each minute costs.")
                .font(Theme.Font.subheadlineRegular)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)

            Picker("Period", selection: $period) {
                Text("Weekly").tag(EVPlanPeriod.weekly)
                Text("Monthly").tag(EVPlanPeriod.monthly)
                Text("Yearly").tag(EVPlanPeriod.yearly)
            }
            .pickerStyle(.segmented)
            .onChange(of: period) { _, p in
                withAnimation(Theme.snappy) { choice = .suggested(for: p) }
            }

            VStack(spacing: 8) {
                ForEach(EVPlanOption.options(for: period)) { option in
                    Button {
                        withAnimation(Theme.snappy) { choice = option }
                    } label: {
                        row(option, selected: option == choice)
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(Theme.smooth, value: period)

            HStack {
                Text("You save vs pay-as-you-go")
                Spacer()
                Text(money(choice.saving))
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
            }
            .font(Theme.Font.body)
            .foregroundStyle(Theme.ink)

            RentbutikPrimaryButton("Take \(choice.minutes.formatted()) minutes · \(money(choice.price))") {
                if store.takePlan(choice) { bought += 1 } else { Haptic.error.fire() }
            }

            Text("Paid from your Wallet, then your card. Package minutes go first; unused minutes expire at the end of the period.")
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private func row(_ option: EVPlanOption, selected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(option.minutes.formatted()) minutes")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                Text("For \(option.period.days) days")
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(money(option.price))
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.goldText)
                    Text(money(option.list, option.list == option.list.rounded0 ? 0 : 2))
                        .font(Theme.Font.subheadlineRegular)
                        .foregroundStyle(Theme.inkSoft)
                        .strikethrough()
                }
                Text("\(money(option.perMinute, 2)) / min")
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.chip))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.chip)
                .strokeBorder(Theme.brandSolid, lineWidth: selected ? 2 : 0)
        }
        .contentShape(.rect)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// EV08a — the plan in use.
    private func active(_ plan: EVPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupedCard {
                GroupedRow(label: "Plan") {
                    Text("\(plan.option.period == .monthly ? String(localized: "Monthly") : plan.option.period == .weekly ? String(localized: "Weekly") : String(localized: "Yearly")) · until \(plan.until.formatted(.dateTime.day().month(.abbreviated)))")
                        .foregroundStyle(Theme.inkSoft)
                }
                GroupedRow(label: "Used this month") {
                    Text("\(plan.usedMinutes) of \(plan.option.minutes) min").foregroundStyle(Theme.inkSoft)
                }
                GroupedRow(label: "Saved so far", showsDivider: false) {
                    Text(money(plan.option.perMinute == 0 ? 0 : (Decimal(0.25) - plan.option.perMinute) * Decimal(plan.usedMinutes), 2))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: Double(plan.usedMinutes), total: Double(plan.option.minutes))
                    .tint(Theme.brandSolid)
                Text("\(plan.usedMinutes) of \(plan.option.minutes) min used")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.horizontal, 2)
            RentbutikPrimaryButton("Cancel plan", destructive: true) { confirmCancel = true }
            Text("Minutes reset on the \(Calendar.current.component(.day, from: plan.until))th. Unused minutes don’t roll over.")
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

private extension Decimal {
    var rounded0: Decimal {
        var v = self, r = Decimal()
        NSDecimalRound(&r, &v, 0, .plain)
        return r
    }
}

#Preview("EV08 · EV plan") {
    // Sheets snapshot blank in previews, so show the content itself.
    EVPlanSheet(store: .seeded()).background(Theme.background)
}

// MARK: - EV01d · With driver  (d2 accepted · d3 on the way · d4 arrived)

/// The request moves through its states on timers, like a live dispatch.
private struct DriverPanel: View {
    let store: Store
    let onChoosePlace: () -> Void
    let onFinish: () -> Void
    /// Back out of the request form to the vehicle card.
    var onBack: () -> Void = {}

    enum Step: Equatable { case form, searching, accepted, onTheWay, arrived }

    @State private var step: Step = .form
    @State private var passengers = 2
    @State private var rating = 0
    @State private var ticks = 0

    private let price: Decimal = 35
    private var destination: String { store.selectedPlace?.name ?? String(localized: "Heydar Aliyev Airport") }

    private func money(_ v: Decimal, _ d: Int = 0) -> String {
        v.formatted(.currency(code: Currency.code).precision(.fractionLength(d)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch step {
            case .form, .searching: form
            case .accepted: accepted
            case .onTheWay: onTheWay
            case .arrived: arrived
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassMapCard()
        .animation(Theme.expand, value: step)
        .sensoryFeedback(.success, trigger: ticks)
        .task(id: step) { await advance() }
    }

    /// Demo dispatch: searching → accepted → on the way → arrived.
    private func advance() async {
        let wait: Double
        let next: Step
        switch step {
        case .searching: wait = 2.2; next = .accepted
        case .accepted:  wait = 6;   next = .onTheWay
        case .onTheWay:  wait = 8;   next = .arrived
        default: return
        }
        guard (try? await Task.sleep(for: .seconds(wait))) != nil else { return }
        if next == .arrived {
            store.charge(price, label: String(localized: "Ride with a driver · EV 3"), symbol: "person.fill")
        }
        withAnimation(Theme.expand) { step = next }
        ticks += 1
    }

    // EV01d
    private var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
            CardBackButton(action: onBack)
            VStack(alignment: .leading, spacing: 2) {
                Text("Electric car with a driver")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                Text("A Rentbutik driver picks you up in an EV.")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            }
            VStack(spacing: 0) {
                HStack {
                    Text("Passengers")
                    Spacer()
                    Text("\(passengers)").foregroundStyle(Theme.inkSoft).contentTransition(.numericText())
                    Stepper("Passengers", value: $passengers, in: 1...4)
                        .labelsHidden()
                }
                .frame(minHeight: 46)
                Divider().overlay(Theme.hairline)
                Button(action: onChoosePlace) {
                    HStack {
                        Text("Where to").foregroundStyle(Theme.ink)
                        Spacer()
                        Text(destination).foregroundStyle(Theme.inkSoft).lineLimit(1)
                        Image(systemName: "chevron.right").font(Theme.Font.footnote).foregroundStyle(Theme.inkSoft)
                    }
                    .frame(minHeight: 46)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                Divider().overlay(Theme.hairline)
                HStack {
                    Text("Pickup")
                    Spacer()
                    Text("Your pin on the map").foregroundStyle(Theme.inkSoft)
                    Image(systemName: "mappin.and.ellipse").foregroundStyle(Theme.goldText)
                }
                .frame(minHeight: 46)
            }
            .font(Theme.Font.body)
            .padding(.horizontal, 14)
            .background(Theme.fill.opacity(0.7), in: .rect(cornerRadius: Theme.Radius.group))
            .sensoryFeedback(.selection, trigger: passengers)

            Button {
                withAnimation(Theme.snappy) { step = .searching }
            } label: {
                HStack(spacing: 8) {
                    if step == .searching { ProgressView().controlSize(.small) }
                    Text(step == .searching ? "Finding a driver…" : "Request driver · about \(money(price))")
                        .contentTransition(.opacity)
                }
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(step == .searching)
        }
    }

    // EV01d2
    private var accepted: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(verbatim: "Accepted · Rashad ★ 4.9")
            } icon: {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.success)
            }
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.brandTint, in: .capsule)
            Text("Rentbutik EV 3 · about 5 min away")
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.ink)
            Text("\(passengers) passengers · to \(destination) · 10-AB-123")
                .font(Theme.Font.subheadlineRegular)
                .foregroundStyle(Theme.inkSoft)
            SlideToEnd(title: "Slide to cancel request", symbol: "xmark", symbolColor: Theme.danger) {
                withAnimation(Theme.expand) { step = .form }
            }
        }
    }

    // EV01d3
    private var onTheWay: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("On the way")
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
            Text("Arrive around \(Date.now.addingTimeInterval(32 * 60).formatted(.dateTime.hour().minute()))")
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.ink)
            Text(verbatim: "EV 3 · Rashad · to \(destination) · \(money(price))")
                .font(Theme.Font.subheadlineRegular)
                .foregroundStyle(Theme.inkSoft)
            ShareLink(item: "I’m on my way to \(destination) with Rentbutik — arriving around \(Date.now.addingTimeInterval(32 * 60).formatted(.dateTime.hour().minute())).") {
                Label("Share trip", systemImage: "square.and.arrow.up")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
    }

    // EV01d4
    private var arrived: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("You have arrived")
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                Text(verbatim: "Rentbutik EV 3 · Rashad · 32 min")
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack(spacing: 8) {
                stat("32 min", "Duration")
                stat(money(price, 2), "Paid")
                stat("24 km", "Distance")
            }
            Text("Paid from Wallet. The receipt is in Trips.")
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
            HStack {
                ShareLink(item: "Rentbutik receipt · EV 3 with Rashad · \(money(price, 2))") {
                    Label("Receipt", systemImage: "square.and.arrow.up")
                        .font(Theme.Font.subheadlineSemibold)
                        .foregroundStyle(Theme.ink)
                }
                .buttonStyle(.glass(.regular.tint(Theme.fill)))
                .buttonBorderShape(.capsule)
                Spacer()
                Button("Book again", systemImage: "arrow.clockwise") {
                    withAnimation(Theme.expand) { step = .form }
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(Theme.ink)
                .buttonStyle(.glass(.regular.tint(Theme.fill)))
                .buttonBorderShape(.circle)
            }
            HStack {
                Text("Rate your driver")
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { n in
                        Button { rating = n } label: {
                            Image(systemName: n <= rating ? "star.fill" : "star")
                                .font(Theme.Font.title3)
                                .foregroundStyle(n <= rating ? Theme.goldText : Theme.inkSoft)
                                .contentTransition(.symbolEffect(.replace))
                                .symbolEffect(.bounce, value: n <= rating)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(n) stars")
                    }
                }
                .sensoryFeedback(.selection, trigger: rating)
            }
            RentbutikPrimaryButton("Done", action: onFinish)
        }
    }

    private func stat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Theme.Font.headline).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.8)
            Text(label).font(Theme.Font.footnoteRegular).foregroundStyle(Theme.inkSoft)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: .rect(cornerRadius: Theme.Radius.chip))
    }
}

