import XCTest

// Taps through the app like a student would
final class MyAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // Opens the app signed in, skipping onboarding
    @MainActor
    private func launchSignedIn() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-isSignedIn", "YES", "-hasSeenIntro", "YES", "-schoolID", "Cary High School"]
        app.launch()
        return app
    }

    // The school day before today
    private var previousSchoolDay: Date {
        let calendar = Calendar.current
        var day = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now)) ?? .now
        while calendar.isDateInWeekend(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return day
    }

    @MainActor
    func testPickingAPastDayShowsThatMenu() throws {
        let app = launchSignedIn()
        XCTAssertTrue(app.buttons["See Menu"].waitForExistence(timeout: 6))
        app.buttons["See Menu"].tap()

        let day = previousSchoolDay
        let chipStart = "\(day.formatted(.dateTime.weekday(.abbreviated))), \(day.formatted(.dateTime.day()))"
        let chip = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", chipStart)).firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5), "No chip for \(chipStart)")
        chip.tap()

        let heading = day.formatted(.dateTime.weekday(.wide).month().day())
        XCTAssertTrue(app.staticTexts[heading].waitForExistence(timeout: 3), "Menu did not switch to \(heading)")
    }

    @MainActor
    func testAccountButtonOpensSettings() throws {
        let app = launchSignedIn()
        XCTAssertTrue(app.buttons["Account"].waitForExistence(timeout: 6))
        app.buttons["Account"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testResetAppGoesBackToFirstLaunch() throws {
        let app = launchSignedIn()
        let account = app.buttons["Account"]
        XCTAssertTrue(account.waitForExistence(timeout: 6))
        account.tap()
        app.buttons["Reset App"].firstMatch.tap()
        // The confirmation sheet has its own Reset App button
        let confirm = app.buttons.matching(identifier: "Reset App").element(boundBy: 1)
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["Swipe up to continue"].waitForExistence(timeout: 5))
    }

    // A slow walkthrough of the whole app, for recording a demo video.
    // Expects the app to be installed and reset to a fresh start first.
    @MainActor
    func testDemoWalkthrough() throws {
        let app = XCUIApplication(bundleIdentifier: "com.akshaysanjai.lunchloop")
        func pause(_ seconds: Double = 1.2) { Thread.sleep(forTimeInterval: seconds) }

        // Opening animation, then swipe up
        app.launch()
        XCTAssertTrue(app.staticTexts["Swipe up to continue"].waitForExistence(timeout: 20))
        pause(1)
        app.swipeUp(velocity: .slow)
        pause()

        // Three intro pages
        app.buttons["Next"].tap()
        pause()
        app.buttons["Next"].tap()
        pause()
        app.buttons["Get Started"].tap()
        pause()

        // Pick a school with the search bar
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'School'")).firstMatch.tap()
        pause()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tap()
        search.typeText("Apex")
        pause()
        app.buttons["Apex Friendship High School"].tap()
        pause()

        // Fill in the account
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Akshay")
        app.textFields["School Email"].tap()
        app.textFields["School Email"].typeText("akshay@wcpss.net")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("lunch123")
        pause()
        app.buttons["Create Account"].tap()

        // iOS offers to save the password. Say Not Now.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if app.buttons["Not Now"].waitForExistence(timeout: 5) {
            pause(0.8)
            app.buttons["Not Now"].tap()
        } else if springboard.buttons["Not Now"].waitForExistence(timeout: 2) {
            pause(0.8)
            springboard.buttons["Not Now"].tap()
        }

        // Home: scroll all the way down, then back up
        XCTAssertTrue(app.buttons["Vote Now"].waitForExistence(timeout: 8))
        pause(1.5)
        for _ in 0..<4 {
            app.swipeUp(velocity: .slow)
            pause(0.9)
        }
        pause()
        for _ in 0..<4 {
            app.swipeDown(velocity: .slow)
            pause(0.6)
        }
        pause()

        // Vote on today's lunch
        app.buttons["Vote Now"].tap()
        pause(1.5)
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS 'votes'")).element(boundBy: 1)
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()
        pause()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Vote for'")).firstMatch.tap()
        pause(2)

        // Look back at yesterday's results, then jump back to today
        let yesterday = previousSchoolDay
        let chipStart = "\(yesterday.formatted(.dateTime.weekday(.abbreviated))), \(yesterday.formatted(.dateTime.day()))"
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", chipStart)).firstMatch.tap()
        pause(2)
        app.navigationBars.buttons["Today"].tap()
        pause()

        // Menu: today, then a past day
        app.tabBars.buttons["Menu"].tap()
        pause(1.5)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", chipStart)).firstMatch.tap()
        pause(2)

        // Back to Home to finish
        app.tabBars.buttons["Home"].tap()
        pause(2)
    }
}
