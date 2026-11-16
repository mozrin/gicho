import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let assetKey = FlutterDartProject.lookupKey(forAsset: "assets/gicho/gicho.yaml")
    if let path = Bundle.main.path(forResource: assetKey, ofType: nil),
       let yaml = try? String(contentsOfFile: path, encoding: .utf8),
       let line = yaml.split(separator: "\n").first(where: {
         $0.trimmingCharacters(in: .whitespaces).hasPrefix("googleApiKey:")
       }) {
      let apiKey = line.split(separator: ":", maxSplits: 1).last?
        .trimmingCharacters(in: .whitespaces) ?? ""
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
