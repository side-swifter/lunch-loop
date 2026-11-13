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
}
