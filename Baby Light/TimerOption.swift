//
//  TimerOption.swift
//  Baby Light
//

import Foundation

/// Represents an auto-off timer option
struct TimerOption: Identifiable, Equatable {
  let id: String
  let label: String
  let minutes: Int?

  var isInfinite: Bool { minutes == nil }

  /// Timer presets matching the web app
  static let options: [TimerOption] = [
    TimerOption(id: "infinite", label: "∞", minutes: nil),
    TimerOption(id: "15m", label: "15m", minutes: 15),
    TimerOption(id: "30m", label: "30m", minutes: 30),
    TimerOption(id: "1h", label: "1h", minutes: 60),
    TimerOption(id: "2h", label: "2h", minutes: 120),
  ]
}
