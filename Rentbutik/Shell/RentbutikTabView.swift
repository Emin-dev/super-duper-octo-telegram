import SwiftUI

/// The tab shell — the native iOS 27 tab bar, no custom control.
///
/// This supersedes the custom floating bar RULES.md B4/O/R describes. The system
/// bar brings its own Liquid Glass, minimize-on-scroll, accessibility and
/// context handling, which is what "Apple-native patterns only" (RULE A2) asks
/// for. Two consequences worth recording:
///
/// - The active-tab recipe in RULE R (glass-clear pill + glass-edge stroke) is
///   now the system's, driven by `.tint`. RULE B4's "white in dark, gold in
///   light" is handled by the system tinting against its own material.
/// - RULE B8's 96pt `tabBarClearance` is no longer ours to set — the system
///   provides the safe-area inset. Screens use `.safeAreaInset`-aware padding
///   instead of a hardcoded 96.
struct RentbutikTabView: View {
    let router: AppRouter
    let store: Store
    let session: Session

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.tab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.symbol, value: .home) {
                TabRoot(tab: .home, router: router, store: store) {
                    HomeScreen(store: store, session: session, router: router)
                }
            }

            Tab(AppTab.chats.title, systemImage: AppTab.chats.symbol, value: .chats) {
                TabRoot(tab: .chats, router: router, store: store) {
                    ChatsScreen(store: store, router: router)
                }
            }
            .badge(store.threads.count { $0.isUnread })

            Tab(AppTab.trips.title, systemImage: AppTab.trips.symbol, value: .trips) {
                TabRoot(tab: .trips, router: router, store: store) {
                    TripsScreen(store: store, router: router)
                }
            }

            Tab(AppTab.profile.title, systemImage: AppTab.profile.symbol, value: .profile) {
                TabRoot(tab: .profile, router: router, store: store) {
                    ProfileScreen(store: store, session: session, router: router)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Text(AppConfiguration.isDemo ? "Demo · no real bookings or charges" : "Service setup required · browsing only")
                .font(.caption).foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity).padding(.vertical, 4).background(Theme.background)
            if let error = store.persistenceError {
                Text(error).font(.caption).foregroundStyle(Theme.danger).padding(.horizontal)
            }
        }
        .tint(Theme.goldText)
        .tabBarMinimizeBehavior(.never)
        // Screens that gate a ride read the session from the environment.
        .environment(session)
        .task {
            MapPrewarm.start()
            // Demo events are triggered by explicit actions, never by a background timer.
        }
        .fullScreenCover(item: $router.auth) { request in
            AuthFlow(session: session, request: request)
        }
        // Tab switches are a selection change, so the native selection feel.
        .sensoryFeedback(.selection, trigger: router.tab)
    }
}

/// One tab's `NavigationStack`. Factored out so the path binding uses a static
/// subscript key and the stack keeps its identity across tab switches.
private struct TabRoot<Content: View>: View {
    let tab: AppTab
    let router: AppRouter
    let store: Store
    @ViewBuilder let content: Content

    /// Shared by Home's tiles and the screens they open, for zoom transitions.
    @Namespace private var zoom

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router[path: tab]) {
            content
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route, store: store, router: router)
                        .modifier(ZoomIn(sourceID: route.zoomSourceID, namespace: zoom))
                }
        }
        .environment(\.zoomNamespace, zoom)
    }
}

extension EnvironmentValues {
    /// The tab's zoom-transition namespace (nil outside a tab).
    @Entry var zoomNamespace: Namespace.ID?
}

extension Route {
    /// Screens that open from a Home tile zoom out of that tile.
    var zoomSourceID: String? {
        switch self {
        case .transferList: "transfer"
        case .renterList: "renter"
        case .evUnlock, .evActiveTrip: "electric"
        case .golfMap: "golf"
        default: nil
        }
    }
}

/// Native iOS zoom navigation transition when the route has a source.
private struct ZoomIn: ViewModifier {
    let sourceID: String?
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if let sourceID {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
    }
}

extension View {
    /// Marks a Home tile as the place its screen zooms out of.
    @ViewBuilder
    func zoomSource(_ id: String, in namespace: Namespace.ID?, cornerRadius: CGFloat) -> some View {
        if let namespace {
            matchedTransitionSource(id: id, in: namespace) { $0.clipShape(.rect(cornerRadius: cornerRadius)) }
        } else {
            self
        }
    }
}

