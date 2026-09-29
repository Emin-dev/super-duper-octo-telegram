import XCTest

@MainActor
final class RentbutikUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        addUIInterruptionMonitor(withDescription: "System permission") { alert in
            if alert.buttons["Don’t Allow"].exists { alert.buttons["Don’t Allow"].tap(); return true }
            if alert.buttons["Don't Allow"].exists { alert.buttons["Don't Allow"].tap(); return true }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let app {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = name
            screenshot.lifetime = .keepAlways
            add(screenshot)
            if (testRun?.failureCount ?? 0) > 0 {
                print("UI FAILURE TREE: \(app.debugDescription)")
            }
            app.terminate()
        }
    }

    private func launch(_ scenario: String = "home", verified: Bool = false,
                        reset: Bool = true, largeDark: Bool = false) {
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if largeDark {
            app.launchArguments += ["-AppleInterfaceStyle", "Dark", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchEnvironment = ["UI_SCENARIO": scenario, "UI_VERIFIED": verified ? "1" : "0", "UI_RESET": reset ? "1" : "0"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Demo · no real bookings or charges"].waitForExistence(timeout: 20))
    }

    private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 12), "Missing \(element)", file: file, line: line)
        XCTAssertTrue(element.isHittable, "Not reachable: \(element)", file: file, line: line)
        element.tap()
    }

    private func button(containing text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func capture(_ stages: [String]) {
        for id in stages {
            XCTAssertTrue(app.staticTexts["capture.stage." + id].waitForExistence(timeout: 15))
            let shutter = app.buttons["Take photo"]
            let ready = NSPredicate(format: "enabled == true")
            expectation(for: ready, evaluatedWith: shutter)
            waitForExpectations(timeout: 10)
            tap(shutter)
        }
    }

    func testGuestCanBrowseAllTabsAndTripsStartEmpty() {
        launch()
        XCTAssertTrue(app.staticTexts["Welcome"].exists)
        tap(app.tabBars.buttons["Chats"])
        XCTAssertTrue(app.textFields["Search"].waitForExistence(timeout: 5))
        tap(app.tabBars.buttons["Trips"])
        XCTAssertTrue(app.staticTexts["No active trip"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nothing booked yet"].exists)
        tap(app.tabBars.buttons["Profile"])
        XCTAssertTrue(button(containing: "Sign in").exists)
        tap(app.tabBars.buttons["Home"])
        XCTAssertTrue(app.staticTexts["Welcome"].exists)
    }

    func testGuestCanBrowseEVButStartRequiresRegistration() {
        launch()
        tap(app.buttons["home.electric"])
        tap(app.buttons["ev.start.veh-ev-6"])
        XCTAssertTrue(app.staticTexts["How will you rent?"].waitForExistence(timeout: 10))
        tap(app.buttons["Close"])
        XCTAssertTrue(app.buttons["ev.start.veh-ev-6"].waitForExistence(timeout: 5))
    }

    func testEVPhotosRideLockExtendReturnAndReceipt() {
        launch("ev", verified: true)
        tap(app.buttons["ev.start.veh-ev-6"])
        capture(["front", "rear", "left", "right", "selfie"])
        XCTAssertTrue(app.staticTexts["Riding now"].waitForExistence(timeout: 15))
        tap(app.buttons["Unlocked"])
        XCTAssertTrue(app.staticTexts["Car locked"].exists)
        tap(app.buttons["Locked"])
        tap(app.buttons["Extend"])
        tap(button(containing: "Add 1 hour"))
        XCTAssertTrue(app.staticTexts["Riding now"].waitForExistence(timeout: 5))
        let slider = app.buttons["Slide to end"]
        XCTAssertTrue(slider.exists)
        slider.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: slider.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)))
        capture(["front", "rear", "left", "right", "inside", "parking"])
        XCTAssertTrue(app.staticTexts["Ride complete"].waitForExistence(timeout: 15))
        tap(app.buttons["Done"])
        tap(app.tabBars.buttons["Trips"])
        XCTAssertTrue(app.staticTexts["No active trip"].waitForExistence(timeout: 5))
        XCTAssertTrue(button(containing: "Rentbutik EV 6").exists)
    }

    func testRideSurvivesTerminationAndRelaunch() {
        launch("ev", verified: true)
        tap(app.buttons["ev.start.veh-ev-6"])
        capture(["front", "rear", "left", "right", "selfie"])
        XCTAssertTrue(app.staticTexts["Riding now"].waitForExistence(timeout: 15))
        app.terminate()
        launch("trips", verified: true, reset: false)
        tap(app.buttons["Open ride"])
        XCTAssertTrue(app.staticTexts["Riding now"].waitForExistence(timeout: 10))
    }

    func testPaymentRecoverySelectsCardAndRetries() {
        launch("payment-pending", verified: true)
        XCTAssertTrue(app.staticTexts["The meter has stopped. Your total will not increase while you update payment."].exists)
        tap(app.buttons["Retry payment"])
        XCTAssertTrue(app.buttons["Retry payment"].exists)
        tap(app.buttons["Payment methods"])
        tap(app.buttons["payment.method.mc"])
        if app.navigationBars.buttons["Wallet"].exists { tap(app.navigationBars.buttons["Wallet"]) }
        tap(app.buttons["Done"])
        tap(app.buttons["Retry payment"])
        XCTAssertTrue(app.staticTexts["Ride complete"].waitForExistence(timeout: 10))
    }

    func testGolfRentalReturnAndReceipt() {
        launch("golf", verified: true)
        let start = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "golf.start.")).firstMatch
        tap(start)
        tap(app.tabBars.buttons["Trips"])
        tap(app.buttons["Return cart"])
        capture(["front", "rear", "left", "right", "inside", "parking"])
        XCTAssertTrue(app.navigationBars["Trip details"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Completed"].exists)
        tap(app.buttons["Done"])
        XCTAssertTrue(app.staticTexts["No active trip"].exists)
    }

    func testRenterInstantBookingAndCancellation() {
        launch("renter-checkout", verified: true)
        tap(app.buttons["renter.confirm"])
        tap(button(containing: "Mercedes-AMG GT"))
        tap(app.buttons["Cancel booking"])
        tap(app.alerts.buttons["Cancel booking"])
        XCTAssertTrue(app.staticTexts["Nothing booked yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(button(containing: "Cancelled").exists)
    }

    func testRenterRequestWaitsForHost() {
        launch("renter-request", verified: true)
        tap(app.buttons["renter.confirm"])
        tap(button(containing: "Ford Mustang GT"))
        XCTAssertTrue(app.staticTexts["No charge now. Host acceptance and payment confirmation are required."].exists)
        tap(app.buttons["Message"])
        XCTAssertTrue(app.navigationBars.matching(NSPredicate(format: "identifier CONTAINS %@", "Nigar")).firstMatch.waitForExistence(timeout: 5)
                      || app.staticTexts["Nigar"].exists)
    }

    func testTransferBookingAppearsInTrips() {
        launch("transfer-book", verified: true)
        tap(app.buttons["transfer.confirm"])
        tap(button(containing: "Baku → Airport"))
        XCTAssertTrue(app.staticTexts["Paid after the ride — Wallet first, then your card."].exists)
        XCTAssertTrue(app.buttons["Cancel booking"].exists)
    }

    func testCatalogAndHostScreensOpen() {
        launch("renter")
        XCTAssertTrue(app.navigationBars["Cars near you"].waitForExistence(timeout: 8))
        app.terminate()
        launch("transfers")
        XCTAssertTrue(app.navigationBars["Transfers"].waitForExistence(timeout: 8))
        app.terminate()
        launch("host", verified: true)
        tap(app.buttons["Add a car"])
        XCTAssertTrue(app.navigationBars["List your car"].waitForExistence(timeout: 8))
        tap(app.navigationBars.buttons["Hosting"])
        tap(app.buttons["Post a transfer"])
        XCTAssertTrue(app.navigationBars["Post a transfer"].waitForExistence(timeout: 8))
    }

    func testChatRejectsEmptyMessageAndSendsTypedMessage() {
        launch("chat", verified: true)
        XCTAssertFalse(app.buttons["chat.send"].isEnabled)
        let message = app.textViews["Message"].exists ? app.textViews["Message"] : app.textFields["Message"]
        tap(message)
        message.typeText("UI test: please confirm the return location.")
        tap(app.buttons["chat.send"])
        XCTAssertTrue(app.staticTexts["UI test: please confirm the return location."].waitForExistence(timeout: 5))
    }

    func testLargeTextDarkModeKeepsTripsAndProfileReachable() {
        launch("trips", largeDark: true)
        XCTAssertTrue(app.staticTexts["No active trip"].waitForExistence(timeout: 5))
        tap(app.tabBars.buttons["Profile"])
        app.swipeUp()
        let wallet = app.buttons["profile.wallet"]
        if !wallet.isHittable { app.swipeUp() }
        tap(wallet)
        XCTAssertTrue(app.navigationBars["Wallet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["wallet.balance"].exists)
    }
}
