//
//  SleepTipTests.swift
//  Baby Night LightTests
//

import Testing
import Foundation
@testable import Baby_Night_Light

// MARK: - BabyProfile: age buckets & windows

struct BabyProfileTests {

  @Test func bucketBoundaries() async throws {
    #expect(BabyProfile.bucket(forAgeMonths: 0) == .months0to3)
    #expect(BabyProfile.bucket(forAgeMonths: 2) == .months0to3)
    #expect(BabyProfile.bucket(forAgeMonths: 3) == .months3to6)
    #expect(BabyProfile.bucket(forAgeMonths: 5) == .months3to6)
    #expect(BabyProfile.bucket(forAgeMonths: 6) == .months6to12)
    #expect(BabyProfile.bucket(forAgeMonths: 11) == .months6to12)
    #expect(BabyProfile.bucket(forAgeMonths: 12) == .months12plus)
    #expect(BabyProfile.bucket(forAgeMonths: 24) == .months12plus)
  }

  @Test func appOpenWindows() async throws {
    #expect(BabyProfile.windowMinutes(for: .months0to3, anchor: .appOpen) == 35)
    #expect(BabyProfile.windowMinutes(for: .months3to6, anchor: .appOpen) == 30)
    #expect(BabyProfile.windowMinutes(for: .months6to12, anchor: .appOpen) == 25)
    #expect(BabyProfile.windowMinutes(for: .months12plus, anchor: .appOpen) == 20)
  }

  @Test func cryCessationWindows() async throws {
    #expect(BabyProfile.windowMinutes(for: .months0to3, anchor: .cryCessation) == 20)
    #expect(BabyProfile.windowMinutes(for: .months3to6, anchor: .cryCessation) == 15)
    #expect(BabyProfile.windowMinutes(for: .months6to12, anchor: .cryCessation) == 10)
    #expect(BabyProfile.windowMinutes(for: .months12plus, anchor: .cryCessation) == 10)
  }

  @Test func ageInMonthsCountsWholeCalendarMonths() async throws {
    let calendar = Calendar.current
    let birth = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
    let beforeAnniversary = calendar.date(from: DateComponents(year: 2026, month: 7, day: 10))!
    let onAnniversary = calendar.date(from: DateComponents(year: 2026, month: 7, day: 15))!
    #expect(BabyProfile.ageInMonths(birthMonth: birth, now: beforeAnniversary) == 5)
    #expect(BabyProfile.ageInMonths(birthMonth: birth, now: onAnniversary) == 6)
  }

  @Test func ageInMonthsClampsFutureBirthMonth() async throws {
    let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
    let future = now.addingTimeInterval(90 * 24 * 3600)
    #expect(BabyProfile.ageInMonths(birthMonth: future, now: now) == 0)
  }
}

// MARK: - Settling session: pure decision rule (simulated clock)

struct SettlingSessionRuleTests {

  let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

  @Test func startsWhenNoSessionRunning() async throws {
    #expect(LightViewModel.settlingSessionAction(now: t0, sessionStart: nil, resignedAt: nil) == .start)
  }

  @Test func resumesWhenNeverResigned() async throws {
    let action = LightViewModel.settlingSessionAction(
      now: t0.addingTimeInterval(600), sessionStart: t0, resignedAt: nil)
    #expect(action == .resume)
  }

  @Test func resumesAfterShortInterruption() async throws {
    let resigned = t0.addingTimeInterval(600)
    let action = LightViewModel.settlingSessionAction(
      now: resigned.addingTimeInterval(120), sessionStart: t0, resignedAt: resigned)
    #expect(action == .resume)
  }

  @Test func resumesAtExactInterruptionLimit() async throws {
    let resigned = t0.addingTimeInterval(600)
    let action = LightViewModel.settlingSessionAction(
      now: resigned.addingTimeInterval(LightViewModel.maxSessionInterruption),
      sessionStart: t0, resignedAt: resigned)
    #expect(action == .resume)
  }

  @Test func restartsAfterLongInterruption() async throws {
    let resigned = t0.addingTimeInterval(600)
    let action = LightViewModel.settlingSessionAction(
      now: resigned.addingTimeInterval(LightViewModel.maxSessionInterruption + 1),
      sessionStart: t0, resignedAt: resigned)
    #expect(action == .restart)
  }
}

