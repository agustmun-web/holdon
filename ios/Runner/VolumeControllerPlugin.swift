import Flutter
import UIKit
import AVFoundation
import MediaPlayer

public class VolumeControllerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "volume_controller", binaryMessenger: registrar.messenger())
        let instance = VolumeControllerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setVolume":
            guard let args = call.arguments as? [String: Any],
                  let volume = args["volume"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Volume argument is required", details: nil))
                return
            }
            setVolume(volume: volume, result: result)
        case "getVolume":
            getVolume(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setVolume(volume: Double, result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Configurar el volumen del sistema
            let volumeView = MPVolumeView()
            if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                slider.value = Float(volume)
            }
            
            result(true)
        } catch {
            result(FlutterError(code: "VOLUME_ERROR", message: "Error setting volume: \(error.localizedDescription)", details: nil))
        }
    }

    private func getVolume(result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            let volume = AVAudioSession.sharedInstance().outputVolume
            result(volume)
        } catch {
            result(FlutterError(code: "VOLUME_ERROR", message: "Error getting volume: \(error.localizedDescription)", details: nil))
        }
    }
}
