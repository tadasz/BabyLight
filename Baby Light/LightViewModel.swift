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

  /// Elapsed time (in seconds) since the app was last opened. Counts up and
  /// resets every time the app becomes active.
  var elapsedSeconds: Int = 0

  // MARK: - Auto Brightness Settings (persisted)

  /// When enabled, the screen dims to minimal brightness when the app closes.
  var dimOnClose: Bool = true {
    didSet { UserDefaults.standard.set(dimOnClose, forKey: "dimOnClose") }
  }

  /// When enabled, the screen brightens to maximum when the app opens.
  var brightenOnOpen: Bool = true {
    didSet { UserDefaults.standard.set(brightenOnOpen, forKey: "brightenOnOpen") }
  }

  /// How much lighter than the background the elapsed-timer text appears.
  /// 0 = same hue as the background (invisible); higher = lighter / more
  /// visible. Adjustable from the controls menu and persisted.
  var timerLightness: CGFloat = 0.2 {
    didSet { UserDefaults.standard.set(Double(timerLightness), forKey: "timerLightness") }
  }

  /// Controls visibility - persisted across launches.
  /// `_controlsVisible` is seeded from `hasLaunchedBefore` in `init()` (shown on
  /// first launch, hidden thereafter); the getter just reflects that state.
  /// (Previously the getter OR'd in `!hasLaunchedBefore`, which permanently
  /// forced controls visible whenever that flag was false — so they could never
  /// be hidden, e.g. when a UI test launches with `-hasLaunchedBefore NO`.)
  var controlsVisible: Bool {
    get { _controlsVisible }
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

  // MARK: - App Usage & Rating

  /// Number of distinct app launches ("uses"), incremented once per cold
  /// start in `init()` and persisted. Used to gate the App Store rating
  /// prompt so we only ask returning users (second use or later).
  private(set) var useCount: Int = 0

  /// Whether we've already shown the native rating prompt. We only ever ask
  /// once, so this stays `true` forever after the first request.
  private var hasRequestedReview: Bool = false

  /// Signals ContentView to present the native StoreKit rating prompt. It is
  /// only raised while the controls overlay is open — a moment when the user
  /// is actively looking at the phone with the screen bright — so the prompt
  /// never appears over the dark light and risks waking a sleeping baby.
  /// ContentView observes this, fires the request, and calls
  /// `didRequestReview()` to clear it.
  var shouldRequestReview: Bool = false

  private var timer: Timer?
  private var elapsedTimer: Timer?

  /// The screen backing the app's active window scene. Replaces the deprecated
  /// `UIScreen.main` (deprecated in iOS 26) by resolving the screen through the
  /// connected-scene hierarchy instead. Prefers the foreground-active scene,
  /// falling back to any connected window scene (e.g. while backgrounding).
  private var activeScreen: UIScreen? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    return scene?.screen
  }

  init() {
    // Initialize brightness from current screen brightness
    brightness = activeScreen?.brightness ?? 1.0
    // Show controls on first launch only
    _controlsVisible = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

    // Load persisted auto-brightness settings (default to enabled)
    if UserDefaults.standard.object(forKey: "dimOnClose") != nil {
      dimOnClose = UserDefaults.standard.bool(forKey: "dimOnClose")
    }
    if UserDefaults.standard.object(forKey: "brightenOnOpen") != nil {
      brightenOnOpen = UserDefaults.standard.bool(forKey: "brightenOnOpen")
    }
    if UserDefaults.standard.object(forKey: "timerLightness") != nil {
      timerLightness = CGFloat(UserDefaults.standard.double(forKey: "timerLightness"))
    }

    // Count this launch as a "use" and remember whether we've already asked
    // for a rating, so the prompt is gated to returning users and shown once.
    useCount = UserDefaults.standard.integer(forKey: "appUseCount") + 1
    UserDefaults.standard.set(useCount, forKey: "appUseCount")
    hasRequestedReview = UserDefaults.standard.bool(forKey: "hasRequestedReview")

    startElapsedTimer()
  }

  // MARK: - Elapsed Timer (counts up from open)

  /// Reset the elapsed counter to zero and start counting up.
  func startElapsedTimer() {
    elapsedTimer?.invalidate()
    elapsedSeconds = 0
    elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.elapsedSeconds += 1
    }
  }

  // MARK: - App Lifecycle

  /// Called when the app becomes active (opened). Resets the elapsed timer and,
  /// if enabled, brightens the screen to maximum.
  func handleAppDidBecomeActive() {
    startElapsedTimer()
    if brightenOnOpen {
      brightness = 1.0
      activeScreen?.brightness = 1.0
    }
  }

  /// Called when the app is about to leave the foreground — home screen, app
  /// switcher, device lock, or a transient interruption (Control Center, an
  /// incoming call). If enabled, dims the screen to minimal brightness.
  ///
  /// The dim happens here, at resign-active, rather than in
  /// `handleAppDidEnterBackground()` below, because iOS only honors
  /// `UIScreen.brightness` writes while the app is still frontmost. By the time
  /// the scene reaches the `.background` phase the window is no longer key and
  /// the write is silently dropped — which is why the previous
  /// background-only implementation never actually dimmed.
  func handleAppWillResignActive() {
    if dimOnClose {
      activeScreen?.brightness = 0.0
    }
  }

  /// Called when the app has fully moved to the background. Re-applies the dim
  /// as a fallback in case the resign-active write didn't take effect.
  func handleAppDidEnterBackground() {
    if dimOnClose {
      activeScreen?.brightness = 0.0
    }
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
    maybeRequestReview()
  }

  /// Toggle controls visibility
  func toggleControls() {
    controlsVisible.toggle()
    if controlsVisible {
      maybeRequestReview()
    }
  }

  // MARK: - Rating

  /// Pure gating rule for the rating prompt: ask only from the second use
  /// onward, and only if we've never asked before. Kept static and
  /// side-effect-free so it can be unit-tested without touching UserDefaults.
  static func shouldPromptForReview(useCount: Int, hasRequestedReview: Bool) -> Bool {
    !hasRequestedReview && useCount >= 2
  }

  /// Flag the native rating prompt for display if the gating rule is met.
  /// Called only when the controls overlay becomes visible — an intentional,
  /// screen-on interaction — so the prompt won't surface over the dim light
  /// while a baby is being settled.
  private func maybeRequestReview() {
    guard Self.shouldPromptForReview(useCount: useCount, hasRequestedReview: hasRequestedReview) else {
      return
    }
    shouldRequestReview = true
  }

  /// Record that the rating prompt has been requested, so it's never shown
  /// again. Called by the view after it presents the StoreKit prompt.
  func didRequestReview() {
    shouldRequestReview = false
    hasRequestedReview = true
    UserDefaults.standard.set(true, forKey: "hasRequestedReview")
  }

  // MARK: - Brightness Control

  /// Adjust brightness by delta (positive = brighter, negative = dimmer)
  /// Allow true minimum (0.0) for darkest possible screen
  func adjustBrightness(delta: CGFloat) {
    brightness = max(0.0, min(1.0, brightness + delta))
    activeScreen?.brightness = brightness
  }
}
