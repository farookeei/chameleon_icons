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
            //not used currently
//        case "getCurrentIconClassName":
//            // If alternateIconName is nil, the primary default icon is active!
//            let currentIcon =
//                UIApplication.shared.alternateIconName
//            result(currentIcon)

        case "changeIcon":
            let args = call.arguments as? [String: Any]
            let targetIcon = args?["targetIcon"] as? String
            guard UIApplication.shared.supportsAlternateIcons else {
                return result(
                    FlutterError(
                        code: "UNSUPPORTED",
                        message: "Alternate icons not supported",
                        details: nil
                    )
                )
            }
             
            setAlternateIcon(icon: targetIcon,result: result)

        case "resetIcon":
            let args = call.arguments as? [String: Any]

            guard UIApplication.shared.supportsAlternateIcons else {
                return result(
                    FlutterError(
                        code: "UNSUPPORTED",
                        message: "Alternate icons not supported",
                        details: nil
                    )

                )
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
