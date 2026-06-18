//
//  ContentView.swift
//  Baby Night Light
//

import SwiftUI

struct ContentView: View {
  @State private var viewModel = LightViewModel()
  @State private var dragStartY: CGFloat = 0
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    Group {
      if viewModel.isScreenOff {
        // Sleep mode - black screen, tap to wake
        Color.black
          .ignoresSafeArea()
          .onTapGesture {
            viewModel.wakeUp()
          }
      } else {
        // Main light view
        ZStack {
          // Full-screen colored background
          viewModel.currentColor.color
            .accessibilityIdentifier("lightBackground")
            .accessibilityLabel("Light background color: \(viewModel.currentColor.name)")

          // Elapsed timer - same hue as the background, slightly lighter so
          // it stays visible without changing the overall lighting.
          Text(viewModel.formatTime(viewModel.elapsedSeconds))
            .font(.system(size: 64, weight: .light, design: .rounded))
            .monospacedDigit()
            .foregroundColor(viewModel.currentColor.color.lightened(by: 0.12))
            .accessibilityIdentifier("elapsedTimer")
            .accessibilityLabel("Elapsed time")

          // Controls overlay (when visible)
          if viewModel.controlsVisible {
            ControlsOverlay(viewModel: viewModel)
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
              .accessibilityIdentifier("controlsOverlay")
          }
        }
        .ignoresSafeArea()
        .accessibilityIdentifier("mainLightView")
        .animation(.easeInOut(duration: 0.2), value: viewModel.controlsVisible)
        .gesture(
          // Double-tap to toggle controls
          TapGesture(count: 2)
            .onEnded {
              viewModel.toggleControls()
            }
        )
        .gesture(
          // Drag up/down to adjust brightness
          DragGesture(minimumDistance: 20)
            .onChanged { value in
              // Only process when controls are hidden
              if !viewModel.controlsVisible {
                let deltaY = dragStartY - value.location.y
                let sensitivity: CGFloat = 0.002
                viewModel.adjustBrightness(delta: deltaY * sensitivity)
                dragStartY = value.location.y
              }
            }
            .onEnded { _ in
              dragStartY = 0
            }
        )
        .simultaneousGesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              if dragStartY == 0 {
                dragStartY = value.location.y
              }
            }
        )
      }
    }
    .ignoresSafeArea()
    .persistentSystemOverlays(.hidden)
    .onAppear {
      // Keep screen awake
      UIApplication.shared.isIdleTimerDisabled = true
    }
    .onDisappear {
      // Allow screen to sleep when app closes
      UIApplication.shared.isIdleTimerDisabled = false
    }
    .onChange(of: scenePhase) { _, newPhase in
      switch newPhase {
      case .active:
        // App opened: reset elapsed timer and brighten to max (if enabled)
        viewModel.handleAppDidBecomeActive()
      case .background:
        // App closed: dim to minimal (if enabled)
        viewModel.handleAppDidEnterBackground()
      default:
        break
      }
    }
  }
}

#Preview {
  ContentView()
}
