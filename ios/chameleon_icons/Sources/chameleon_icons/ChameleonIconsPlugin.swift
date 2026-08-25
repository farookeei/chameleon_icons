import Flutter
import UIKit

public class ChameleonIconsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "chameleon_icons", binaryMessenger: registrar.messenger())
        let instance = ChameleonIconsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " +     UIDevice.current.systemVersion)
        case "getCurrentIconClassName":
            // If alternateIconName is nil, the primary default icon is active!
            let currentIcon =      UIApplication.shared.alternateIconName ?? "MainActivityDefault"
            result(currentIcon)
            
        case "changeIcon":
            let args = call.arguments as? [String:Any]
            //passing nil to setAlternateIconName changes it back to the original app icon
            let targetIcon = args?["targetIcon"] as? String
            
            
            guard UIApplication.shared.supportsAlternateIcons else{
                // If the device does not support dynamic icons (e.g. some iPads/old iOS):
                return  result (FlutterError(code: "UNSUPPORTED", message: "Alternate icons is not supported in this device", details: nil))
            }
            
            UIApplication.shared.setAlternateIconName(targetIcon) {
                error in
                if let error = error{
                    result (FlutterError(code: "CHANGE_ICON_FAILED", message: error.localizedDescription, details:nil))
                }else{
                    result(true)
                }
            }
            
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
