//
//  BabyProfile.swift
//  Baby Night Light
//

import Foundation

/// Birth-month setting and age-based tip-window lookup for the deep-sleep tip.
///
/// The windows are the early edge of the researched deep-sleep ranges
/// (specs/2026-07-10-deep-sleep-tip); the repeat-glow rounds cover the tail.
/// All lookups are pure static functions so tests can hit them directly.
struct BabyProfile {

  /// Age buckets the sleep-science windows are keyed by.
  enum AgeBucket: CaseIterable {
    case months0to3
    case months3to6
    case months6to12
    case months12plus
  }

  /// What the tip countdown is anchored to. `cryCessation` arrives with the
  /// Phase-2 microphone work; the window table already covers it so the
  /// engine's timing math never changes shape. String-raw and Codable because
  /// it is persisted verbatim in session-log records.
  enum AnchorKind: String, Codable {
    case appOpen
    case cryCessation
  }

  static func bucket(forAgeMonths months: Int) -> AgeBucket {
    switch months {
    case ..<3: return .months0to3
    case 3..<6: return .months3to6
    case 6..<12: return .months6to12
    default: return .months12plus
    }
  }

  /// Minutes from the anchor to the first glow.
  static func windowMinutes(for bucket: AgeBucket, anchor: AnchorKind) -> Int {
    switch anchor {
    case .appOpen:
      switch bucket {
      case .months0to3: return 35
      case .months3to6: return 30
      case .months6to12: return 25
      case .months12plus: return 20
      }
    case .cryCessation:
      switch bucket {
      case .months0to3: return 20
      case .months3to6: return 15
      case .months6to12: return 10
      case .months12plus: return 10
      }
    }
  }

  /// Whole calendar months between the birth month and `now`, clamped to 0
  /// so a future-dated birth month behaves like a newborn.
  static func ageInMonths(birthMonth: Date, now: Date) -> Int {
    let months = Calendar.current.dateComponents([.month], from: birthMonth, to: now).month ?? 0
    return max(0, months)
  }

  // MARK: - Birth-month persistence

  static let birthMonthKey = "sleepTipBirthMonth"

  static func loadBirthMonth() -> Date? {
    UserDefaults.standard.object(forKey: birthMonthKey) as? Date
  }

  static func save(birthMonth: Date?) {
    if let birthMonth {
      UserDefaults.standard.set(birthMonth, forKey: birthMonthKey)
    } else {
      UserDefaults.standard.removeObject(forKey: birthMonthKey)
    }
  }
}
