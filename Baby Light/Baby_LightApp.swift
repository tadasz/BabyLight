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
<<<<<<< /Users/tadasziemys/Projects/AI/BabyLight/Baby Light/Baby Light/Baby_LightApp.swift
<<<<<<< /Users/tadasziemys/Projects/AI/BabyLight/Baby Light/Baby Light/Baby_LightApp.swift
<<<<<<< /Users/tadasziemys/Projects/AI/BabyLight/Baby Light/Baby Light/Baby_LightApp.swift
    view.backgroundColor = .black
=======
=======
>>>>>>> /Users/tadasziemys/.windsurf/worktrees/Baby Light/Baby Light-4e28c210/Baby Light/Baby_LightApp.swift
=======
>>>>>>> /Users/tadasziemys/.windsurf/worktrees/Baby Light/Baby Light-f8848958/Baby Light/Baby_LightApp.swift
    // Use iOS 16.4+ API to disable safe area regions
    safeAreaRegions = []
    view.backgroundColor = .clear
>>>>>>> /Users/tadasziemys/.windsurf/worktrees/Baby Light/Baby Light-4e28c210/Baby Light/Baby_LightApp.swift
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Ensure window background is black to prevent white showing through
    view.window?.backgroundColor = .black
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Ensure window background is black to prevent white showing through
    view.window?.backgroundColor = .black
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Ensure window background is black to prevent white showing through
    view.window?.backgroundColor = .black
  }
}
