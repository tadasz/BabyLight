//
//  WatchContentView.swift
//  Baby Light Watch App
//

import AVKit
import Combine
import SwiftUI

/// watchOS has no public API to hide the time-of-day in the top corner — but the
/// system hides it whenever a `VideoPlayer` is on screen. We mount an invisible,
/// inert player so the night light stays a pure, dark glow with no bright white
/// clock burning in the corner at 3 AM.
private struct TimeHidingOverlay: View {
  var body: some View {
    VideoPlayer(player: nil, videoOverlay: { EmptyView() })
      .focusable(false)
      .disabled(true)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
      .opacity(0)
  }
}

struct WatchContentView: View {
  /// Index into `WatchPalette.presets`.
  @State private var colorIndex = 0
  /// 0.15…1.0 — driven by the Digital Crown; dims the glow toward black.
  @State private var brightness: Double = 1.0
  /// Seconds since the view appeared / was reset. A glanceable feed timer.
  @State private var elapsed = 0
  /// Briefly show the color name after a tap.
  @State private var showName = false

  @FocusState private var crownFocused: Bool

  private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  private var preset: WatchLightColor { WatchPalette.presets[colorIndex] }

  var body: some View {
    ZStack {
      // Full-screen glow. `.brightness` (negative) dims it toward black so the
      // Digital Crown acts like a dimmer without touching system brightness.
      preset.color
        .brightness(brightness - 1.0)
        .ignoresSafeArea()
        .background(TimeHidingOverlay())

      VStack(spacing: 6) {
        // Count-up feed timer, in the same hue as the light but lighter.
        Text(timeString)
          .font(.system(size: 44, weight: .light, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(preset.color.watchLightened(by: 0.22).opacity(brightness))

        if showName {
          Text(preset.name.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .tracking(1)
            .foregroundStyle(.white.opacity(0.55))
            .transition(.opacity)
        }
      }
    }
    // Tap anywhere to cycle to the next color.
    .contentShape(Rectangle())
    .onTapGesture { cycleColor() }
    // Digital Crown = brightness/dimmer.
    .focusable(true)
    .focused($crownFocused)
    .digitalCrownRotation($brightness, from: 0.15, through: 1.0, by: 0.02,
                          sensitivity: .medium, isContinuous: false)
    .onAppear { crownFocused = true }
    .onReceive(tick) { _ in elapsed += 1 }
    .animation(.easeInOut(duration: 0.2), value: colorIndex)
    .animation(.easeInOut(duration: 0.25), value: showName)
  }

  private func cycleColor() {
    colorIndex = (colorIndex + 1) % WatchPalette.presets.count
    showName = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { showName = false }
  }

  private var timeString: String {
    let h = elapsed / 3600, m = (elapsed % 3600) / 60, s = elapsed % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                 : String(format: "%d:%02d", m, s)
  }
}

#Preview {
  WatchContentView()
}
