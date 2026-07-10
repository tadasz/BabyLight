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
    if UserDefaults.standard.object(forKey: "sleepTipFineTune") != nil {
      sleepTipFineTuneMinutes = UserDefaults.standard.integer(forKey: "sleepTipFineTune")
    }
    sleepTipBirthMonth = BabyProfile.loadBirthMonth()
    if UserDefaults.standard.object(forKey: "sleepTipEnabled") != nil {
      sleepTipEnabled = UserDefaults.standard.bool(forKey: "sleepTipEnabled")
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
      guard let self = self else { return }
      if let start = self.sessionStart {
        // With a settling session running, the readout derives from the start
        // date instead of counting ticks — ticks don't fire while suspended,
        // and the value must be correct after a short interruption keeps the
        // session alive. `sessionStart` is always nil with the feature off,
        // so that path counts ticks exactly as before.
        let now = Date()
        self.elapsedSeconds = Int(now.timeIntervalSince(start))
        let roundsBefore = self.sleepTipEngine.roundsFired
        self.sleepTipEngine.tick(now: now)
        if self.sleepTipEngine.roundsFired > roundsBefore {
          self.glowCount += 1
        }
      } else {
        self.elapsedSeconds += 1
      }
    }
  }

  // MARK: - Deep Sleep Tip (settling session)

  /// When enabled, opening the app starts a settling session and the elapsed
  /// readout counts from the session start, surviving interruptions shorter
  /// than `maxSessionInterruption` instead of resetting on every activation
  /// (specs/2026-07-10-deep-sleep-tip). Off by default; while off, every code
  /// path of this feature is inert and the app behaves exactly as before.
  var sleepTipEnabled: Bool = false {
    didSet {
      UserDefaults.standard.set(sleepTipEnabled, forKey: "sleepTipEnabled")
      if !sleepTipEnabled {
        endSettlingSession(reason: .manualReset)
      } else {
        // The date picker can't display "unset", so first enable seeds the
        // birth month with today — the newborn bucket has the longest window,
        // which fails in the conservative direction (glow later, never
        // earlier) until the parent picks the real month.
        if sleepTipBirthMonth == nil {
          sleepTipBirthMonth = Date()
        }
        if sessionStart == nil {
          beginSettlingSession()
        }
      }
    }
  }

  /// The baby's birth month backing the age-bucket window lookup; persisted
  /// through `BabyProfile` so the lookup logic stays view-model-free.
  var sleepTipBirthMonth: Date? {
    didSet {
      BabyProfile.save(birthMonth: sleepTipBirthMonth)
      sleepTipEngine.updateBucket(ageBucket(at: Date()))
    }
  }

  /// Parent adjustment on top of the age window, −10…+10 minutes; applies to
  /// the running session as well as future ones.
  var sleepTipFineTuneMinutes: Int = 0 {
    didSet {
      UserDefaults.standard.set(sleepTipFineTuneMinutes, forKey: "sleepTipFineTune")
      sleepTipEngine.updateFineTune(minutes: sleepTipFineTuneMinutes)
    }
  }

  /// Monotonic glow counter driving the pulse animation — bumps once per
  /// fired round and never resets, so a session reset can't retrigger it.
  private(set) var glowCount = 0

  /// True while a glow is pulsing — the only window in which a single tap
  /// acknowledges (AC2).
  func acknowledgeSleepTip(at now: Date = Date()) -> Bool {
    sleepTipEngine.acknowledge(at: now)
  }

  /// Start of the current settling session; nil when none is running
  /// (feature off, session ended by auto-off, or a long interruption).
  private(set) var sessionStart: Date?

  /// The tip state machine — pure, clock-driven; ticked from the elapsed
  /// timer while a session runs.
  private(set) var sleepTipEngine = SleepTipEngine()

  /// Where session records land at session end. `var` so tests can point it
  /// at a temporary file instead of the app container.
  var sessionLog = SessionLog()

  /// When the app last left the foreground with a session running — the
  /// timestamp the interruption rule measures against.
  private var sessionResignedAt: Date?

  /// Interruptions up to this long keep the session (and its tip estimate)
  /// alive; anything longer ends it and the next activation starts fresh.
  static let maxSessionInterruption: TimeInterval = 180

  enum SettlingSessionAction {
    case start    // no session yet → begin one
    case resume   // short interruption → keep the session and its estimate
    case restart  // interruption exceeded the limit → end old, begin fresh
  }

  /// Pure decision rule for what a foreground activation does to the settling
  /// session. Static and side-effect-free so tests can drive it with
  /// simulated dates (same shape as `shouldPromptForReview`).
  static func settlingSessionAction(now: Date, sessionStart: Date?, resignedAt: Date?) -> SettlingSessionAction {
    guard sessionStart != nil else { return .start }
    if let resignedAt, now.timeIntervalSince(resignedAt) > maxSessionInterruption {
      return .restart
    }
    return .resume
  }

  /// Begin a fresh settling session anchored at `now`.
  func beginSettlingSession(at now: Date = Date()) {
    sessionStart = now
    sessionResignedAt = nil
    sleepTipEngine.sessionStarted(at: now, bucket: ageBucket(at: now),
                                  fineTuneMinutes: sleepTipFineTuneMinutes)
    startElapsedTimer()
  }

  /// End the current session (auto-off firing, long interruption, manual
  /// reset, or the feature being switched off), appending one record to the
  /// on-device session log (AC5). The elapsed readout keeps ticking from its
  /// current value — nothing ever stops the on-light clock.
  func endSettlingSession(reason: SessionRecord.EndReason) {
    if let start = sessionStart {
      let record = SessionRecord(
        date: start,
        ageMonths: sleepTipBirthMonth.map { BabyProfile.ageInMonths(birthMonth: $0, now: start) },
        napOrNight: SessionRecord.napOrNight(for: start),
        anchorKind: sleepTipEngine.anchorKind,
        anchorTime: sleepTipEngine.anchorTime ?? start,
        glowTimes: sleepTipEngine.glowTimes,
        cryBouts: [],
        acknowledgeTime: sleepTipEngine.acknowledgeTime,
        outcome: Self.sessionOutcome(glowCount: sleepTipEngine.glowTimes.count, endReason: reason),
        endReason: reason)
      sessionLog.append(record)
    }
    sessionStart = nil
    sessionResignedAt = nil
    sleepTipEngine.sessionEnded()
  }

  /// Manual reset (long-press on the light): ends the running session and
  /// starts a fresh one on the spot — the backup for a missed cue.
  func resetSettlingSession(at now: Date = Date()) {
    guard sleepTipEnabled else { return }
    endSettlingSession(reason: .manualReset)
    beginSettlingSession(at: now)
  }

  /// Phase-1 outcome labeling — the mic-less projection of the calibration
  /// rule (plan task 5.1): a glow followed by a calm background end reads as
  /// a successful put-down; a glow followed by a manual reset means the baby
  /// roused (too early). Everything else is honest `unknown` until the cry
  /// detector can say more. Static and pure so tests hit it directly.
  static func sessionOutcome(glowCount: Int, endReason: SessionRecord.EndReason) -> SessionRecord.Outcome {
    guard glowCount > 0 else { return .unknown }
    switch endReason {
    case .background: return .success
    case .manualReset: return .tooEarly
    case .autoOff: return .unknown
    }
  }

  /// Age bucket for the window lookup; nil when the birth month is unset
  /// (the session still runs and logs, but no glow is scheduled).
  private func ageBucket(at now: Date) -> BabyProfile.AgeBucket? {
    guard let birthMonth = sleepTipBirthMonth else { return nil }
    return BabyProfile.bucket(forAgeMonths: BabyProfile.ageInMonths(birthMonth: birthMonth, now: now))
  }

  // MARK: - App Lifecycle

  /// Session bookkeeping for a foreground activation, separated from the
  /// UIKit brightness side effects so unit tests can drive it with simulated
  /// dates without touching `UIScreen` (which traps off the main queue).
  func applySettlingSessionActivation(now: Date = Date()) {
    guard sleepTipEnabled else {
      startElapsedTimer()
      return
    }
    switch Self.settlingSessionAction(now: now, sessionStart: sessionStart, resignedAt: sessionResignedAt) {
    case .resume:
      sessionResignedAt = nil
      sleepTipEngine.becameActive(at: now)
      // Correct the readout immediately rather than waiting for the next tick.
      if let start = sessionStart {
        elapsedSeconds = Int(now.timeIntervalSince(start))
      }
    case .start:
      beginSettlingSession(at: now)
    case .restart:
      // The old session ended in the background; its record says so.
      endSettlingSession(reason: .background)
      beginSettlingSession(at: now)
    }
  }

  /// Called when the app becomes active (opened). Resets the elapsed timer
  /// (or resumes/starts a settling session when the deep-sleep tip is on) and,
  /// if enabled, brightens the screen to maximum.
  func handleAppDidBecomeActive() {
    applySettlingSessionActivation()
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
    noteSettlingSessionResigned()
    if dimOnClose {
      activeScreen?.brightness = 0.0
    }
  }

  /// Stamps when the app left the foreground with a session running — the
  /// timestamp the interruption rule measures against. Separated from the
  /// brightness side effect for the same testability reason as
  /// `applySettlingSessionActivation(now:)`.
  func noteSettlingSessionResigned(at now: Date = Date()) {
    if sessionStart != nil {
      sessionResignedAt = now
      sleepTipEngine.wentInactive(at: now)
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
        // Auto-off reaching zero also ends any settling session.
        self.endSettlingSession(reason: .autoOff)
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
