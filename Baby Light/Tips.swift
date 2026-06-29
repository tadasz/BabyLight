//
//  Tips.swift
//  Baby Night Light
//

import TipKit

/// First-run tutorial, step 1 — shown while the controls panel is visible
/// (i.e. on first launch). Teaches how to get the controls out of the way so
/// the screen becomes a clean night light.
///
/// Anchored to the controls overlay itself, so it only appears while the
/// overlay is on screen; no display rule is needed for that.
struct HideControlsTip: Tip {
  var title: Text {
    Text("Hide the controls")
  }

  var message: Text? {
    Text("Double-tap anywhere to hide these controls and dim the screen to a calm night light.")
  }

  var image: Image? {
    Image(systemName: "hand.tap")
  }

  var options: [Option] {
    MaxDisplayCount(1)
  }
}

/// First-run tutorial, step 2 — shown once the controls are hidden and the
/// user is looking at the bare light. Teaches how to bring the controls back
/// and how to adjust brightness, both of which are gesture-only and otherwise
/// undiscoverable. The swipe gesture is mentioned here (and not in step 1)
/// because it only takes effect while the controls are hidden.
struct ShowControlsTip: Tip {
  /// Mirrors the controls overlay's visibility. The tip is only eligible once
  /// the controls have been hidden, so it follows naturally after step 1.
  @Parameter static var controlsVisible: Bool = true

  var title: Text {
    Text("Tap to show controls")
  }

  var message: Text? {
    Text("Double-tap anywhere to show the controls again. Swipe up or down to adjust the brightness.")
  }

  var image: Image? {
    Image(systemName: "hand.tap")
  }

  var rules: [Rule] {
    #Rule(Self.$controlsVisible) { $0 == false }
  }

  var options: [Option] {
    MaxDisplayCount(1)
  }
}
