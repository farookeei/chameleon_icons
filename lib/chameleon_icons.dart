import 'chameleon_icons_platform_interface.dart';

/// The main entry point for the Chameleon Icons plugin.
///
/// Use [ChameleonIcons] to dynamically change, reset, and inspect app launcher
/// icons at runtime across Android and iOS.
///
/// Example:
/// ```dart
/// final chameleon = ChameleonIcons();
///
/// // Check if alternate icons are supported on this device:
/// if (await chameleon.isAlternateIconsSupported()) {
///   // Change to a dark icon:
///   await chameleon.changeIcon("MainActivityDark");
///
///   // Reset back to default primary icon:
///   await chameleon.resetIcon();
///
///   // Check currently active icon:
///   final active = await chameleon.getCurrentIcon();
///   print('Active icon: $active');
/// }
/// ```
class ChameleonIcons {
  /// Constructs a [ChameleonIcons] instance.
  const ChameleonIcons();

  /// Returns the current host operating system version string.
  Future<String?> getPlatformVersion() {
    return ChameleonIconsPlatform.instance.getPlatformVersion();
  }

  /// Checks whether dynamic alternate icons are supported on the current device.
  ///
  /// On iOS, this checks `UIApplication.shared.supportsAlternateIcons`.
  /// On Android, this checks if the default icon metadata is configured in `AndroidManifest.xml`.
  ///
  /// Returns `true` if alternate icons can be changed, or `false` otherwise.
  Future<bool> isAlternateIconsSupported() {
    return ChameleonIconsPlatform.instance.isAlternateIconsSupported();
  }

  /// Dynamically changes the app launcher icon to [targetIconClassName].
  ///
  /// - On Android: Enables the corresponding `<activity-alias>` and disables
  ///   other launcher aliases.
  /// - On iOS: Calls `UIApplication.shared.setAlternateIconName([targetIconClassName])`.
  ///
  /// Throws a [PlatformException] if the operation fails or is unsupported.
  Future<void> changeIcon(String targetIconClassName) {
    return ChameleonIconsPlatform.instance.changeIcon(targetIconClassName);
  }

  /// Retrieves the identifier of the currently active app launcher icon.
  ///
  /// - On Android: Returns the simple class name of the enabled activity alias
  ///   (e.g. `"MainActivityDark"` or `"MainActivityDefault"`).
  /// - On iOS: Returns the active alternate icon name, or dynamically extracts
  ///   the primary icon name from `Info.plist` (e.g. `"AppIcon"`).
  ///
  /// Returns a non-null [String] representing the active icon name.
  Future<String> getCurrentIcon() {
    return ChameleonIconsPlatform.instance.getCurrentIcon();
  }

  /// Resets the app launcher icon back to the primary default icon.
  ///
  /// - On Android: Re-enables the default `<activity-alias>` and disables alternates.
  /// - On iOS: Calls `UIApplication.shared.setAlternateIconName(nil)` to restore `CFBundlePrimaryIcon`.
  ///
  /// Throws a [PlatformException] if the operation fails or is unsupported.
  Future<void> resetIcon() {
    return ChameleonIconsPlatform.instance.resetIcon();
  }
}
