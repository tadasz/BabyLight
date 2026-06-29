//
//  Tips.swift
//  Baby Night Light
//

import TipKit

/// A short, one-time tutorial tooltip teaching the app's core gestures.
///
/// The main screen is just a full-bleed colored light with no visible chrome,
/// so the double-tap (show/hide controls) and swipe (adjust brightness)
/// gestures aren't discoverable on their own. This tip (a native TipKit
/// popover) points them out the first time the app launches — including while
/// the controls panel is on screen — and is shown only once.
struct ControlsTip: Tip {
  var title: Text {
    Text("Tap to show controls")
  }

  var message: Text? {
    Text("Double-tap anywhere to show or hide the controls. Swipe up or down to adjust the brightness.")
  }

  var image: Image? {
    Image(systemName: "hand.tap")
  }

  var options: [Option] {
    // A gentle, one-time nudge: never show it more than once. With no display
    // rules it becomes eligible as soon as the app first appears, so it shows
    // on the very first launch regardless of whether the controls are visible.
    MaxDisplayCount(1)
  }
}
