//
//  Tips.swift
//  Baby Night Light
//

import TipKit

/// A short, one-time tutorial tooltip teaching the app's core gesture.
///
/// The main screen is just a full-bleed colored light with no visible chrome,
/// so the double-tap gesture that reveals the controls isn't discoverable on
/// its own. This tip (a native TipKit popover) points it out the first time
/// the controls are hidden, and also mentions the swipe-to-dim gesture.
struct ControlsTip: Tip {
  /// Tracks whether the controls overlay is currently hidden. The tip is only
  /// eligible to appear once the controls have been hidden, so it never
  /// competes with the controls panel that's shown on first launch.
  @Parameter static var controlsHidden: Bool = false

  var title: Text {
    Text("Tap to show controls")
  }

  var message: Text? {
    Text("Double-tap anywhere to show or hide the controls. Swipe up or down to adjust the brightness.")
  }

  var image: Image? {
    Image(systemName: "hand.tap")
  }

  var rules: [Rule] {
    // Only show once the controls are hidden — i.e. when the user is looking
    // at the bare light and would otherwise have no hint about the gesture.
    #Rule(Self.$controlsHidden) { $0 == true }
  }

  var options: [Option] {
    // A gentle, one-time nudge: never show it more than once.
    MaxDisplayCount(1)
  }
}
