import SwiftUI

/// The four tab roots. The active tab follows the screen and never defaults
/// back to Home — RULE R.
enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case home, chats, trips, profile

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .home:    "Home"
        case .chats:   "Chats"
        case .trips:   "Trips"
        case .profile: "Profile"
        }
    }

    /// SF Symbols only, no custom icons, ever — RULE A3.
    var symbol: String {
        switch self {
        case .home:    "house.fill"
        case .chats:   "message.fill"
        case .trips:   "suitcase.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

/// Everything a screen can push. One enum keeps destinations type-checked and
/// makes `navigationDestination` exhaustive.
enum Route: Hashable {
    /// TR01 · Transfers marketplace — Home's first module.
    case transferList
    /// TR02 · Book a ride.
    case transferBook(rideID: String)
    /// H04 · All notifications — pushed from "See all".
    case allNotifications
    /// R01 · Cars near you.
    case renterList
    /// R04 · Checkout for a Renter listing and its dates.
    case checkout(listingID: String, dates: RentalDates)
    /// R05 · Rental complete.
    case rentalComplete
    /// EV01 · Select vehicle, starting on this car.
    case evUnlock(vehicleID: String)
    /// EV03 · Active ride.
    case evActiveTrip(vehicleID: String)
    /// G01 · Select golf cart.
    case golfMap
    /// G02 · Golf reservation.
    case golfBooking(vehicleID: String)
    /// C02 / C03 · A chat.
    case thread(threadID: String)
    /// HO01 · Hosting.
    case becomeHost
    /// HO03 · Booking request.
    case hostRequest
    /// HO04 · Handoff.
    case hostHandoff
    /// HO04b · Car returned.
    case hostReturn
    /// HO02 · List your car (4 steps).
    case hostListCar
    /// HO06 · Your transfers.
    case hostTransfers
    /// HO07 · Post a transfer (4 steps).
    case hostPostTransfer
    /// HO08 · Passenger request.
    case hostPassenger
}

/// One request to open Sign in (section 06). It carries the car being held
/// for the person and what to do once they are verified, so the trip picks up
/// exactly where it stopped.
struct AuthRequest: Identifiable {
    enum Entry { case firstTrip, returning }

    let id = UUID()
    var entry: Entry = .firstTrip
    var heldVehicle: String? = nil
    /// The hold from A06 — 30 minutes from the moment Start was tapped.
    var holdEnds: Date = .now.addingTimeInterval(30 * 60)
    var onVerified: () -> Void = {}
}

/// Owns the selected tab and one `NavigationPath` per tab, so each tab keeps
/// its own back stack.
@Observable
final class AppRouter {
    var tab: AppTab = .home

    /// Presented as a full-screen cover by the tab shell.
    var auth: AuthRequest?

    /// "Only at the first trip": runs `action` straight away when the person
    /// can already ride, otherwise opens Sign in and runs it after verifying.
    func requireVerified(_ session: Session, holding vehicle: String?,
                         then action: @escaping () -> Void) {
        if session.canRide {
            action()
        } else {
            auth = AuthRequest(heldVehicle: vehicle, onVerified: action)
        }
    }

    private var homePath = NavigationPath()
    private var chatsPath = NavigationPath()
    private var tripsPath = NavigationPath()
    private var profilePath = NavigationPath()

    /// Labelled subscript so views can project a `Binding` straight into the
    /// right path — `$router[path: .home]` — instead of building a closure
    /// binding, which would allocate on every body evaluation.
    subscript(path tab: AppTab) -> NavigationPath {
        get {
            switch tab {
            case .home:    homePath
            case .chats:   chatsPath
            case .trips:   tripsPath
            case .profile: profilePath
            }
        }
        set {
            switch tab {
            case .home:    homePath = newValue
            case .chats:   chatsPath = newValue
            case .trips:   tripsPath = newValue
            case .profile: profilePath = newValue
            }
        }
    }

    /// Push onto the currently selected tab's stack.
    func push(_ route: Route) {
        self[path: tab].append(route)
    }

    func popToRoot(_ tab: AppTab) {
        self[path: tab] = NavigationPath()
    }
}

