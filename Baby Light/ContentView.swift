//
//  ContentView.swift
//  Baby Light
//

import SwiftUI

struct ContentView: View {
  @State private var viewModel = LightViewModel()
  @State private var dragStartY: CGFloat = 0

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
            .ignoresSafeArea()
            .accessibilityIdentifier("lightBackground")
            .accessibilityLabel("Light background color: \(viewModel.currentColor.name)")

          // Controls overlay (when visible)
          if viewModel.controlsVisible {
            ControlsOverlay(viewModel: viewModel)
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
              .accessibilityIdentifier("controlsOverlay")
          }
        }
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
    .persistentSystemOverlays(.hidden)
    .onAppear {
      // Keep screen awake
      UIApplication.shared.isIdleTimerDisabled = true
    }
    .onDisappear {
      // Allow screen to sleep when app closes
      UIApplication.shared.isIdleTimerDisabled = false
    }
  }
}

#Preview {
  ContentView()
}