// MARK: - Settling session: view-model lifecycle (simulated clock)

/// Serialized: these tests flip the persisted `sleepTipEnabled` flag, so they
/// must not interleave with each other or race a parallel `LightViewModel()`
/// init reading the flag mid-flip.
@Suite(.serialized)
struct SettlingSessionLifecycleTests {

  let t0 = Date(timeIntervalSinceReferenceDate: 2_000_000)

  /// Flips the feature on for the duration of `body` with the session log
  /// pointed at a throwaway file, then restores the persisted flag so other
  /// tests see an untouched UserDefaults.
  private func withSleepTipEnabled(_ body: (LightViewModel) -> Void) {
    let viewModel = LightViewModel()
    viewModel.sessionLog = SessionLog(fileURL: FileManager.default.temporaryDirectory
      .appendingPathComponent("SleepTipTests-\(UUID().uuidString).json"))
    viewModel.sleepTipEnabled = true
    body(viewModel)
    viewModel.sleepTipEnabled = false
    UserDefaults.standard.removeObject(forKey: "sleepTipEnabled")
  }

  @Test func enablingFeatureStartsSession() async throws {
    withSleepTipEnabled { viewModel in
      #expect(viewModel.sessionStart != nil)
    }
  }

  @Test func shortInterruptionKeepsSession() async throws {
    withSleepTipEnabled { viewModel in
      viewModel.beginSettlingSession(at: t0)
      viewModel.noteSettlingSessionResigned(at: t0.addingTimeInterval(600))
      viewModel.applySettlingSessionActivation(now: t0.addingTimeInterval(700))
      #expect(viewModel.sessionStart == t0)
      #expect(viewModel.elapsedSeconds == 700)
    }
  }

  @Test func longInterruptionStartsFreshSession() async throws {
    withSleepTipEnabled { viewModel in
      viewModel.beginSettlingSession(at: t0)
      viewModel.noteSettlingSessionResigned(at: t0.addingTimeInterval(600))
      let comeback = t0.addingTimeInterval(600 + LightViewModel.maxSessionInterruption + 60)
      viewModel.applySettlingSessionActivation(now: comeback)
      #expect(viewModel.sessionStart == comeback)
      // The expired session was logged as ending in the background.
      #expect(viewModel.sessionLog.load().last?.endReason == .background)
    }
  }

  @Test func manualResetStartsFreshSession() async throws {
    withSleepTipEnabled { viewModel in
      viewModel.beginSettlingSession(at: t0)
      let resetTime = t0.addingTimeInterval(500)
      viewModel.resetSettlingSession(at: resetTime)
      #expect(viewModel.sessionStart == resetTime)
      #expect(viewModel.sessionLog.load().last?.endReason == .manualReset)
    }
  }

  @Test func disablingFeatureEndsSession() async throws {
    let viewModel = LightViewModel()
    viewModel.sessionLog = SessionLog(fileURL: FileManager.default.temporaryDirectory
      .appendingPathComponent("SleepTipTests-\(UUID().uuidString).json"))
    viewModel.sleepTipEnabled = true
    viewModel.beginSettlingSession(at: t0)
    viewModel.sleepTipEnabled = false
    UserDefaults.standard.removeObject(forKey: "sleepTipEnabled")
    #expect(viewModel.sessionStart == nil)
  }

  @Test func endSettlingSessionClearsState() async throws {
    withSleepTipEnabled { viewModel in
      viewModel.beginSettlingSession(at: t0)
      viewModel.endSettlingSession(reason: .manualReset)
      #expect(viewModel.sessionStart == nil)
    }
  }

  @Test func glowMinutesCaptionReflectsBucketAndOffset() async throws {
    withSleepTipEnabled { viewModel in
      let eightMonthsAgo = Calendar.current.date(byAdding: .month, value: -8, to: Date())!
      viewModel.sleepTipBirthMonth = eightMonthsAgo
      #expect(viewModel.sleepTipGlowMinutes == 25)  // 6–12 mo appOpen window
      viewModel.sleepTipFineTuneMinutes = 5
      #expect(viewModel.sleepTipGlowMinutes == 30)
      viewModel.sleepTipBirthMonth = nil
      #expect(viewModel.sleepTipGlowMinutes == nil)
    }
    UserDefaults.standard.removeObject(forKey: BabyProfile.birthMonthKey)
    UserDefaults.standard.removeObject(forKey: "sleepTipFineTune")
  }

