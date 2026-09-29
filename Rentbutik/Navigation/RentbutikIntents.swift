import AppIntents
import SwiftUI

/// The single router, store and session the app and its App Intents share,
/// so Siri, Spotlight and Shortcuts act on exactly what's on screen.
enum AppServices {
    #if DEBUG
    static let store = UITestConfiguration.makeStore()
    static let session = UITestConfiguration.makeSession()
    static let router = UITestConfiguration.makeRouter()
    #else
    static let router = AppRouter()
    static let store = Store.live()
    static let session = Session()
    #endif
}

// MARK: - Intents

struct FindElectricCarIntent: AppIntent {
    static let title: LocalizedStringResource = "Find an electric car"
    static let description = IntentDescription("Shows Rentbutik electric cars near you on the map.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let router = AppServices.router
        router.tab = .home
        router.popToRoot(.home)
        router.push(.evUnlock(vehicleID: "veh-ev-6"))
        return .result()
    }
}

struct RentGolfCartIntent: AppIntent {
    static let title: LocalizedStringResource = "Rent a golf cart"
    static let description = IntentDescription("Opens the Sea Breeze golf cart map.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let router = AppServices.router
        router.tab = .home
        router.popToRoot(.home)
        router.push(.golfMap)
        return .result()
    }
}

struct BookTransferIntent: AppIntent {
    static let title: LocalizedStringResource = "Book a transfer"
    static let description = IntentDescription("Opens rides and tours from Baku.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let router = AppServices.router
        router.tab = .home
        router.popToRoot(.home)
        router.push(.transferList)
        return .result()
    }
}

/// Answered by Siri in place — no need to open the app.
struct WalletBalanceIntent: AppIntent {
    static let title: LocalizedStringResource = "Wallet balance"
    static let description = IntentDescription("Tells you how much is in your Rentbutik Wallet.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let balance = AppServices.store.walletBalance
            .formatted(.currency(code: Currency.code).precision(.fractionLength(2)))
        return .result(value: balance,
                       dialog: "You have \(balance) in your Rentbutik Wallet.")
    }
}

struct MessageHostIntent: AppIntent {
    static let title: LocalizedStringResource = "Message my host"
    static let description = IntentDescription("Opens the chat with the host of your current booking.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let router = AppServices.router
        router.tab = .chats
        router.popToRoot(.chats)
        router.push(.thread(threadID: "thr-hasan"))
        return .result()
    }
}

// MARK: - App Shortcuts (Siri, Spotlight, Shortcuts, Action button)

struct RentbutikShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: FindElectricCarIntent(),
                    phrases: ["Find an electric car in \(.applicationName)",
                              "Start an EV ride with \(.applicationName)"],
                    shortTitle: "Electric car", systemImageName: "bolt.car.fill")
        AppShortcut(intent: RentGolfCartIntent(),
                    phrases: ["Rent a golf cart in \(.applicationName)",
                              "Golf cart with \(.applicationName)"],
                    shortTitle: "Golf cart", systemImageName: "steeringwheel")
        AppShortcut(intent: BookTransferIntent(),
                    phrases: ["Book a transfer in \(.applicationName)",
                              "Get a ride to the airport with \(.applicationName)"],
                    shortTitle: "Transfer", systemImageName: "point.topleft.down.to.point.bottomright.curvepath.fill")
        AppShortcut(intent: WalletBalanceIntent(),
                    phrases: ["What’s my \(.applicationName) balance",
                              "\(.applicationName) wallet balance"],
                    shortTitle: "Wallet balance", systemImageName: "wallet.bifold.fill")
        AppShortcut(intent: MessageHostIntent(),
                    phrases: ["Message my host in \(.applicationName)"],
                    shortTitle: "Message host", systemImageName: "message.fill")
    }
}
