//
//  Baby_LightUITests.swift
//  Baby Night LightUITests
//
//  Created by Tadas Ziemys on 1/25/26.
//

import XCTest

final class Baby_LightUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset UserDefaults for consistent test state
        app.launchArguments = ["-hasLaunchedBefore", "NO"]
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Full Screen Red Background Tests
    
    @MainActor
    func testFullScreenRedBackgroundExists() throws {
        app.launch()
        
        // Verify the light background exists
        let lightBackground = app.otherElements["lightBackground"]
        XCTAssertTrue(lightBackground.waitForExistence(timeout: 5), "Light background should exist")
        
        // Verify it's the main light view (red is default)
        let mainLightView = app.otherElements["mainLightView"]
        XCTAssertTrue(mainLightView.exists, "Main light view should exist")
    }
    
    @MainActor
    func testLightBackgroundAccessibilityLabel() throws {
        app.launch()
        
        // Check that the background has the correct accessibility label for Deep Red
        let lightBackground = app.otherElements["lightBackground"]
        XCTAssertTrue(lightBackground.waitForExistence(timeout: 5))
        
        // The default color should be Deep Red
        XCTAssertTrue(lightBackground.label.contains("Deep Red"), 
                      "Default color should be Deep Red, got: \(lightBackground.label)")
    }
    
    // MARK: - Double Tap Menu Toggle Tests
    
    @MainActor
    func testControlsOverlayVisibleOnFirstLaunch() throws {
        app.launch()
        
        // On first launch, controls should be visible
        let controlsOverlay = app.otherElements["controlsOverlay"]
        XCTAssertTrue(controlsOverlay.waitForExistence(timeout: 5), 
                      "Controls overlay should be visible on first launch")
    }
    
    @MainActor
    func testDoubleTapHidesControlsOverlay() throws {
        app.launch()
        
        // Verify controls are initially visible
        let controlsOverlay = app.otherElements["controlsOverlay"]
        XCTAssertTrue(controlsOverlay.waitForExistence(timeout: 5), 
                      "Controls overlay should be visible initially")
        
        // Double tap to hide controls
        let mainLightView = app.otherElements["mainLightView"]
        XCTAssertTrue(mainLightView.waitForExistence(timeout: 5))
        mainLightView.doubleTap()
        
        // Wait for animation and verify controls are hidden
        let controlsHidden = controlsOverlay.waitForNonExistence(timeout: 3)
        XCTAssertTrue(controlsHidden, "Controls overlay should be hidden after double tap")
    }
    
    @MainActor
    func testDoubleTapShowsControlsOverlayAfterHiding() throws {
        app.launch()
        
        let controlsOverlay = app.otherElements["controlsOverlay"]
        let mainLightView = app.otherElements["mainLightView"]
        
        // Wait for initial state
        XCTAssertTrue(controlsOverlay.waitForExistence(timeout: 5))
        XCTAssertTrue(mainLightView.waitForExistence(timeout: 5))
        
        // Double tap to hide
        mainLightView.doubleTap()
        XCTAssertTrue(controlsOverlay.waitForNonExistence(timeout: 3), 
                      "Controls should hide after first double tap")
        
        // Double tap again to show
        mainLightView.doubleTap()
        XCTAssertTrue(controlsOverlay.waitForExistence(timeout: 3), 
                      "Controls should show after second double tap")
    }
    
    @MainActor
    func testDoubleTapToggleCycle() throws {
        app.launch()
        
        let controlsOverlay = app.otherElements["controlsOverlay"]
        let mainLightView = app.otherElements["mainLightView"]
        
        XCTAssertTrue(mainLightView.waitForExistence(timeout: 5))
        
        // Perform multiple toggle cycles
        for i in 0..<3 {
            // Controls should be visible (or we just showed them)
            if i == 0 {
                XCTAssertTrue(controlsOverlay.waitForExistence(timeout: 3), 
                              "Controls should be visible at cycle \(i) start")
            }
            
            // Hide
            mainLightView.doubleTap()
            XCTAssertTrue(controlsOverlay.waitForNonExistence(timeout: 3), 
                          "Controls should be hidden at cycle \(i)")
            
            // Show
            mainLightView.doubleTap()
            XCTAssertTrue(controlsOverlay.waitForExistence(timeout: 3), 
                          "Controls should be visible at cycle \(i) end")
        }
    }
    
    // MARK: - Deep Sleep Tip Tests

    @MainActor
    func testDeepSleepTipSectionAppears() throws {
        // Pin the feature off regardless of persisted state on the test device.
        app.launchArguments += ["-sleepTipEnabled", "NO"]
        app.launch()

        let controlsOverlay = app.otherElements["controlsOverlay"]
        XCTAssertTrue(controlsOverlay.waitForExistence(timeout: 5),
                      "Controls overlay should be visible on first launch")

        let section = app.otherElements["deepSleepTipSection"]
        XCTAssertTrue(section.waitForExistence(timeout: 5),
                      "DEEP SLEEP TIP section should appear in the controls overlay")

        let toggle = app.switches["sleepTipToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5),
                      "Sleep tip toggle should exist")
    }

    @MainActor
    func testDeepSleepTipOffByDefaultAndGesturesUnchanged() throws {
        // Feature-off parity (spec AC4): with the tip off, the pre-existing
        // gesture surface behaves exactly as before the feature existed.
        app.launchArguments += ["-sleepTipEnabled", "NO"]
        app.launch()

        let toggle = app.switches["sleepTipToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "0",
                       "Deep sleep tip must be off by default")

        // Double-tap still hides and re-shows the controls.
        let controlsOverlay = app.otherElements["controlsOverlay"]
        let mainLightView = app.otherElements["mainLightView"]
        XCTAssertTrue(mainLightView.waitForExistence(timeout: 5))
        mainLightView.doubleTap()
        XCTAssertTrue(controlsOverlay.waitForNonExistence(timeout: 3),
                      "Double-tap must still hide the controls with the tip off")
        mainLightView.doubleTap()
        XCTAssertTrue(controlsOverlay.waitForExistence(timeout: 3),
                      "Double-tap must still show the controls with the tip off")
    }

    @MainActor
    func testDeepSleepTipControlsRespondWhileOverlayVisible() throws {
        // Regression: the settling-time gestures on the light surface must not
        // swallow taps meant for the section's date picker / stepper while the
        // overlay is open (found in TestFlight 28 dogfood).
        app.launchArguments += ["-sleepTipEnabled", "YES", "-sleepTipFineTune", "0"]
        app.launch()

        let stepper = app.steppers["sleepTipFineTuneStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5), "Fine-tune stepper should exist with the feature on")
        XCTAssertTrue(app.staticTexts["0m"].waitForExistence(timeout: 3), "Fine-tune starts at 0m")

        // The plus half of the stepper (labels differ across OS versions, so
        // tap by position rather than by button identifier).
        stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["+1m"].waitForExistence(timeout: 3),
                      "Stepper must respond to taps while the controls overlay is visible")
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