  @Test func doubleTapSuppressedRightAfterFineTuneTap() async throws {
    // Reproduction: rapid −/+ taps register as a double-tap on the light
    // surface and dismiss the controls. The toggle is suppressed within
    // `controlToggleSuppressWindow` of a fine-tune tap.
    let t = Date(timeIntervalSinceReferenceDate: 5_000_000)
    #expect(LightViewModel.shouldToggleControls(now: t, lastFineTuneChangeAt: t) == false)
    #expect(LightViewModel.shouldToggleControls(
      now: t.addingTimeInterval(LightViewModel.controlToggleSuppressWindow - 0.01),
      lastFineTuneChangeAt: t) == false)
  }

  @Test func doubleTapTogglesAfterWindowOrWithNoFineTune() async throws {
    let t = Date(timeIntervalSinceReferenceDate: 5_000_000)
    #expect(LightViewModel.shouldToggleControls(now: t, lastFineTuneChangeAt: nil) == true)
    #expect(LightViewModel.shouldToggleControls(
      now: t.addingTimeInterval(LightViewModel.controlToggleSuppressWindow + 0.05),
      lastFineTuneChangeAt: t) == true)
  }

  @Test func adjustFineTuneClampsAndStamps() async throws {
    withSleepTipEnabled { viewModel in
      viewModel.beginSettlingSession(at: t0)
      viewModel.adjustFineTune(by: 1, now: t0)
      #expect(viewModel.sleepTipFineTuneMinutes == 1)
      // Clamp at +10.
      for _ in 0..<20 { viewModel.adjustFineTune(by: 1, now: t0) }
      #expect(viewModel.sleepTipFineTuneMinutes == 10)
      for _ in 0..<40 { viewModel.adjustFineTune(by: -1, now: t0) }
      #expect(viewModel.sleepTipFineTuneMinutes == -10)
      // A double-tap at the same instant is suppressed; controls don't toggle.
      let before = viewModel.controlsVisible
      viewModel.toggleControls(now: t0)
      #expect(viewModel.controlsVisible == before)
    }
    UserDefaults.standard.removeObject(forKey: "sleepTipFineTune")
  }

  @Test func fineTuneAppliesToRunningSession() async throws {
    withSleepTipEnabled { viewModel in
      viewModel.beginSettlingSession(at: t0)
      viewModel.sleepTipFineTuneMinutes = 5
      #expect(viewModel.sleepTipEngine.fineTuneMinutes == 5)
    }
    UserDefaults.standard.removeObject(forKey: "sleepTipFineTune")
  }

  @Test func endingSessionAppendsOneRecord() async throws {
    withSleepTipEnabled { viewModel in
      viewModel.beginSettlingSession(at: t0)
      viewModel.endSettlingSession(reason: .autoOff)
      let records = viewModel.sessionLog.load()
      // The helper's initial enable already logged nothing (its session is
      // still open when body runs), so this session's record is the last one.
      #expect(records.last?.date == t0)
      #expect(records.last?.endReason == .autoOff)
      #expect(records.last?.anchorKind == .appOpen)
      #expect(records.last?.cryBouts.isEmpty == true)
    }
  }

  @Test func featureOffActivationResetsElapsedAsToday() async throws {
    let viewModel = LightViewModel()
    viewModel.sleepTipEnabled = false
    UserDefaults.standard.removeObject(forKey: "sleepTipEnabled")
    viewModel.elapsedSeconds = 42
    viewModel.applySettlingSessionActivation(now: t0)
    #expect(viewModel.elapsedSeconds == 0)
    #expect(viewModel.sessionStart == nil)
  }
}

// MARK: - SleepTipEngine (simulated clock)

struct SleepTipEngineTests {

  let t0 = Date(timeIntervalSinceReferenceDate: 3_000_000)

  private func startedEngine(bucket: BabyProfile.AgeBucket? = .months6to12,
                             fineTuneMinutes: Int = 0) -> SleepTipEngine {
    var engine = SleepTipEngine()
    engine.sessionStarted(at: t0, bucket: bucket, fineTuneMinutes: fineTuneMinutes)
    return engine
  }

