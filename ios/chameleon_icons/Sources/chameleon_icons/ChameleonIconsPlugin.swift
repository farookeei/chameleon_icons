import Flutter
import UIKit

public class ChameleonIconsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "chameleon_icons",
            binaryMessenger: registrar.messenger()
        )
        let instance = ChameleonIconsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "isAlternateIconsSupported":
            result(UIApplication.shared.supportsAlternateIcons)
        case "getCurrentIcon":
            // If alternateIconName is nil, the primary default icon is active!
            guard _ensureAlternateIconSupported(result: result) else{
                return
            }
            
            let currentIcon =
            UIApplication.shared.alternateIconName ?? getDefaultIcon()
            result(currentIcon)
            
        case "changeIcon":
            let args = call.arguments as? [String: Any]
            let targetIcon = args?["targetIcon"] as? String
            
            guard  _ensureAlternateIconSupported(result: result) else{
                return
            }
            setAlternateIcon(icon: targetIcon,result: result)
            
        case "resetIcon":
            guard _ensureAlternateIconSupported(result: result) else{
                return
            }
            setAlternateIcon(icon: nil,result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
        
        
    }
}


private  func setAlternateIcon(icon: String?,result :@escaping FlutterResult)  {
    UIApplication.shared.setAlternateIconName(icon) {
        error in
        if let error = error {
            result(
                FlutterError(
                    code: "CHANGE_ICON_FAILED",
                    message: error.localizedDescription,
                    details: nil
                )
            )
        } else {
            result(true)
        }
    }
}





private func _ensureAlternateIconSupported(result:  FlutterResult)->Bool{
    
    guard  UIApplication.shared.supportsAlternateIcons else{
        result(
            FlutterError(
                code: "UNSUPPORTED",
                message: "Alternate icons not supported",
                details: nil
            )
        )
        
        return false
    }
    
    return true
    
}


private func getDefaultIcon()->String{
    guard let  iconsDict =  Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
          let primaryIconDict =   iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
          let iconFiles = primaryIconDict["CFBundleIconFiles"] as? [String],
          let icon = iconFiles.first,
          !icon.isEmpty  else{
        return "AppIcon"
    }

    // Dynamically strips any trailing dimension like "60x60", "76x76", "1024x1024"
    // "ApplicationIcon60x60" -> "ApplicationIcon"
    // "AppIcon60x60"         -> "AppIcon"
    // "CustomIcon"           -> "CustomIcon"
    let cleanIconName = icon.replacingOccurrences(of: "\\d+x\\d+.*", with: "", options: .regularExpression)
    
    return icon
    
}


