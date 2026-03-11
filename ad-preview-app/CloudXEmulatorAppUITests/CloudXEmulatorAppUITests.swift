import XCTest

final class CloudXAdPreviewUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch_DefaultWaitingStateVisible() throws {
        let app = XCUIApplication()
        app.launch()

        let statusLabel = app.staticTexts["emu.statusLabel"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(statusLabel.label.contains("Waiting"))

        XCTAssertTrue(app.buttons["emu.clearEventsButton"].exists)
    }

    @MainActor
    func testLaunch_WithDeepLink_UpdatesPlacement() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-emu_deeplink",
            "cloudxemulator://load?app_key=test1234&ad_unit_id=unit_banner&format=banner&env=prod"
        ]
        app.launch()

        let placementLabel = app.staticTexts["emu.placementLabel"]
        XCTAssertTrue(placementLabel.waitForExistence(timeout: 10))
        XCTAssertTrue(placementLabel.label.contains("unit_banner"))

        XCTAssertFalse(app.buttons["emu.showFullscreenButton"].exists)
    }
}
