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
          // Full-screen colored background. `ignoresSafeArea` here guarantees the
          // color bleeds to every edge (notch, Dynamic Island, home indicator)
          // independently of how the content stack above sizes itself.
          viewModel.currentColor.color
            .ignoresSafeArea()
            .accessibilityIdentifier("lightBackground")
            .accessibilityLabel("Light background color: \(viewModel.currentColor.name)")

          // Elapsed timer - same hue as the background, slightly lighter so
          // it stays visible without changing the overall lighting.
          Text(viewModel.formatTime(viewModel.elapsedSeconds))
            .font(.system(size: 64, weight: .light, design: .rounded))
            .monospacedDigit()
            .foregroundColor(viewModel.currentColor.color.lightened(by: viewModel.timerLightness))
            .accessibilityIdentifier("elapsedTimer")
            .accessibilityLabel("Elapsed time")

          // Controls overlay (when visible)
          if viewModel.controlsVisible {
            ControlsOverlay(viewModel: viewModel)
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
              // Expose the overlay as a single accessibility container so
              // otherElements["controlsOverlay"] resolves to it (otherwise the
              // identifier only lands on the inner controls, not a container).
              .accessibilityElement(children: .contain)
              .accessibilityIdentifier("controlsOverlay")
          }
        }
        .ignoresSafeArea()
        // Mark the ZStack as an accessibility container so the identifier
        // below applies only to it; without this, .accessibilityIdentifier on
        // the container propagates to every child and clobbers their own
        // identifiers (lightBackground, elapsedTimer, controlsOverlay).
        .accessibilityElement(children: .contain)
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
    .onChange(of: scenePhase) { oldPhase, newPhase in
      switch newPhase {
      case .active:
        // App opened/returned: reset elapsed timer and brighten to max (if enabled)
        viewModel.handleAppDidBecomeActive()
      case .inactive where oldPhase == .active:
        // Leaving the foreground (home, app switcher, lock, interruption). Dim
        // now, while we're still frontmost — brightness writes are ignored once
        // we reach .background. Guarding on `oldPhase == .active` avoids dimming
        // on the .background → .inactive → .active path when returning.
        viewModel.handleAppWillResignActive()
      case .background:
        // Fallback dim in case the resign-active write didn't take effect.
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
