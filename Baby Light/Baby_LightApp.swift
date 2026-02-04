//
//  Baby_LightApp.swift
//  Baby Night Light
//
//  Created by Tadas Ziemys on 1/25/26.
//

import SwiftUI
import UIKit  // Added for UIViewControllerRepresentable and UIHostingController

@main
struct Baby_LightApp: App {
  var body: some Scene {
    WindowGroup {
      StatusBarHiddenView {
        ContentView()
      }
    }
  }
}

/// Wrapper view that forces status bar to be hidden
struct StatusBarHiddenView<Content: View>: UIViewControllerRepresentable {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  func makeUIViewController(context: Context) -> StatusBarHiddenHostingController<Content> {
    StatusBarHiddenHostingController(rootView: content)
  }

  func updateUIViewController(
    _ uiViewController: StatusBarHiddenHostingController<Content>, context: Context
  ) {
    uiViewController.rootView = content
  }
}

/// Custom hosting controller that hides the status bar and fills entire screen
class StatusBarHiddenHostingController<Content: View>: UIHostingController<Content> {
  override var prefersStatusBarHidden: Bool { true }
  override var prefersHomeIndicatorAutoHidden: Bool { true }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }
}
