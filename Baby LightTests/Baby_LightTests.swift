//
//  Baby_LightTests.swift
//  Baby Night LightTests
//
//  Created by Tadas Ziemys on 1/25/26.
//

import Testing
import Foundation
@testable import Baby_Night_Light

struct Baby_LightTests {
    
    // MARK: - LightViewModel Initial State Tests
    
    @Test func viewModelInitialColorIsDeepRed() async throws {
        let viewModel = LightViewModel()
        #expect(viewModel.currentColor.id == "deep-red")
        #expect(viewModel.currentColor.name == "Deep Red")
    }
    
    @Test func viewModelInitialTimerIsInfinite() async throws {
        let viewModel = LightViewModel()
        #expect(viewModel.selectedTimer.minutes == nil)
        #expect(viewModel.timeRemaining == nil)
    }
    
    @Test func viewModelInitialScreenIsNotOff() async throws {
        let viewModel = LightViewModel()
        #expect(viewModel.isScreenOff == false)
    }
    
    // MARK: - Color Selection Tests
    
    @Test func viewModelCanChangeColor() async throws {
        let viewModel = LightViewModel()
        let amberColor = LightColor.presets[1]
        viewModel.currentColor = amberColor
        #expect(viewModel.currentColor.id == "amber")
    }
    
    // MARK: - Timer Tests
    
    @Test func viewModelSetTimerUpdatesTimeRemaining() async throws {
        let viewModel = LightViewModel()
        // options are: ∞, 15m, 30m, 1h, 2h — index 2 is the 30 minute preset
        let thirtyMinOption = TimerOption.options[2]
        #expect(thirtyMinOption.minutes == 30)
        viewModel.setTimer(thirtyMinOption)
        #expect(viewModel.timeRemaining == 30 * 60)
    }
    
    @Test func viewModelInfiniteTimerHasNilTimeRemaining() async throws {
        let viewModel = LightViewModel()
        let infiniteOption = TimerOption.options[0]
        viewModel.setTimer(infiniteOption)
        #expect(viewModel.timeRemaining == nil)
    }
    
    @Test func viewModelScreenOffWhenTimerReachesZero() async throws {
        let viewModel = LightViewModel()
        // Simulate timer reaching 0
        viewModel.setTimer(TimerOption.options[1])
        // Manually set to 0 to test screen off state
        viewModel.timeRemaining = 0
        #expect(viewModel.isScreenOff == true)
    }
    
    // MARK: - Format Time Tests
    
    @Test func formatTimeReturnsEmptyForNil() async throws {
        let viewModel = LightViewModel()
        #expect(viewModel.formatTime(nil) == "")
    }
    
    @Test func formatTimeFormatsMinutesAndSeconds() async throws {
        let viewModel = LightViewModel()
        #expect(viewModel.formatTime(90) == "1:30")
        #expect(viewModel.formatTime(60) == "1:00")
        #expect(viewModel.formatTime(59) == "0:59")
    }
    
    @Test func formatTimeFormatsHoursMinutesAndSeconds() async throws {
        let viewModel = LightViewModel()
        #expect(viewModel.formatTime(3661) == "1:01:01")
        #expect(viewModel.formatTime(3600) == "1:00:00")
    }
    
    // MARK: - Wake Up Tests
    
    @Test func wakeUpResetsTimerAndShowsControls() async throws {
        let viewModel = LightViewModel()
        viewModel.setTimer(TimerOption.options[1])
        viewModel.timeRemaining = 0
        #expect(viewModel.isScreenOff == true)
        
        viewModel.wakeUp()
        #expect(viewModel.isScreenOff == false)
        #expect(viewModel.timeRemaining == nil)
    }
    
    // MARK: - Toggle Controls Tests
    
    @Test func toggleControlsChangesVisibility() async throws {
        let viewModel = LightViewModel()
        let initialState = viewModel.controlsVisible
        viewModel.toggleControls()
        #expect(viewModel.controlsVisible != initialState)
    }
    
    // MARK: - Brightness Tests
    
    @Test func adjustBrightnessIncreasesValue() async throws {
        let viewModel = LightViewModel()
        let initialBrightness = viewModel.brightness
        viewModel.adjustBrightness(delta: 0.1)
        #expect(viewModel.brightness > initialBrightness || viewModel.brightness == 1.0)
    }
    
    @Test func adjustBrightnessDecreasesValue() async throws {
        let viewModel = LightViewModel()
        viewModel.brightness = 0.5
        viewModel.adjustBrightness(delta: -0.1)
        #expect(viewModel.brightness < 0.5)
    }
    
    @Test func adjustBrightnessClampsToMinimum() async throws {
        let viewModel = LightViewModel()
        viewModel.brightness = 0.1
        viewModel.adjustBrightness(delta: -1.0)
        #expect(viewModel.brightness == 0.0)
    }
    
    @Test func adjustBrightnessClampsToMaximum() async throws {
        let viewModel = LightViewModel()
        viewModel.brightness = 0.9
        viewModel.adjustBrightness(delta: 1.0)
        #expect(viewModel.brightness == 1.0)
    }
}

// MARK: - Rating Prompt Tests

struct ReviewPromptTests {

    @Test func doesNotPromptOnFirstUse() async throws {
        #expect(LightViewModel.shouldPromptForReview(useCount: 1, hasRequestedReview: false) == false)
    }

    @Test func promptsOnSecondUse() async throws {
        #expect(LightViewModel.shouldPromptForReview(useCount: 2, hasRequestedReview: false) == true)
    }

    @Test func promptsOnLaterUses() async throws {
        #expect(LightViewModel.shouldPromptForReview(useCount: 7, hasRequestedReview: false) == true)
    }

    @Test func doesNotPromptOnceAlreadyRequested() async throws {
        #expect(LightViewModel.shouldPromptForReview(useCount: 5, hasRequestedReview: true) == false)
    }

    @Test func didRequestReviewClearsPendingFlag() async throws {
        let viewModel = LightViewModel()
        viewModel.shouldRequestReview = true
        viewModel.didRequestReview()
        #expect(viewModel.shouldRequestReview == false)
    }
}

// MARK: - LightColor Tests

struct LightColorTests {

    @Test func presetsContainFourColors() async throws {
        #expect(LightColor.presets.count == 4)
    }
    
    @Test func firstPresetIsDeepRed() async throws {
        let firstColor = LightColor.presets[0]
        #expect(firstColor.id == "deep-red")
        #expect(firstColor.name == "Deep Red")
    }
    
    @Test func allPresetsHaveUniqueIds() async throws {
        let ids = LightColor.presets.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }
}

// MARK: - TimerOption Tests

struct TimerOptionTests {
    
    @Test func optionsContainFiveTimers() async throws {
        #expect(TimerOption.options.count == 5)
    }
    
    @Test func firstOptionIsInfinite() async throws {
        let firstOption = TimerOption.options[0]
        #expect(firstOption.minutes == nil)
        #expect(firstOption.label == "∞")
    }
    
    @Test func allOptionsHaveUniqueIds() async throws {
        let ids = TimerOption.options.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }
}
