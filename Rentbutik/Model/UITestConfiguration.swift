#if DEBUG
import Foundation

/// Isolated fixtures for simulator UI tests. Not compiled into Release.
/// Tests still use the real screens, navigation, Store and payment logic.
enum UITestConfiguration {
    private static var enabled: Bool { ProcessInfo.processInfo.arguments.contains("--ui-testing") }
    private static var environment: [String: String] { ProcessInfo.processInfo.environment }

    static func makeSession() -> Session {
        guard enabled, environment["UI_VERIFIED"] == "1" else { return Session() }
        return Session.emin()
    }

    static func makeStore() -> Store {
        guard enabled else { return Store.live() }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rentbutik-ui-test.json")
        if environment["UI_RESET"] != "0" { try? FileManager.default.removeItem(at: url) }
        let store = Store.live(snapshotURL: url)
        if environment["UI_RESET"] != "0", environment["UI_SCENARIO"] == "payment-pending" {
            store.walletBalance = 0
            store.cardDeclines = true
            _ = store.startRide(vehicleID: "veh-ev-6", name: "Rentbutik EV 6", kind: .electric)
            if let trip = store.activeTrip { store.endTrip(id: trip.id) }
        }
        return store
    }

    static func makeRouter() -> AppRouter {
        let router = AppRouter()
        guard enabled else { return router }
        switch environment["UI_SCENARIO"] {
        case "ev": router.push(.evUnlock(vehicleID: "veh-ev-6"))
        case "payment-pending": router.push(.evActiveTrip(vehicleID: "veh-ev-6"))
        case "golf": router.push(.golfMap)
        case "renter": router.push(.renterList)
        case "renter-checkout": router.push(.checkout(listingID: "amg", dates: .fromNow))
        case "renter-request": router.push(.checkout(listingID: "mustang", dates: .fromNow))
        case "transfers": router.push(.transferList)
        case "transfer-book": router.push(.transferBook(rideID: "gyd"))
        case "host": router.tab = .profile; router.push(.becomeHost)
        case "chat": router.tab = .chats; router.push(.thread(threadID: "thr-support"))
        case "trips": router.tab = .trips
        default: break
        }
        return router
    }
}
#endif
