//
//  SleepTipEngine.swift
//  Baby Night Light
//

import Foundation

/// Pure state machine for the deep-sleep tip: decides *when to glow*, *when to
/// re-arm*, and remembers what happened so the session record can be written.
///
/// No timers and no UI — the owner feeds it clock ticks and events, which is
/// what makes the timing rules unit-testable with simulated dates
/// (specs/2026-07-10-deep-sleep-tip). Tip time = anchor + window(ageBucket,
/// anchorKind) + learnedOffset + userFineTune; unacknowledged glows repeat
/// every `repeatInterval`, at most `maxRounds` times.
struct SleepTipEngine {

  struct Config {
    var repeatInterval: TimeInterval = 5 * 60
    var maxRounds = 4
    /// How long a glow "pulses" (3 pulses × ~1.5 s) — the window during which
    /// a single tap counts as an acknowledge.
    var pulseDuration: TimeInterval = 4.5
  }

  enum State: Equatable {
    case idle
    case settling
    /// A glow has fired and is awaiting acknowledgement; `round` is 1-based.
    case tipDue(round: Int)
    case acknowledged
  }

  let config: Config

  private(set) var state: State = .idle
  private(set) var anchorKind: BabyProfile.AnchorKind = .appOpen
  private(set) var anchorTime: Date?
  private(set) var glowTimes: [Date] = []
  private(set) var acknowledgeTime: Date?
  private(set) var roundsFired = 0

  /// Age bucket for the window lookup; nil (birth month unset) means the
  /// session runs and logs normally but no glow is ever scheduled.
  private(set) var bucket: BabyProfile.AgeBucket?
  private(set) var fineTuneMinutes = 0
  /// Per-baby calibration offset; stays 0 until Phase 3 wires Calibration.
  private(set) var learnedOffsetMinutes = 0

  /// True between a confirmed cry bout and its end — no glows while the baby
  /// is audibly awake.
  private var inCryBout = false

  init(config: Config = Config()) {
    self.config = config
  }

  /// When the next glow is due, or nil when no more glows can fire
  /// (no anchor, no bucket, all rounds spent).
  var nextGlowTime: Date? {
    guard let anchorTime, let bucket, roundsFired < config.maxRounds else { return nil }
    let window = TimeInterval(BabyProfile.windowMinutes(for: bucket, anchor: anchorKind) * 60)
    let offsets = TimeInterval((learnedOffsetMinutes + fineTuneMinutes) * 60)
    let firstTip = anchorTime.addingTimeInterval(window + offsets)
    return firstTip.addingTimeInterval(TimeInterval(roundsFired) * config.repeatInterval)
  }

  // MARK: - Events

  mutating func sessionStarted(at now: Date, bucket: BabyProfile.AgeBucket?,
                               fineTuneMinutes: Int = 0, learnedOffsetMinutes: Int = 0) {
    state = .settling
    anchorKind = .appOpen
    anchorTime = now
    glowTimes = []
    acknowledgeTime = nil
    roundsFired = 0
    inCryBout = false
    self.bucket = bucket
    self.fineTuneMinutes = fineTuneMinutes
    self.learnedOffsetMinutes = learnedOffsetMinutes
  }

  mutating func sessionEnded() {
    state = .idle
    anchorTime = nil
    inCryBout = false
  }

  /// Clock tick: fires the next glow round when it is due. Each tick advances
  /// at most one round, so a long gap (suspension) never bursts several glows.
  mutating func tick(now: Date) {
    switch state {
    case .settling, .tipDue:
      guard !inCryBout, let due = nextGlowTime, now >= due else { return }
      roundsFired += 1
      glowTimes.append(now)
      state = .tipDue(round: roundsFired)
    case .idle, .acknowledged:
      return
    }
  }

  /// Single tap on the light. Counts only while a glow is pulsing (AC2);
  /// returns whether it was accepted.
  @discardableResult
  mutating func acknowledge(at now: Date) -> Bool {
    guard case .tipDue = state, let lastGlow = glowTimes.last,
          now <= lastGlow.addingTimeInterval(config.pulseDuration) else { return false }
    state = .acknowledged
    acknowledgeTime = now
    return true
  }

  /// Leaving the foreground stops any pulsing (AC2); the session itself
  /// survives or ends per the view model's interruption rule.
  mutating func wentInactive(at now: Date) {
    if case .tipDue = state {
      state = .settling
    }
  }

  mutating func becameActive(at now: Date) {
    // Nothing to do — the next tick re-evaluates against nextGlowTime.
  }

  /// A confirmed cry bout: the baby is awake, so any pending or shown tip is
  /// cleared; the engine re-arms when the bout ends (AC7).
  mutating func cryBoutConfirmed(at now: Date) {
    guard state != .idle else { return }
    inCryBout = true
    state = .settling
  }

  /// End of a cry bout: re-anchor the countdown to the bout's end with the
  /// (shorter) cry-cessation window and a fresh set of rounds (AC6).
  mutating func cryBoutEnded(at now: Date) {
    guard state != .idle else { return }
    inCryBout = false
    anchorKind = .cryCessation
    anchorTime = now
    roundsFired = 0
    state = .settling
  }

  /// Long-press reset: a fresh session anchored at `now` — the backup when a
  /// put-down failed or a cry went undetected.
  mutating func manualReset(at now: Date) {
    sessionStarted(at: now, bucket: bucket,
                   fineTuneMinutes: fineTuneMinutes,
                   learnedOffsetMinutes: learnedOffsetMinutes)
  }

  /// The fine-tune stepper applies to the running session too — the next
  /// glow moves, already-fired rounds stay history.
  mutating func updateFineTune(minutes: Int) {
    fineTuneMinutes = minutes
  }

  /// Birth-month edits mid-session re-bucket the running session.
  mutating func updateBucket(_ newBucket: BabyProfile.AgeBucket?) {
    bucket = newBucket
  }
}
