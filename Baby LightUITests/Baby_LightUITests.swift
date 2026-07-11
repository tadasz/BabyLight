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
    func testDeepSleepTipDatePickerOpensCalendarFirstRunFlow() throws {
        // Isolation variant: controls visible at launch (no double-tap) and
        // the rating prompt suppressed, so neither TipKit nor StoreKit can
        // interfere — probes the picker itself.
        app.launchArguments = ["-hasLaunchedBefore", "NO",
                               "-hasRequestedReview", "YES",
                               "-sleepTipEnabled", "YES", "-sleepTipFineTune", "0"]
        app.launch()

        // On a truly first launch the TipKit tutorial popover covers part of
        // the panel — dismiss it so this test probes the picker, not the tip.
        let tipClose = app.buttons["Close"]
        if tipClose.waitForExistence(timeout: 2) {
            tipClose.tap()
        }

        let picker = app.datePickers["sleepTipBirthMonthPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 8), "Birthday picker should be visible")
        picker.tap()
        XCTAssertTrue(app.buttons["Next Month"].waitForExistence(timeout: 3),
                      "Tapping the birthday picker must open the calendar popover")
    }

    @MainActor
    func testDeepSleepTipStepperFirstRunFlow() throws {
        app.launchArguments = ["-hasLaunchedBefore", "NO",
                               "-hasRequestedReview", "YES",
                               "-sleepTipEnabled", "YES", "-sleepTipFineTune", "0"]
        app.launch()

        let stepper = app.steppers["sleepTipFineTuneStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 8))
        stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["+1m"].waitForExistence(timeout: 3),
                      "Stepper must respond with gestures active and no system overlays")
    }

    // NOTE ON DOUBLE-TAP: the picker/stepper regression is verified via the
    // two *FirstRunFlow tests above, which open the panel via first-launch
    // (controls already visible) and then use a real single `.tap()` on each
    // control. That single tap is the exact interaction that was broken
    // (TestFlight 28–29: an ancestor zero-distance drag swallowed it) and now
    // works. A double-tap-to-open variant was intentionally dropped: XCUITest's
    // synthetic doubleTap() is unreliable on the iOS 26.5 simulator (a
    // pre-existing, feature-independent quirk — testDoubleTapHidesControlsOverlay
    // fails there too), which would make the test flaky without adding coverage
    // of the picker/stepper themselves.

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
