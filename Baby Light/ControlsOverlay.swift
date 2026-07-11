//
//  ControlsOverlay.swift
//  Baby Night Light
//

import SwiftUI

/// Semi-transparent overlay with color and timer controls
struct ControlsOverlay: View {
  @Bindable var viewModel: LightViewModel

  var body: some View {
    VStack(spacing: 24) {
      // Title
      Text("Baby Light")
        .font(.system(size: 28, weight: .bold))
        .foregroundColor(.white)
        .padding(.top, 10)

      // Color Selection
      VStack(spacing: 12) {
        Text("LIGHT COLOR")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color(white: 0.85))
          .tracking(1)

        HStack(spacing: 12) {
          ForEach(LightColor.presets) { color in
            ColorButton(
              color: color,
              isSelected: viewModel.currentColor.id == color.id
            ) {
              viewModel.currentColor = color
            }
          }
        }

        Text(LocalizedStringKey(viewModel.currentColor.description))
          .font(.system(size: 14))
          .foregroundColor(Color(white: 0.65))
          .italic()
      }

      // Timer Selection
      VStack(spacing: 12) {
        HStack(spacing: 4) {
          Text("AUTO-OFF TIMER")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(white: 0.85))
            .tracking(1)

          if let time = viewModel.timeRemaining, time > 0 {
            Text("(\(viewModel.formatTime(time)))")
              .font(.system(size: 14, weight: .semibold))
              .foregroundColor(Color(white: 0.85))
          }
        }

        HStack(spacing: 12) {
          ForEach(TimerOption.options) { option in
            TimerButton(
              option: option,
              isSelected: viewModel.selectedTimer.id == option.id
            ) {
              viewModel.setTimer(option)
            }
          }
        }
      }

      // Auto Brightness Settings
      VStack(spacing: 12) {
        Text("AUTO BRIGHTNESS")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color(white: 0.85))
          .tracking(1)
          .frame(maxWidth: .infinity, alignment: .leading)

        Toggle(isOn: $viewModel.brightenOnOpen) {
          Text("Max brightness when opened")
            .font(.system(size: 15))
            .foregroundColor(.white)
        }
        .tint(.white)

        Toggle(isOn: $viewModel.dimOnClose) {
          Text("Dim to minimum when closed")
            .font(.system(size: 15))
            .foregroundColor(.white)
        }
        .tint(.white)
      }

      // Elapsed Timer Settings
      VStack(spacing: 12) {
        Text("ELAPSED TIMER")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color(white: 0.85))
          .tracking(1)
          .frame(maxWidth: .infinity, alignment: .leading)

        HStack(spacing: 12) {
          Text("Brightness")
            .font(.system(size: 15))
            .foregroundColor(.white)

          Slider(value: $viewModel.timerLightness, in: 0.05...0.45)
            .tint(.white)
            .accessibilityIdentifier("timerBrightnessSlider")
            .accessibilityLabel("Elapsed timer brightness")

          // Live preview of how the timer text will look against the light.
          Text("0:00")
            .font(.system(size: 17, weight: .light, design: .rounded))
            .monospacedDigit()
            .foregroundColor(viewModel.currentColor.color.lightened(by: viewModel.timerLightness))
        }
      }

      // Deep Sleep Tip Settings
      VStack(spacing: 12) {
        Text("DEEP SLEEP TIP")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color(white: 0.85))
          .tracking(1)
          .frame(maxWidth: .infinity, alignment: .leading)

        Toggle(isOn: $viewModel.sleepTipEnabled) {
          Text("Glow when baby may be deeply asleep")
            .font(.system(size: 15))
            .foregroundColor(.white)
            // Wraps instead of truncating — several locales run long here.
            .fixedSize(horizontal: false, vertical: true)
        }
        .tint(.white)
        .accessibilityIdentifier("sleepTipToggle")

        Text("A gentle glow suggests a good moment to try the put-down.")
          .font(.system(size: 13))
          .foregroundColor(Color(white: 0.5))
          // Wrap instead of truncating when the panel is vertically tight.
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)

        if viewModel.sleepTipEnabled {
          DatePicker(
            selection: Binding(
              get: { viewModel.sleepTipBirthMonth ?? Date() },
              set: { viewModel.sleepTipBirthMonth = $0 }
            ),
            in: ...Date(),
            displayedComponents: .date
          ) {
            Text("Baby's birthday")
              .font(.system(size: 15))
              .foregroundColor(.white)
          }
          .environment(\.colorScheme, .dark)
          .accessibilityIdentifier("sleepTipBirthMonthPicker")

          HStack(spacing: 12) {
            Text("Glow earlier or later")
              .font(.system(size: 15))
              .foregroundColor(.white)

            Spacer()

            // Numeric abbreviation like the timer capsules ("15m") — not a
            // catalog entry.
            Text(viewModel.sleepTipFineTuneMinutes > 0
                 ? "+\(viewModel.sleepTipFineTuneMinutes)m"
                 : "\(viewModel.sleepTipFineTuneMinutes)m")
              .font(.system(size: 15, weight: .semibold))
              .monospacedDigit()
              .foregroundColor(.white)

            // A SwiftUI −/+ pair, not a UIKit `Stepper`, matching the app's
            // button chrome. Adjustments route through `adjustFineTune(by:)`,
            // which also records the tap so a following double-tap doesn't
            // dismiss the controls (rapid taps were mis-read as double-taps).
            FineTuneStepper(
              minutes: viewModel.sleepTipFineTuneMinutes,
              onAdjust: { viewModel.adjustFineTune(by: $0) }
            )
          }

          // Live answer to "how long will this take": the age-window logic,
          // updated as the birthday or the offset stepper changes.
          if let minutes = viewModel.sleepTipGlowMinutes {
            Text("Glows about \(minutes) min after you open the app — the typical time to reach deep sleep at this age.")
              .font(.system(size: 13))
              .foregroundColor(Color(white: 0.5))
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          Text("Tap the glow to dismiss • Hold the light to restart timing")
            .font(.system(size: 13))
            .foregroundColor(Color(white: 0.5))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      // Container so otherElements["deepSleepTipSection"] resolves in UI
      // tests (same wiring as the controlsOverlay identifier).
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("deepSleepTipSection")

      // Hint
      Text("Double-tap to hide • Swipe to adjust brightness")
        .font(.system(size: 13))
        .foregroundColor(Color(white: 0.5))
        .padding(.top, 10)
    }
    .padding(24)
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(Color.black.opacity(0.6))
        .shadow(color: .black.opacity(0.3), radius: 4.65, y: 4)
    )
    .frame(maxWidth: 380)
  }
}

