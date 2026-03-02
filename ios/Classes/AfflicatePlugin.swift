import Flutter
import UIKit

public class AfflicatePlugin: NSObject, FlutterPlugin {
    private static let channelName = "com.afflicate.sdk/attribution"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = AfflicatePlugin()
        registrar.addMethodCallDelegate(instance, channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getClickIdFromLaunchUrl":
            result(clickIdFromLaunchUrl())
        case "getClickIdFromClipboard":
            result(nil)
        case "getClickIdFromReferrer":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func clickIdFromLaunchUrl() -> String? {
        guard let urlString = AfflicatePluginStorage.launchUrl,
              let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            return nil
        }
        return items.first(where: { $0.name == "click_id" })?.value
    }

    /// Call from AppDelegate when the app is opened via Universal Link.
    public static func setLaunchUrl(_ url: URL?) {
        // Plugin instance is not retained by Flutter; app must pass URL at init.
        // So we use a static store that the app sets from AppDelegate.
        AfflicatePluginStorage.launchUrl = url?.absoluteString
    }
}

private enum AfflicatePluginStorage {
    static var launchUrl: String?
}
