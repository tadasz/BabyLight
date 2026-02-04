//
//  LightViewModel.swift
//  Baby Night Light
//

import Observation
import SwiftUI

/// Main view model managing app state
@Observable
class LightViewModel {
  // MARK: - State
  var currentColor: LightColor = LightColor.presets[0]
  var selectedTimer: TimerOption = TimerOption.options[0]
  var timeRemaining: Int? = nil
  var brightness: CGFloat = 1.0

  /// Controls visibility - persisted across launches
  var controlsVisible: Bool {
    get { !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") || _controlsVisible }
    set {
      _controlsVisible = newValue
      // Mark that app has launched before (so controls hidden on future launches)
      if !newValue {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
      }
    }
  }
  private var _controlsVisible: Bool = false

  /// Screen is "off" when timer reaches exactly 0
  var isScreenOff: Bool {
    timeRemaining == 0
  }

  private var timer: Timer?

  init() {
    // Initialize brightness from current screen brightness
    brightness = UIScreen.main.brightness
    // Show controls on first launch only
    _controlsVisible = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
  }

  // MARK: - Timer Logic

  /// Set a new timer, starting countdown if not infinite
  func setTimer(_ option: TimerOption) {
    selectedTimer = option
    timer?.invalidate()
    timer = nil

    if let minutes = option.minutes {
      timeRemaining = minutes * 60
      startCountdown()
    } else {
      timeRemaining = nil
    }
  }

  private func startCountdown() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self = self else { return }

      if let remaining = self.timeRemaining, remaining > 0 {
        self.timeRemaining = remaining - 1
      } else if self.timeRemaining == 0 {
        // Timer finished, keep at 0 for screen-off state
        self.timer?.invalidate()
        self.timer = nil
      }
    }
  }

  /// Format seconds into MM:SS or H:MM:SS
  func formatTime(_ seconds: Int?) -> String {
    guard let seconds = seconds else { return "" }

    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60

    if h > 0 {
      return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
  }

  /// Wake up from screen-off state
  func wakeUp() {
    timer?.invalidate()
    timer = nil
    selectedTimer = TimerOption.options[0]  // Reset to infinite
    timeRemaining = nil
    _controlsVisible = true
  }

  /// Toggle controls visibility
  func toggleControls() {
    controlsVisible = !controlsVisible
  }

  // MARK: - Brightness Control

  /// Adjust brightness by delta (positive = brighter, negative = dimmer)
  /// Allow true minimum (0.01) for darkest possible screen
  func adjustBrightness(delta: CGFloat) {
    brightness = max(0.0, min(1.0, brightness + delta))
    UIScreen.main.brightness = brightness
  }
}