// MARK: - Fine-Tune Stepper
/// A −/+ pair for the deep-sleep-tip offset (−10…+10 min), built from SwiftUI
/// `Button`s matching the app's button chrome. Taps route through
/// `LightViewModel.adjustFineTune(by:)`, which records the tap so a following
/// double-tap-to-hide is suppressed — otherwise rapid −/+ taps were counted as
/// a double-tap and dismissed the controls (dogfood round 3).
struct FineTuneStepper: View {
  let minutes: Int
  let onAdjust: (Int) -> Void

  private static let range = -10...10

  var body: some View {
    HStack(spacing: 0) {
      button(systemName: "minus", identifier: "sleepTipFineTuneMinus") {
        onAdjust(-1)
      }
      .disabled(minutes <= Self.range.lowerBound)

      Rectangle()
        .fill(Color.white.opacity(0.3))
        .frame(width: 1, height: 20)

      button(systemName: "plus", identifier: "sleepTipFineTunePlus") {
        onAdjust(1)
      }
      .disabled(minutes >= Self.range.upperBound)
    }
    .background(
      Capsule()
        .fill(Color.white.opacity(0.1))
        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
    )
  }

  private func button(systemName: String, identifier: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(.white)
        .frame(width: 44, height: 32)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(identifier)
  }
}

// MARK: - Color Button
struct ColorButton: View {
  let color: LightColor
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .fill(color.color)
          .frame(width: 48, height: 48)
          .overlay(
            Circle()
              .stroke(Color.white, lineWidth: 2)
          )
          .scaleEffect(isSelected ? 1.1 : 1.0)

        if isSelected {
          Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
        }
      }
    }
    .buttonStyle(.plain)
    .animation(.easeInOut(duration: 0.15), value: isSelected)
  }
}

// MARK: - Timer Button
struct TimerButton: View {
  let option: TimerOption
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(option.label)
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(isSelected ? .black : .white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          Capsule()
            .fill(isSelected ? Color.white : Color.white.opacity(0.1))
            .overlay(
              Capsule()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        )
    }
    .buttonStyle(.plain)
    .animation(.easeInOut(duration: 0.15), value: isSelected)
  }
}
