//
//  RentbutikApp.swift
//  Rentbutik
//
//  Created by Emin on 17.09.26.
//

import SwiftUI
import AppIntents

@main
struct RentbutikApp: App {
    /// Shared with the App Intents (Siri, Spotlight, Shortcuts), so a spoken
    /// "Find an electric car" drives the same router the screen uses.
    private let router = AppServices.router
    private let store = AppServices.store
    // Browse-first applies at launch too: people can explore cars and prices
    // without a fabricated signed-in or verified identity.
    private let session = AppServices.session

    init() {
        LocalNotifier.shared.activate()
        RentbutikShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            // RULE K: the app opens straight to Home. No wall, no splash gate —
            // anyone can browse vehicles and see prices. Pricing is the hook.
            RentbutikTabView(router: router, store: store, session: session)
        }
    }
}

