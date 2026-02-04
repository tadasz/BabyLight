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
    
    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
