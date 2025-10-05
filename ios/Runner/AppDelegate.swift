import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyC7NLRAlv0qJVyF4sRzQfVR_AKhkDO5ekA")
    
    // Registrar plugin de control de volumen
    let controller = window?.rootViewController as! FlutterViewController
    let volumeChannel = FlutterMethodChannel(name: "volume_controller", binaryMessenger: controller.binaryMessenger)
    volumeChannel.setMethodCallHandler { (call, result) in
        VolumeControllerPlugin.handle(call, result: result)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
