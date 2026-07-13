//
//  CryDetector.swift
//  Baby Night Light
//

import Foundation
import AVFoundation
import SoundAnalysis

/// Pure debounce core for cry detection: turns a stream of per-window
/// classifier confidences into confirmed-bout / bout-ended events. It owns no
/// audio and no clock — the caller feeds it window results with an injected
/// `now`, which is what makes the AC6/AC7 rules unit-testable without a
/// microphone (same shape as `SleepTipEngine`). Constants come from
/// specs/2026-07-10-deep-sleep-tip → plan 4.3.
struct CryBoutTracker {

  struct Config {
    /// A window counts as "crying" at or above this classifier confidence.
    var confidence: Double = 0.6
    /// Positive windows required within `confirmWithin` to confirm a bout —
    /// isolated grunts/squawks (fewer) never move the anchor (AC6).
    var confirmCount = 3
    var confirmWithin: TimeInterval = 10
    /// Continuous quiet after the last positive window that ends a bout (AC6:
    /// "≥ 2 min quiet"). Kept as one tunable so real-nursery feedback can move
    /// it in one place.
    var endSilence: TimeInterval = 120
  }

  enum Event: Equatable {
    case boutConfirmed
    case boutEnded
  }

  let config: Config

  private(set) var inBout = false
  /// Positive-window timestamps still inside the confirmation window.
  private var recentPositives: [Date] = []
  private var lastPositive: Date?

  init(config: Config = Config()) {
    self.config = config
  }

  /// One classification window; `confidence` is the max over the cry labels.
  /// Returns an event only when this window flips the bout state.
  mutating func observe(confidence: Double, at now: Date) -> Event? {
    guard confidence >= config.confidence else {
      // A quiet window can only end an already-confirmed bout.
      return endIfSilent(now: now)
    }
    lastPositive = now
    guard !inBout else { return nil }
    // Copy to a local: reading `self.config` inside the closure while
    // `self.recentPositives` is being mutated is an exclusivity violation.
    let within = config.confirmWithin
    recentPositives.append(now)
    recentPositives.removeAll { now.timeIntervalSince($0) > within }
    guard recentPositives.count >= config.confirmCount else { return nil }
    inBout = true
    recentPositives.removeAll()
    return .boutConfirmed
  }

  private mutating func endIfSilent(now: Date) -> Event? {
    guard inBout, let last = lastPositive,
          now.timeIntervalSince(last) >= config.endSilence else { return nil }
    inBout = false
    recentPositives.removeAll()
    lastPositive = nil
    return .boutEnded
  }
}

/// Live-microphone cry detection: an `AVAudioEngine` mic tap feeds an
/// `SNAudioStreamAnalyzer` running Apple's built-in sound classifier, and the
/// per-window confidence drives the pure `CryBoutTracker` above. Only the thin
/// capture/plumbing lives here — all debounce logic is the tracker, so this
/// class is deliberately unit-test-free (it needs real hardware) while the
/// AC6/AC7 timing is fully tested.
///
/// Runs only while a settling session is active and the mic toggle is on
/// (`LightViewModel`). Nothing is recorded or persisted: buffers are classified
/// in memory and dropped (specs/2026-07-10-deep-sleep-tip → privacy). Classifier
/// callbacks arrive off the main thread (patterns §8) — bout events hop back to
/// main before touching any shared state.
final class CryDetector: NSObject, SNResultsObserving {

  /// Classifier identifiers treated as "baby crying". Verified against
  /// `SNClassifySoundRequest(.version1).knownClassifications` at integration
  /// (plan 4.2): `baby_crying` is primary; `crying_sobbing` is accepted if the
  /// installed classifier exposes it.
  static let cryLabels: Set<String> = ["baby_crying", "crying_sobbing"]

  /// Fired on the main thread when a bout is confirmed / ends.
  var onBoutConfirmed: ((Date) -> Void)?
  var onBoutEnded: ((Date) -> Void)?

  private let audioEngine = AVAudioEngine()
  private var analyzer: SNAudioStreamAnalyzer?
  private let analysisQueue = DispatchQueue(label: "com.tadas.Baby-Light.cry-analysis")
  private var tracker: CryBoutTracker

  init(config: CryBoutTracker.Config = .init()) {
    self.tracker = CryBoutTracker(config: config)
  }

  /// Request permission, then start capture. `completion(false)` means the mic
  /// is unavailable (permission denied or capture failed) — a silent, expected
  /// fallback to the app-open anchor (AC8); the caller leaves the engine on
  /// `.appOpen`. Always called on the main thread.
  func start(completion: @escaping (Bool) -> Void) {
    AVAudioApplication.requestRecordPermission { [weak self] granted in
      DispatchQueue.main.async {
        guard granted, let self else { completion(false); return }
        completion(self.beginCapture())
      }
    }
  }

  func stop() {
    if audioEngine.isRunning {
      audioEngine.inputNode.removeTap(onBus: 0)
      audioEngine.stop()
    }
    analyzer?.removeAllRequests()
    analyzer = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func beginCapture() -> Bool {
    // Never install a second tap on the same bus — that throws an (uncatchable)
    // exception. A redundant start tears the old capture down first.
    if audioEngine.isRunning { stop() }

    // Activate the record session BEFORE touching the input node. The input
    // format is only valid — and only matches the hardware the tap and engine
    // will actually run against — once the `.record` session is active. Reading
    // it first (as the original code did) yields a mismatched format, and
    // `AVAudioEngine` then raises an Objective-C exception at `start()` that
    // Swift `do/catch` cannot intercept — an outright crash on enable.
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.record, mode: .measurement, options: [])
      try session.setActive(true, options: [])
    } catch {
      return false
    }

    let input = audioEngine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else {
      try? AVAudioSession.sharedInstance().setActive(false)
      return false
    }

    let analyzer = SNAudioStreamAnalyzer(format: format)
    do {
      let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
      request.windowDuration = CMTime(seconds: 1.5, preferredTimescale: 1000)
      request.overlapFactor = 0.5
      try analyzer.add(request, withObserver: self)
    } catch {
      try? AVAudioSession.sharedInstance().setActive(false)
      return false
    }
    self.analyzer = analyzer

    input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, when in
      self?.analysisQueue.async {
        self?.analyzer?.analyze(buffer, atAudioFramePosition: when.sampleTime)
      }
    }

    audioEngine.prepare()
    do {
      try audioEngine.start()
      return true
    } catch {
      stop()
      return false
    }
  }

  // MARK: - SNResultsObserving

  func request(_ request: SNRequest, didProduce result: SNResult) {
    guard let result = result as? SNClassificationResult else { return }
    let confidence = result.classifications
      .filter { Self.cryLabels.contains($0.identifier) }
      .map(\.confidence)
      .max() ?? 0
    // The tracker is only ever touched from the serial analysis queue, so its
    // mutation here needs no extra lock.
    let now = Date()
    guard let event = tracker.observe(confidence: confidence, at: now) else { return }
    DispatchQueue.main.async { [weak self] in
      switch event {
      case .boutConfirmed: self?.onBoutConfirmed?(now)
      case .boutEnded: self?.onBoutEnded?(now)
      }
    }
  }
}
