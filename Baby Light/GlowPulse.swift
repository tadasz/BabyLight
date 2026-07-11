//
//  GlowPulse.swift
//  Baby Night Light
//

import SwiftUI

/// The deep-sleep tip's cue: the light itself briefly breathes brighter.
/// Three ease-in-out pulses of the current color lightened toward white —
/// same hue, no sound, no haptics — then back to the exact previous darkness.
///
/// Rendering-only brightening via `lightened(by:)`, never `UIScreen.brightness`
/// — it must be visible with hardware brightness near zero and stay out of the
/// lifecycle brightness handling (specs/2026-07-10-deep-sleep-tip → Decisions).
struct GlowPulse: ViewModifier {
  /// The light color being pulsed; the overlay is this color lightened.
  let color: Color
  /// Monotonic glow counter — every increment plays one 3-pulse cycle.
  let trigger: Int

  /// ~+12 % lightness at the top of each pulse.
  private static let lightness: CGFloat = 0.12
  /// 0 → 1 → 0 three times: one pulse ≈ 1.5 s, full cue ≈ 4.5 s, ends dark.
  private static let phases: [Double] = [0, 1, 0, 1, 0, 1, 0]

  func body(content: Content) -> some View {
    content
      .overlay(
        color.lightened(by: Self.lightness)
          .ignoresSafeArea()
          .allowsHitTesting(false)
          .phaseAnimator(Self.phases, trigger: trigger) { overlay, phase in
            overlay.opacity(phase)
          } animation: { _ in
            .easeInOut(duration: 0.75)
          }
      )
  }
}
