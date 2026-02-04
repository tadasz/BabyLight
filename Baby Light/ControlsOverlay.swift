//
//  ControlsOverlay.swift
//  Baby Light
//

import SwiftUI

/// Semi-transparent overlay with color and timer controls
struct ControlsOverlay: View {
  @Bindable var viewModel: LightViewModel

  var body: some View {
    VStack(spacing: 24) {
      // Title
      Text("Baby Safe Light")
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

        Text(viewModel.currentColor.description)
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
