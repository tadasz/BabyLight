//
//  BabyLightWatchApp.swift
//  Baby Light Watch App
//
//  Standalone watchOS night light — a wrist-sized red/amber glow for night
//  feeds and check-ins. Mirrors the iPhone app: tap to cycle colors, turn the
//  Digital Crown to dim, glance at the count-up feed timer.
//

import SwiftUI

@main
struct BabyLightWatchApp: App {
  var body: some Scene {
    WindowGroup {
      WatchContentView()
    }
  }
}
