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
            let args = call.arguments as? [String: Any]
            let targetIcon = args?["targetIcon"] as? String
            guard UIApplication.shared.supportsAlternateIcons else {
                return result(FlutterError(code: "UNSUPPORTED", message: "Alternate icons not supported", details: nil))
            }
            // If it's the default icon name, convert it to nil for Apple's API:
            let iconNameToSet = (targetIcon == "MainActivityDefault" || targetIcon == "default" || targetIcon == nil) ? nil : targetIcon
            UIApplication.shared.setAlternateIconName(iconNameToSet) { error in
                if let error = error {
                    result(FlutterError(code: "CHANGE_ICON_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
            
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
