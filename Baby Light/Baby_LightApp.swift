//
//  Baby_LightApp.swift
//  Baby Night Light
//
//  Created by Tadas Ziemys on 1/25/26.
//

import SwiftUI
import TipKit
import UIKit  // Added for UIViewControllerRepresentable and UIHostingController

@main
struct Baby_LightApp: App {
  init() {
    // Initialize TipKit so the tutorial tooltip can track its display state.
    try? Tips.configure([
      .displayFrequency(.immediate),
      .datastoreLocation(.applicationDefault),
    ])
  }

  var body: some Scene {
    WindowGroup {
      StatusBarHiddenView {
        ContentView()
      }
      .ignoresSafeArea()
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
  
  override init(rootView: Content) {
    super.init(rootView: rootView)
  }
  
  @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Use iOS 16.4+ API to disable safe area regions
    safeAreaRegions = []
    view.backgroundColor = .black
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Ensure window background is black to prevent white showing through
    view.window?.backgroundColor = .black
  }
}