  @Test func glowFiresAtAgeWindowPerBucket() async throws {
    let expected: [(BabyProfile.AgeBucket, Int)] = [
      (.months0to3, 35), (.months3to6, 30), (.months6to12, 25), (.months12plus, 20),
    ]
    for (bucket, minutes) in expected {
      var engine = startedEngine(bucket: bucket)
      engine.tick(now: t0.addingTimeInterval(TimeInterval(minutes * 60 - 1)))
      #expect(engine.state == .settling, "bucket \(bucket) glowed early")
      engine.tick(now: t0.addingTimeInterval(TimeInterval(minutes * 60)))
      #expect(engine.state == .tipDue(round: 1), "bucket \(bucket) missed its window")
    }
  }

  @Test func fineTuneShiftsGlow() async throws {
    var later = startedEngine(fineTuneMinutes: 10)
    later.tick(now: t0.addingTimeInterval(25 * 60))
    #expect(later.state == .settling)
    later.tick(now: t0.addingTimeInterval(35 * 60))
    #expect(later.state == .tipDue(round: 1))

    var earlier = startedEngine(fineTuneMinutes: -10)
    earlier.tick(now: t0.addingTimeInterval(15 * 60))
    #expect(earlier.state == .tipDue(round: 1))
  }

  @Test func noBirthMonthNeverGlows() async throws {
    var engine = startedEngine(bucket: nil)
    engine.tick(now: t0.addingTimeInterval(10 * 3600))
    #expect(engine.state == .settling)
    #expect(engine.glowTimes.isEmpty)
  }

  @Test func repeatsEveryFiveMinutesMaxFourRounds() async throws {
    var engine = startedEngine()
    let firstTip = 25 * 60
    for round in 1...4 {
      engine.tick(now: t0.addingTimeInterval(TimeInterval(firstTip + (round - 1) * 300)))
      #expect(engine.state == .tipDue(round: round))
    }
    engine.tick(now: t0.addingTimeInterval(TimeInterval(firstTip + 4 * 300)))
    #expect(engine.state == .tipDue(round: 4))
    #expect(engine.glowTimes.count == 4)
  }

  @Test func acknowledgeOnlyWhilePulsing() async throws {
    var engine = startedEngine()
    let glowAt = t0.addingTimeInterval(25 * 60)
    engine.tick(now: glowAt)

    var lateEngine = engine
    #expect(lateEngine.acknowledge(at: glowAt.addingTimeInterval(10)) == false)
    #expect(lateEngine.state == .tipDue(round: 1))

    #expect(engine.acknowledge(at: glowAt.addingTimeInterval(3)) == true)
    #expect(engine.state == .acknowledged)
    #expect(engine.acknowledgeTime == glowAt.addingTimeInterval(3))
  }

  @Test func acknowledgeStopsFurtherGlows() async throws {
    var engine = startedEngine()
    let glowAt = t0.addingTimeInterval(25 * 60)
    engine.tick(now: glowAt)
    engine.acknowledge(at: glowAt.addingTimeInterval(2))
    engine.tick(now: glowAt.addingTimeInterval(600))
    #expect(engine.state == .acknowledged)
    #expect(engine.glowTimes.count == 1)
  }

  @Test func goingInactiveStopsPulsing() async throws {
    var engine = startedEngine()
    let glowAt = t0.addingTimeInterval(25 * 60)
    engine.tick(now: glowAt)
    engine.wentInactive(at: glowAt.addingTimeInterval(1))
    #expect(engine.state == .settling)
    // Rounds already fired are preserved: the next glow is round 2, on its
    // original 5-minute schedule.
    engine.becameActive(at: glowAt.addingTimeInterval(60))
    engine.tick(now: glowAt.addingTimeInterval(299))
    #expect(engine.state == .settling)
    engine.tick(now: glowAt.addingTimeInterval(300))
    #expect(engine.state == .tipDue(round: 2))
  }

