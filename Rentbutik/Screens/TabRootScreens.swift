import SwiftUI

/// Resolves a pushed `Route`. Each phase replaces its own cases.
struct RouteView: View {
    let route: Route
    let store: Store
    let router: AppRouter

    var body: some View {
        // Wrapped in a Group so every branch shares one top-level view.
        Group {
            switch route {
            case .allNotifications:
                AllNotificationsScreen(store: store)

            case .renterList:
                RenterListScreen(store: store, router: router)

            case .checkout(let listingID, let dates):
                if let listing = RenterCatalog.listings.first(where: { $0.id == listingID }) {
                    RenterCheckoutScreen(listing: listing, dates: dates, store: store, router: router)
                } else {
                    MissingRoute(route: route)
                }

            case .rentalComplete:
                RentalCompleteScreen(router: router)

            case .transferList:
                TransferListScreen(store: store, router: router)

            case .transferBook(let rideID):
                if let ride = TransferCatalog.rides.first(where: { $0.id == rideID }) {
                    TransferBookScreen(ride: ride, store: store, router: router)
                } else {
                    MissingRoute(route: route)
                }

            case .thread(let threadID):
                if let thread = store.threads.first(where: { $0.id == threadID }) {
                    ThreadScreen(thread: thread, store: store)
                } else {
                    MissingRoute(route: route)
                }

            case .evUnlock(let vehicleID):
                EVSelectScreen(store: store, router: router, initialID: vehicleID)

            case .evActiveTrip(let vehicleID):
                if let vehicle = store.vehicles.first(where: { $0.id == vehicleID }) {
                    EVActiveTripScreen(vehicle: vehicle, store: store, router: router)
                } else {
                    MissingRoute(route: route)
                }

            case .golfMap:
                GolfMapScreen(store: store, router: router)

            case .golfBooking(let vehicleID):
                if let cart = store.vehicles.first(where: { $0.id == vehicleID }) {
                    GolfBookingScreen(cart: cart, store: store, router: router)
                } else {
                    MissingRoute(route: route)
                }

            case .becomeHost:       HostingScreen(store: store, router: router)
            case .hostRequest:      HostRequestScreen(store: store)
            case .hostHandoff:      HostHandoffScreen(store: store, router: router)
            case .hostReturn:       HostReturnScreen(store: store, router: router)
            case .hostListCar:      HostListCarScreen(store: store)
            case .hostTransfers:    HostTransfersScreen(store: store, router: router)
            case .hostPostTransfer: HostPostTransferScreen(store: store)
            case .hostPassenger:    HostPassengerScreen(store: store)
            }
        }
    }
}

/// A route whose screens aren't built yet — the native empty state, so it
/// reads as "coming soon" rather than a broken page.
private struct MissingRoute: View {
    let route: Route

    var body: some View {
        ContentUnavailableView("Coming soon",
                               systemImage: "hammer.fill",
                               description: Text("This part of Rentbutik is on its way."))
            .background(Theme.background)
    }
}

