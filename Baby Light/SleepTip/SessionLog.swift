//
//  SessionLog.swift
//  Baby Night Light
//

import Foundation

/// One settling session, as recorded at session end. The field table is
/// pinned by specs/2026-07-10-deep-sleep-tip → Data model; records feed the
/// Phase-3 calibration and the success-outcome measurement, and never leave
/// the device.
struct SessionRecord: Codable, Equatable {

  enum NapOrNight: String, Codable {
    case nap
    case night
  }

  struct CryBout: Codable, Equatable {
    let start: Date
    let end: Date
  }

  enum Outcome: String, Codable {
    case success
    case tooEarly
    case unknown
  }

  enum EndReason: String, Codable {
    case background
    case autoOff
    case manualReset
  }

  let date: Date
  let ageMonths: Int?
  let napOrNight: NapOrNight
  let anchorKind: BabyProfile.AnchorKind
  let anchorTime: Date
  let glowTimes: [Date]
  let cryBouts: [CryBout]
  let acknowledgeTime: Date?
  let outcome: Outcome
  let endReason: EndReason

  /// Night runs 19:00–06:59 by clock hour (requirements → Data model:
  /// "napOrNight … by clock hour").
  static func napOrNight(for date: Date) -> NapOrNight {
    let hour = Calendar.current.component(.hour, from: date)
    return (hour < 7 || hour >= 19) ? .night : .nap
  }
}

/// Ring-buffer persistence for session records: a single JSON file in
/// Application Support, capped at `capacity` records (oldest dropped).
///
/// A deliberate, owner-approved deviation from the "no files on disk" house
/// rule (specs/2026-07-10-deep-sleep-tip → Decisions) — UserDefaults is
/// unsuited to a ~100-record ring buffer.
struct SessionLog {

  static let capacity = 100

  let fileURL: URL

  /// Production location: Application Support/DeepSleepTip/sessions.json.
  /// Tests inject a temporary URL instead.
  init(fileURL: URL? = nil) {
    if let fileURL {
      self.fileURL = fileURL
    } else {
      let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                             in: .userDomainMask).first!
      self.fileURL = support.appendingPathComponent("DeepSleepTip/sessions.json")
    }
  }

  func load() -> [SessionRecord] {
    guard let data = try? Data(contentsOf: fileURL) else { return [] }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return (try? decoder.decode([SessionRecord].self, from: data)) ?? []
  }

  /// Appends one record, trimming to the newest `capacity`. Failures are
  /// swallowed deliberately: the log is best-effort evidence, and a full disk
  /// must never take the night light down with it.
  func append(_ record: SessionRecord) {
    var records = load()
    records.append(record)
    if records.count > Self.capacity {
      records.removeFirst(records.count - Self.capacity)
    }
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(records) else { return }
    try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                             withIntermediateDirectories: true)
    try? data.write(to: fileURL, options: .atomic)
  }
}