  @Test func cryBoutOverridesAnchor() async throws {
    var engine = startedEngine()  // 6–12 mo: appOpen 25 min, cryCessation 10 min
    engine.cryBoutConfirmed(at: t0.addingTimeInterval(5 * 60))
    // While the bout runs, the original window passing must not glow.
    engine.tick(now: t0.addingTimeInterval(26 * 60))
    #expect(engine.state == .settling)

    let boutEnd = t0.addingTimeInterval(30 * 60)
    engine.cryBoutEnded(at: boutEnd)
    #expect(engine.anchorKind == .cryCessation)
    engine.tick(now: boutEnd.addingTimeInterval(10 * 60 - 1))
    #expect(engine.state == .settling)
    engine.tick(now: boutEnd.addingTimeInterval(10 * 60))
    #expect(engine.state == .tipDue(round: 1))
  }

  @Test func newBoutClearsShownTipAndReArms() async throws {
    var engine = startedEngine()
    engine.tick(now: t0.addingTimeInterval(25 * 60))
    #expect(engine.state == .tipDue(round: 1))

    engine.cryBoutConfirmed(at: t0.addingTimeInterval(26 * 60))
    #expect(engine.state == .settling)

    let boutEnd = t0.addingTimeInterval(40 * 60)
    engine.cryBoutEnded(at: boutEnd)
    engine.tick(now: boutEnd.addingTimeInterval(10 * 60))
    // Fresh rounds from the new anchor — round 1 again, not round 2.
    #expect(engine.state == .tipDue(round: 1))
  }

  @Test func manualResetReArmsFromNow() async throws {
    var engine = startedEngine()
    engine.tick(now: t0.addingTimeInterval(25 * 60))
    let resetAt = t0.addingTimeInterval(27 * 60)
    engine.manualReset(at: resetAt)
    #expect(engine.state == .settling)
    #expect(engine.anchorKind == .appOpen)
    #expect(engine.glowTimes.isEmpty)
    engine.tick(now: resetAt.addingTimeInterval(25 * 60))
    #expect(engine.state == .tipDue(round: 1))
  }
}

// MARK: - SessionLog

struct SessionLogTests {

  private func temporaryLog() -> SessionLog {
    SessionLog(fileURL: FileManager.default.temporaryDirectory
      .appendingPathComponent("SessionLogTests-\(UUID().uuidString).json"))
  }

  private func record(date: Date) -> SessionRecord {
    SessionRecord(
      date: date,
      ageMonths: 7,
      napOrNight: .night,
      anchorKind: .appOpen,
      anchorTime: date,
      glowTimes: [date.addingTimeInterval(1500)],
      cryBouts: [SessionRecord.CryBout(start: date.addingTimeInterval(60),
                                       end: date.addingTimeInterval(120))],
      acknowledgeTime: date.addingTimeInterval(1502),
      outcome: .success,
      endReason: .background)
  }

  @Test func recordRoundTripsThroughDisk() async throws {
    let log = temporaryLog()
    let original = record(date: Date(timeIntervalSinceReferenceDate: 4_000_000))
    log.append(original)
    #expect(log.load() == [original])
  }

  @Test func ringBufferCapsAtCapacity() async throws {
    let log = temporaryLog()
    let base = Date(timeIntervalSinceReferenceDate: 4_000_000)
    for i in 0..<(SessionLog.capacity + 5) {
      log.append(record(date: base.addingTimeInterval(TimeInterval(i))))
    }
    let records = log.load()
    #expect(records.count == SessionLog.capacity)
    // Oldest five dropped; the newest survives.
    #expect(records.first?.date == base.addingTimeInterval(5))
    #expect(records.last?.date == base.addingTimeInterval(TimeInterval(SessionLog.capacity + 4)))
  }

  @Test func napOrNightSplitsByClockHour() async throws {
    let calendar = Calendar.current
    func date(hour: Int) -> Date {
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: hour))!
    }
    #expect(SessionRecord.napOrNight(for: date(hour: 3)) == .night)
    #expect(SessionRecord.napOrNight(for: date(hour: 7)) == .nap)
    #expect(SessionRecord.napOrNight(for: date(hour: 14)) == .nap)
    #expect(SessionRecord.napOrNight(for: date(hour: 19)) == .night)
  }
}

// MARK: - Phase-1 outcome rule

struct SessionOutcomeTests {

  @Test func noGlowIsUnknown() async throws {
    #expect(LightViewModel.sessionOutcome(glowCount: 0, endReason: .background) == .unknown)
  }

