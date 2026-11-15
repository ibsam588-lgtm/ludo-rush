import Flutter
import AppTrackingTransparency
import GameKit
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var gameAuthenticationResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    FlutterMethodChannel(name: "ludo_rush/app", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        self?.handleAppCall(call, result: result)
      }
    FlutterMethodChannel(name: "ludo_rush/play_games", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        self?.handleGameCall(call, result: result)
      }
  }

  private var foregroundScene: UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
  }

  private var presentingController: UIViewController? {
    var controller = foregroundScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  private func handleAppCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "getVersionInfo":
      result([
        "versionName": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
        "buildNumber": Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0,
      ])
    case "openUrl":
      guard let value = arguments["url"] as? String,
            let url = URL(string: value),
            ["https", "http", "itms-apps", "mailto"].contains(url.scheme?.lowercased() ?? "") else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
    case "shareText":
      guard let text = arguments["text"] as? String, !text.isEmpty,
            let controller = presentingController else {
        result(false)
        return
      }
      let share = UIActivityViewController(activityItems: [text], applicationActivities: nil)
      if let popover = share.popoverPresentationController {
        popover.sourceView = controller.view
        popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
      }
      controller.present(share, animated: true) { result(true) }
    case "requestInAppReview":
      if let scene = foregroundScene {
        if #available(iOS 16.0, *) {
          AppStore.requestReview(in: scene)
        } else {
          SKStoreReviewController.requestReview(in: scene)
        }
      }
      result(nil)
    case "prepareAdsPrivacy":
      guard foregroundScene != nil,
            ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
        result(nil)
        return
      }
      ATTrackingManager.requestTrackingAuthorization { _ in
        DispatchQueue.main.async { result(nil) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGameCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "isAuthenticated":
      result(GKLocalPlayer.local.isAuthenticated)
    case "signIn":
      authenticateGameCenter(result: result)
    case "submitScore":
      guard GKLocalPlayer.local.isAuthenticated,
            let identifier = arguments["id"] as? String,
            let score = arguments["score"] as? NSNumber,
            score.intValue > 0 else {
        result(false)
        return
      }
      GKLeaderboard.submitScore(score.intValue, context: 0, player: GKLocalPlayer.local,
                                leaderboardIDs: [identifier]) { error in
        DispatchQueue.main.async { result(error == nil) }
      }
    case "unlockAchievement":
      guard GKLocalPlayer.local.isAuthenticated,
            let identifier = arguments["id"] as? String else {
        result(false)
        return
      }
      let achievement = GKAchievement(identifier: identifier)
      achievement.percentComplete = 100
      achievement.showsCompletionBanner = true
      GKAchievement.report([achievement]) { error in
        DispatchQueue.main.async { result(error == nil) }
      }
    case "showLeaderboard":
      guard GKLocalPlayer.local.isAuthenticated, foregroundScene != nil else {
        result(false)
        return
      }
      GKAccessPoint.shared.parentWindow = foregroundScene?.windows.first(where: { $0.isKeyWindow })
      if #available(iOS 18.0, *), let identifier = arguments["id"] as? String {
        GKAccessPoint.shared.trigger(leaderboardID: identifier, playerScope: .global, timeScope: .allTime) {
          result(true)
        }
      } else {
        GKAccessPoint.shared.trigger(state: .leaderboards) { result(true) }
      }
    case "showAchievements":
      guard GKLocalPlayer.local.isAuthenticated, foregroundScene != nil else {
        result(false)
        return
      }
      GKAccessPoint.shared.parentWindow = foregroundScene?.windows.first(where: { $0.isKeyWindow })
      GKAccessPoint.shared.trigger(state: .achievements) { result(true) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func authenticateGameCenter(result: @escaping FlutterResult) {
    if GKLocalPlayer.local.isAuthenticated {
      result(true)
      return
    }
    guard gameAuthenticationResult == nil else {
      result(false)
      return
    }
    gameAuthenticationResult = result
    GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
      DispatchQueue.main.async {
        guard let self = self else { return }
        if let controller = controller, let presenter = self.presentingController {
          presenter.present(controller, animated: true)
          return
        }
        let completion = self.gameAuthenticationResult
        self.gameAuthenticationResult = nil
        completion?(error == nil && GKLocalPlayer.local.isAuthenticated)
      }
    }
  }
}
