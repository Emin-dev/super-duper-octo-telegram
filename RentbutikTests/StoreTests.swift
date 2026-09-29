import XCTest
@testable import Rentbutik

@MainActor
final class StoreTests: XCTestCase {
    private func freshStore() -> Store {
        let store = Store.seeded()
        store.trips = []
        store.ledger = []
        store.bookedRecords = []
        store.walletBalance = 200
        return store
    }

    private func snapshotURL() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
        return folder.appendingPathComponent("snapshot.json")
    }

    #if DEBUG
    func testFreshLiveStoreHasNoFabricatedTripsOrTransactions() async throws {
        let store = Store.live(snapshotURL: try snapshotURL())
        XCTAssertNil(store.activeTrip)
        XCTAssertTrue(store.trips.isEmpty)
        XCTAssertTrue(store.bookedRecords.isEmpty)
        XCTAssertTrue(store.ledger.isEmpty)
        XCTAssertTrue(store.transactions.isEmpty)
        XCTAssertTrue(store.notifications.isEmpty)
    }

    func testSecondRideIsBlockedWhileOneIsActive() async {
        let store = freshStore()
        XCTAssertTrue(store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric))
        XCTAssertFalse(store.startRide(vehicleID: "veh-ev-3", name: "EV 3", kind: .electric))
        XCTAssertEqual(store.trips.count, 1)
        XCTAssertEqual(store.activeTrip?.vehicleID, "veh-ev-6")
    }

    func testEndRideChargesOnceAndClearsActiveTrip() async throws {
        let store = freshStore()
        store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric)
        let id = try XCTUnwrap(store.activeTrip?.id)
        guard case .paid = store.endTrip(id: id) else { return XCTFail("Expected a paid ride") }
        XCTAssertNil(store.activeTrip)
        XCTAssertEqual(store.trips.first?.status, .completed)
        XCTAssertEqual(store.walletBalance, 184)
        XCTAssertEqual(store.ledger.count, 1)
        store.endTrip(id: id)
        XCTAssertEqual(store.walletBalance, 184)
        XCTAssertEqual(store.ledger.count, 1)
    }

    func testDeclinedFareFreezesAndRetryChargesOnce() async throws {
        let store = freshStore()
        store.walletBalance = 5
        store.cardDeclines = true
        store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric)
        let id = try XCTUnwrap(store.activeTrip?.id)
        guard case .paymentNeeded = store.endTrip(id: id) else { return XCTFail("Expected recovery") }
        let stopped = try XCTUnwrap(store.trips.first?.billingStoppedAt)
        XCTAssertEqual(store.walletBalance, 5)
        XCTAssertTrue(store.ledger.isEmpty)
        XCTAssertNil(store.activeTrip)
        XCTAssertEqual(store.trips.first?.status, .paymentPending)
        XCTAssertEqual(store.rideCost(store.trips[0], at: stopped.addingTimeInterval(86_400)), 16)
        XCTAssertFalse(store.startRide(vehicleID: "veh-ev-3", name: "EV 3", kind: .electric))
        XCTAssertFalse(store.takePlan(.suggested(for: .weekly)))
        store.endTrip(id: id)
        XCTAssertEqual(store.trips.first?.billingStoppedAt, stopped)
        store.cardDeclines = false
        store.defaultCard = "Mastercard test"
        guard case .paid = store.endTrip(id: id) else { return XCTFail("Retry should succeed") }
        store.endTrip(id: id)
        XCTAssertEqual(store.walletBalance, 0)
        XCTAssertEqual(store.ledger.count, 1)
        XCTAssertEqual(store.paymentBook.receipts["ride-" + id]?.wallet, 5)
        XCTAssertEqual(store.paymentBook.receipts["ride-" + id]?.card, 11)
    }

    func testPlanMinutesAreConsumedOnceAcrossDeclinesAndRetry() async throws {
        let store = freshStore()
        store.evPlan = EVPlan(option: .suggested(for: .weekly), until: .now.addingTimeInterval(86_400), usedMinutes: 0)
        store.walletBalance = 0
        store.cardDeclines = true
        store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric, tariff: .minute)
        store.trips[0].startDate = .now.addingTimeInterval(-125)
        let id = try XCTUnwrap(store.activeTrip?.id)
        store.endTrip(id: id)
        XCTAssertEqual(store.evPlan?.usedMinutes, 3)
        XCTAssertEqual(store.trips[0].total, 1)
        store.endTrip(id: id)
        store.cardDeclines = false
        store.endTrip(id: id)
        XCTAssertEqual(store.evPlan?.usedMinutes, 3)
        XCTAssertEqual(store.trips[0].reservedPlanMinutes, 3)
    }

    func testExpiredPlanDoesNotCoverFare() async throws {
        let store = freshStore()
        store.evPlan = EVPlan(option: .suggested(for: .weekly), until: .now.addingTimeInterval(-1), usedMinutes: 0)
        store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric, tariff: .minute)
        let trip = try XCTUnwrap(store.activeTrip)
        let quote = store.rideQuote(trip, at: trip.startDate.addingTimeInterval(120))
        XCTAssertEqual(quote.total, Decimal(string: "1.50"))
        XCTAssertEqual(quote.planMinutes, 0)
    }

    func testExtensionIsOnlyForOngoingBookedTariffs() async throws {
        let store = freshStore()
        store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric)
        let trip = try XCTUnwrap(store.activeTrip)
        store.extendRide(id: trip.id)
        XCTAssertEqual(store.activeTrip?.endDate, trip.endDate.addingTimeInterval(3600))
        XCTAssertEqual(store.rideCost(try XCTUnwrap(store.activeTrip)), 31)
        store.endTrip(id: trip.id)
        let stoppedEnd = store.trips[0].endDate
        store.extendRide(id: trip.id)
        XCTAssertEqual(store.trips[0].endDate, stoppedEnd)
        store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric, tariff: .minute)
        let minute = try XCTUnwrap(store.activeTrip)
        store.extendRide(id: minute.id)
        XCTAssertEqual(store.activeTrip?.endDate, minute.endDate)
    }

    func testGolfDepositIsSeparateAndRefundedExactlyOnce() async throws {
        let store = freshStore()
        let cart = try XCTUnwrap(store.vehicles.first { $0.kind == .golfCart })
        XCTAssertTrue(store.bookGolfCart(cart, hours: 2, total: 38, paymentID: "golf"))
        XCTAssertEqual(store.walletBalance, 62)
        XCTAssertEqual(store.paymentBook.receipts.count, 2)
        XCTAssertEqual(store.paymentBook.receipts["golf-deposit"]?.wallet, 100)
        guard case .paid = store.endTrip(id: "golf") else { return XCTFail("Expected return") }
        XCTAssertEqual(store.walletBalance, 162)
        XCTAssertEqual(store.trips[0].total, 38)
        XCTAssertEqual(store.ledger.count, 3)
        store.endTrip(id: "golf")
        XCTAssertEqual(store.walletBalance, 162)
        XCTAssertEqual(store.ledger.count, 3)
    }

    func testGolfDeclineDoesNotTakeRentalOrDeposit() async throws {
        let store = freshStore()
        let cart = try XCTUnwrap(store.vehicles.first { $0.kind == .golfCart })
        store.walletBalance = 50
        store.cardDeclines = true
        XCTAssertFalse(store.bookGolfCart(cart, hours: 2, total: 38))
        XCTAssertEqual(store.walletBalance, 50)
        XCTAssertTrue(store.ledger.isEmpty)
        XCTAssertTrue(store.trips.isEmpty)
        XCTAssertTrue(store.paymentBook.receipts.isEmpty)
    }

    func testCancellationRestoresOriginalSplitOnce() async {
        let store = freshStore()
        store.walletBalance = 20
        store.charge(100, label: "Rental", idempotencyKey: "rental")
        store.addBooking(TripRecord(id: "booking", kind: .car, title: "Rental", status: "Booked",
                                   tone: .success, amount: .money(100), rows: [], paymentID: "rental"))
        store.defaultCard = "Different card"
        store.cancelBooking("booking")
        store.cancelBooking("booking")
        XCTAssertEqual(store.walletBalance, 20)
        XCTAssertEqual(store.ledger.count, 2)
        XCTAssertEqual(store.bookedRecords[0].amount, .refunded(100))
        XCTAssertTrue(store.bookedRecords[0].isCancelled)
        XCTAssertEqual(store.paymentBook.receipts["rental"]?.cardLabel, "Visa •••• 4242")
    }

    func testUnchargedRequestCancellationCreatesNoRefund() async {
        let store = freshStore()
        let booking = TripRecord(id: "request", kind: .car, title: "Requested car", status: "Waiting for host",
                                 tone: .pending, amount: .money(350), rows: [])
        store.addBooking(booking)
        store.addBooking(booking)
        XCTAssertEqual(store.bookedRecords.count, 1)
        store.cancelBooking(booking.id)
        XCTAssertEqual(store.walletBalance, 200)
        XCTAssertTrue(store.ledger.isEmpty)
        XCTAssertEqual(store.bookedRecords[0].amount, .noCharge)
    }

    func testSnapshotRestoresTripPaymentsPlanCardAndPromos() async throws {
        let url = try snapshotURL()
        let store = Store.live(snapshotURL: url)
        store.walletBalance = 200
        store.defaultCard = "Mastercard test"
        store.redeemedPromos = ["WELCOME"]
        XCTAssertTrue(store.takePlan(.suggested(for: .weekly)))
        store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric)
        let restored = Store.live(snapshotURL: url)
        XCTAssertNil(restored.persistenceError)
        XCTAssertEqual(restored.activeTrip?.id, store.activeTrip?.id)
        XCTAssertEqual(restored.walletBalance, store.walletBalance)
        XCTAssertEqual(restored.evPlan, store.evPlan)
        XCTAssertEqual(restored.defaultCard, "Mastercard test")
        XCTAssertEqual(restored.redeemedPromos, ["WELCOME"])
        XCTAssertEqual(restored.paymentBook.receipts.count, 1)
        XCTAssertEqual(restored.ledger.count, 1)
    }

    func testPendingPaymentSurvivesRelaunchAndRetry() async throws {
        let url = try snapshotURL()
        let store = Store.live(snapshotURL: url)
        store.walletBalance = 0
        store.cardDeclines = true
        store.startRide(vehicleID: "veh-ev-6", name: "EV 6", kind: .electric)
        let id = try XCTUnwrap(store.activeTrip?.id)
        store.endTrip(id: id)
        let restored = Store.live(snapshotURL: url)
        XCTAssertNil(restored.activeTrip)
        XCTAssertEqual(restored.trips[0].status, .paymentPending)
        XCTAssertEqual(restored.trips[0].total, 16)
        restored.endTrip(id: id)
        restored.endTrip(id: id)
        XCTAssertEqual(restored.paymentBook.receipts.count, 1)
        XCTAssertEqual(restored.ledger.count, 1)
        XCTAssertEqual(Store.live(snapshotURL: url).trips[0].status, .completed)
    }

    func testCancelledBookingAndRefundSurviveRelaunch() async throws {
        let url = try snapshotURL()
        let store = Store.live(snapshotURL: url)
        store.walletBalance = 10
        store.charge(30, label: "Transfer", idempotencyKey: "paid")
        store.addBooking(TripRecord(id: "b", kind: .transfer, title: "Transfer", status: "Booked",
                                   tone: .success, amount: .money(30), rows: [], paymentID: "paid"))
        store.cancelBooking("b")
        let restored = Store.live(snapshotURL: url)
        restored.cancelBooking("b")
        XCTAssertTrue(restored.bookedRecords[0].isCancelled)
        XCTAssertEqual(restored.walletBalance, 10)
        XCTAssertEqual(restored.ledger.count, 2)
    }

    func testCorruptSnapshotIsPreservedAndNeverOverwritten() async throws {
        let url = try snapshotURL()
        let corrupt = Data("invalid saved data".utf8)
        try corrupt.write(to: url)
        let store = Store.live(snapshotURL: url)
        XCTAssertNotNil(store.persistenceError)
        store.credit(50, label: "Test")
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }

    func testFutureSnapshotVersionIsPreserved() async throws {
        let url = try snapshotURL()
        let store = Store.live(snapshotURL: url)
        store.saveSnapshot()
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        json["version"] = 999
        let future = try JSONSerialization.data(withJSONObject: json)
        try future.write(to: url)
        let restored = Store.live(snapshotURL: url)
        XCTAssertNotNil(restored.persistenceError)
        restored.saveSnapshot()
        XCTAssertEqual(try Data(contentsOf: url), future)
    }

    func testGuestGateAndVerificationPreviewDoNotStartRide() async {
        let router = AppRouter(), session = Session()
        var starts = 0
        router.requireVerified(session, holding: "EV") { starts += 1 }
        XCTAssertNotNil(router.auth)
        XCTAssertEqual(starts, 0)
        session.signIn(name: "Test", phone: "test")
        session.beginVerificationPreview()
        session.receivePreviewApproval()
        XCTAssertFalse(session.canRide)
        session.completeVerification()
        router.requireVerified(session, holding: "EV") { starts += 1 }
        XCTAssertEqual(starts, 1)
        session.signOut()
        XCTAssertFalse(session.hasAccount)
        XCTAssertNil(session.phoneNumber)
    }

    func testTabsKeepIndependentNavigationStacks() async {
        let router = AppRouter()
        router.push(.renterList)
        router.tab = .profile
        router.push(.becomeHost)
        XCTAssertEqual(router[path: .home].count, 1)
        XCTAssertEqual(router[path: .profile].count, 1)
        router.popToRoot(.profile)
        XCTAssertEqual(router[path: .home].count, 1)
        XCTAssertEqual(router[path: .profile].count, 0)
    }

    func testGolfOneDaySelectionIsExactly24Hours() async {
        let dates = RentalDates.fromNow
        XCTAssertEqual(dates.dropOff.timeIntervalSince(dates.pickUp), 86_400, accuracy: 0.001)
        XCTAssertEqual(dates.days, 1)
    }
    #else
    func testReleaseBlocksDemoMoneyAndRideMutations() async throws {
        XCTAssertFalse(AppConfiguration.isDemo)
        let store = freshStore()
        let cart = try XCTUnwrap(store.vehicles.first { $0.kind == .golfCart })
        XCTAssertFalse(store.startRide(vehicleID: "veh-ev-6", name: "EV", kind: .electric))
        XCTAssertFalse(store.bookGolfCart(cart, hours: 2, total: 38))
        XCTAssertEqual(store.charge(20, label: "Test"), .declined)
        XCTAssertFalse(store.takePlan(.suggested(for: .weekly)))
        store.credit(50, label: "Test")
        XCTAssertEqual(store.walletBalance, 200)
        XCTAssertTrue(store.ledger.isEmpty)
    }

    func testReleaseCannotVerifyFromDemoCallback() async {
        let session = Session()
        session.signIn(name: "Test", phone: "test")
        session.completeVerification()
        XCTAssertFalse(session.canRide)
        let router = AppRouter()
        var started = false
        router.requireVerified(session, holding: "EV") { started = true }
        XCTAssertFalse(started)
        XCTAssertNotNil(router.auth)
    }

    func testReleaseDoesNotLoadDemoSnapshot() async throws {
        let url = try snapshotURL()
        try Data("invalid demo data".utf8).write(to: url)
        let store = Store.live(snapshotURL: url)
        XCTAssertTrue(store.trips.isEmpty)
        XCTAssertEqual(store.walletBalance, 0)
        XCTAssertNil(store.persistenceError)
    }
    #endif
}
