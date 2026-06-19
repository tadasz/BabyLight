//
//  WatchLight.swift
//  Baby Light Watch App
//
//  Color presets, shared with the iPhone app's palette (LightColor.swift).
//  Kept as a small self-contained copy so the watch target has no dependency
//  on the iOS sources.
//

import SwiftUI

struct WatchLightColor: Identifiable, Equatable {
  let id: String
  let color: Color
  let name: String
  let blurb: String
}

enum WatchPalette {
  /// Same four sleep-friendly colors as the phone, in the same order.
  static let presets: [WatchLightColor] = [
    WatchLightColor(id: "deep-red", color: Color(red: 1.0, green: 0.0, blue: 0.0),
                    name: "Deep Red", blurb: "Best for sleep"),
    WatchLightColor(id: "amber", color: Color(red: 1.0, green: 69.0/255.0, blue: 0.0),
                    name: "Amber", blurb: "Warm & soothing"),
    WatchLightColor(id: "candle", color: Color(red: 1.0, green: 140.0/255.0, blue: 0.0),
                    name: "Candle", blurb: "Soft orange"),
    WatchLightColor(id: "warm", color: Color(red: 245.0/255.0, green: 222.0/255.0, blue: 179.0/255.0),
                    name: "Warm White", blurb: "If you need more light"),
  ]
}

extension Color {
  /// Nudge each channel toward white so on-screen text stays visible against
  /// the light without changing the overall hue (matches the iPhone app).
  func watchLightened(by amount: CGFloat) -> Color {
    let ui = UIColor(self)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    ui.getRed(&r, green: &g, blue: &b, alpha: &a)
    return Color(red: Double(min(1, r + amount)),
                 green: Double(min(1, g + amount)),
                 blue: Double(min(1, b + amount)),
                 opacity: Double(a))
  }
}