  @Test func glowThenCalmBackgroundEndIsSuccess() async throws {
    #expect(LightViewModel.sessionOutcome(glowCount: 1, endReason: .background) == .success)
  }

  @Test func glowThenManualResetIsTooEarly() async throws {
    #expect(LightViewModel.sessionOutcome(glowCount: 2, endReason: .manualReset) == .tooEarly)
  }

  @Test func glowThenAutoOffIsUnknown() async throws {
    #expect(LightViewModel.sessionOutcome(glowCount: 1, endReason: .autoOff) == .unknown)
  }
}

// MARK: - CryBoutTracker: cry debounce (Phase 2)

struct CryBoutTrackerTests {

  let t0 = Date(timeIntervalSinceReferenceDate: 4_000_000)
  private let cry = 0.8    // above the 0.6 confidence gate
  private let quiet = 0.0

  @Test func threePositiveWindowsConfirmABout() async throws {
    var tracker = CryBoutTracker()
    #expect(tracker.observe(confidence: cry, at: t0) == nil)
    #expect(tracker.observe(confidence: cry, at: t0.addingTimeInterval(0.75)) == nil)
    #expect(tracker.observe(confidence: cry, at: t0.addingTimeInterval(1.5)) == .boutConfirmed)
    #expect(tracker.inBout)
  }

  @Test func isolatedGruntsNeverConfirm() async throws {
    var tracker = CryBoutTracker()
    // Two positives then quiet — below the 3-in-10s threshold (AC6).
    _ = tracker.observe(confidence: cry, at: t0)
    _ = tracker.observe(confidence: cry, at: t0.addingTimeInterval(1))
    for i in 1...20 {
      #expect(tracker.observe(confidence: quiet, at: t0.addingTimeInterval(Double(i))) == nil)
    }
    #expect(!tracker.inBout)
  }

  @Test func positivesSpacedBeyondWindowNeverAccumulate() async throws {
    var tracker = CryBoutTracker()
    // Each positive lands > 10 s after the previous, so the window only ever
    // holds one — three spread-out squawks are not a bout.
    #expect(tracker.observe(confidence: cry, at: t0) == nil)
    #expect(tracker.observe(confidence: cry, at: t0.addingTimeInterval(11)) == nil)
    #expect(tracker.observe(confidence: cry, at: t0.addingTimeInterval(22)) == nil)
    #expect(!tracker.inBout)
  }

  @Test func boutEndsAfterTwoMinutesQuiet() async throws {
    var tracker = confirmedTracker()
    let lastPositive = t0.addingTimeInterval(1.5)
    #expect(tracker.observe(confidence: quiet, at: lastPositive.addingTimeInterval(119)) == nil)
    #expect(tracker.inBout)
    #expect(tracker.observe(confidence: quiet, at: lastPositive.addingTimeInterval(120)) == .boutEnded)
    #expect(!tracker.inBout)
  }

  @Test func continuedCryingPostponesBoutEnd() async throws {
    var tracker = confirmedTracker()
    // A positive window mid-bout refreshes the silence clock, so the 2-minute
    // countdown to bout-end runs from the *last* cry, not the first.
    let refresh = t0.addingTimeInterval(60)
    #expect(tracker.observe(confidence: cry, at: refresh) == nil)   // already in bout, no event
    #expect(tracker.observe(confidence: quiet, at: refresh.addingTimeInterval(119)) == nil)
    #expect(tracker.observe(confidence: quiet, at: refresh.addingTimeInterval(120)) == .boutEnded)
  }

  @Test func subThresholdConfidenceIsNeverPositive() async throws {
    var tracker = CryBoutTracker()
    for i in 0...10 {
      #expect(tracker.observe(confidence: 0.59, at: t0.addingTimeInterval(Double(i))) == nil)
    }
    #expect(!tracker.inBout)
  }

  /// A tracker already in a confirmed bout, last positive at t0 + 1.5 s.
  private func confirmedTracker() -> CryBoutTracker {
    var tracker = CryBoutTracker()
    _ = tracker.observe(confidence: cry, at: t0)
    _ = tracker.observe(confidence: cry, at: t0.addingTimeInterval(0.75))
    _ = tracker.observe(confidence: cry, at: t0.addingTimeInterval(1.5))
    return tracker
  }
}
