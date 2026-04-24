import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let homeWidgetChannelName = "com.phoneshame/home_widget"
  private let homeWidgetAppGroup = "group.com.example.phoneshame.widgets"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: homeWidgetChannelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "saveWidgetData":
          guard let args = call.arguments as? [String: Any] else {
            result(
              FlutterError(
                code: "bad_args",
                message: "Expected widget payload map",
                details: nil
              )
            )
            return
          }
          self?.saveWidgetData(args)
          result(nil)
        case "refreshWidgets":
          self?.refreshWidgets()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveWidgetData(_ args: [String: Any]) {
    guard let defaults = UserDefaults(suiteName: homeWidgetAppGroup) else {
      return
    }

    let updatedAtValue = (args["updatedAtEpochMs"] as? NSNumber)?.int64Value
      ?? Int64(Date().timeIntervalSince1970 * 1000)

    defaults.set(args["totalMinutes"] as? Int ?? 0, forKey: "total_minutes")
    defaults.set(args["totalTimeLabel"] as? String ?? "0m", forKey: "total_time_label")
    defaults.set(args["score"] as? Int ?? 0, forKey: "score")
    defaults.set(args["topApp"] as? String ?? "No data yet", forKey: "top_app")
    defaults.set(args["topMinutes"] as? Int ?? 0, forKey: "top_minutes")
    defaults.set(args["topTimeLabel"] as? String ?? "0m", forKey: "top_time_label")
    defaults.set(args["trackedAppsCount"] as? Int ?? 0, forKey: "tracked_apps_count")
    defaults.set(updatedAtValue, forKey: "updated_at_epoch_ms")
    defaults.set(args["hasData"] as? Bool ?? false, forKey: "has_data")
    defaults.synchronize()
  }

  private func refreshWidgets() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}
