//
//  Calibration.swift
//  Baby Night Light
//

import Foundation

/// Per-baby calibration (Phase 3): reads the on-device session log and nudges
/// the glow offset toward the times that actually worked for this baby, with no
/// new interaction (US-3). Pure and static — fed a record array, so the math is
/// unit-testable with synthetic logs (specs/2026-07-10-deep-sleep-tip).
///
/// The offset is stored *relative to the age-default window*, so it stays valid
/// as the baby ages (Decisions). It is bucketed by (nap/night × anchorKind),
/// clamped to ±`clampMinutes`, and applied only once a bucket has at least
/// `minOutcomes` labelled sessions; a rolling `window` ages regressions out.
enum Calibration {

  struct Config {
    /// EMA weight on the newest outcome.
    var alpha = 0.2
    /// Gate: no learned offset until a bucket has this many labelled sessions.
    var minOutcomes = 5
    /// Rolling window of most-recent outcomes the EMA runs over.
    var window = 20
    /// ± clamp on the learned offset, relative to the age default.
    var clampMinutes = 10
    /// How much later to aim after a too-early rousing.
    var tooEarlyNudgeMinutes = 5
    /// A cry starting within this long after the glow reads as a failed
    /// put-down (the baby roused → the glow was too early).
    var rouseWithin: TimeInterval = 5 * 60
  }

  static let config = Config()

  struct BucketKey: Hashable {
    let napOrNight: SessionRecord.NapOrNight
    let anchorKind: BabyProfile.AnchorKind
  }

  /// Calibration label for one record, refined with cry timing (plan 5.1): a
  /// cry starting within `rouseWithin` after the first glow means the put-down
  /// failed (too early); an otherwise calm background end after a glow is a
  /// success. Everything else stays `unknown` and does not feed the EMA.
  static func outcome(for record: SessionRecord, config: Config = config) -> SessionRecord.Outcome {
    guard let firstGlow = record.glowTimes.first else { return .unknown }
    let rouseWindowEnd = firstGlow.addingTimeInterval(config.rouseWithin)
    if record.cryBouts.contains(where: { $0.start >= firstGlow && $0.start <= rouseWindowEnd }) {
      return .tooEarly
    }
    return record.endReason == .background ? .success : .unknown
  }

  /// Records that feed a bucket's EMA: this bucket, a definite success/tooEarly
  /// label, and a known age (needed to express the offset relative to the age
  /// default).
  private static func qualifying(for key: BucketKey, in records: [SessionRecord],
                                 config: Config) -> [SessionRecord] {
    records.filter { record in
      BucketKey(napOrNight: record.napOrNight, anchorKind: record.anchorKind) == key
        && record.ageMonths != nil
        && outcome(for: record, config: config) != .unknown
    }
  }

  /// How many labelled sessions currently back a bucket's learning — drives the
  /// "learned from N nights" caption.
  static func qualifyingCount(for key: BucketKey, in records: [SessionRecord],
                              config: Config = config) -> Int {
    qualifying(for: key, in: records, config: config).count
  }

  /// The learned offset (whole minutes, relative to the age default) for one
  /// bucket, or nil until the bucket has `minOutcomes` labelled sessions.
  static func learnedOffsetMinutes(for key: BucketKey, in records: [SessionRecord],
                                   config: Config = config) -> Int? {
    let qualifying = qualifying(for: key, in: records, config: config)
    guard qualifying.count >= config.minOutcomes else { return nil }

    // Rolling window, oldest → newest. Seed the EMA with the first target so a
    // run of consistent outcomes converges to that offset instead of lagging
    // up from zero.
    let recent = Array(qualifying.suffix(config.window))
    var ema = target(for: recent[0], config: config)
    for record in recent.dropFirst() {
      ema = config.alpha * target(for: record, config: config) + (1 - config.alpha) * ema
    }
    let limit = Double(config.clampMinutes)
    return Int(max(-limit, min(limit, ema)).rounded())
  }

  /// The offset (relative to the age default) this record argues for: a success
  /// reinforces the offset that produced it; a too-early rousing argues for
  /// firing `tooEarlyNudgeMinutes` later next time. Expressed relative to the
  /// age default so it stays valid as the baby moves between age buckets.
  private static func target(for record: SessionRecord, config: Config) -> Double {
    let bucket = BabyProfile.bucket(forAgeMonths: record.ageMonths ?? 0)
    let defaultWindow = Double(BabyProfile.windowMinutes(for: bucket, anchor: record.anchorKind))
    let glow = record.glowTimes.first ?? record.anchorTime
    let usedOffset = glow.timeIntervalSince(record.anchorTime) / 60 - defaultWindow
    switch outcome(for: record, config: config) {
    case .tooEarly: return usedOffset + Double(config.tooEarlyNudgeMinutes)
    case .success, .unknown: return usedOffset
    }
  }
}
