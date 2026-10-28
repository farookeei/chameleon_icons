import 'package:flutter/foundation.dart';

import 'src/models/chameleon_icon_definition.dart';
import 'src/platform/chameleon_icons_platform_interface.dart';
export 'src/models/chameleon_icon_definition.dart';

/// The main entry point for the Chameleon Icons plugin.
///
/// Use [ChameleonIcons] to dynamically change, reset, and inspect app launcher
/// icons at runtime across Android and iOS.
class ChameleonIcons {
  static final ChameleonIcons _instance = ChameleonIcons._internal();

  /// Returns the singleton [ChameleonIcons] instance.
  factory ChameleonIcons() => _instance;

  ChameleonIcons._internal();

  /// A [ValueNotifier] holding the currently active icon definition.
  ///
  /// Can be bound directly to a `ValueListenableBuilder` in UI without requiring
  /// manual `initState` fetching or local state variables.
  final ValueNotifier<ChameleonIconDefinition?> activeIconNotifier =
      ValueNotifier<ChameleonIconDefinition?>(null);

  /// Returns the current host operating system version string.
  Future<String?> getPlatformVersion() {
    return ChameleonIconsPlatform.instance.getPlatformVersion();
  }

  /// Checks whether dynamic alternate icons are supported on the current device.
  ///
  /// On iOS, this checks `UIApplication.shared.supportsAlternateIcons`.
  /// On Android, this checks if the default icon metadata is configured in `AndroidManifest.xml`.
  Future<bool> isAlternateIconsSupported() {
    return ChameleonIconsPlatform.instance.isAlternateIconsSupported();
  }

  /// Dynamically changes the app launcher icon to [targetIconClassName].
  Future<void> changeIcon(String targetIconClassName) {
    return ChameleonIconsPlatform.instance.changeIcon(targetIconClassName);
  }

  /// Changes or resets the app launcher icon using a [ChameleonIconDefinition].
  ///
  /// If [icon.isDefault] is true, calls [resetIcon]. Otherwise, calls [changeIcon].
  /// Updates [activeIconNotifier] automatically.
  Future<void> setIcon(ChameleonIconDefinition icon) async {
    if (icon.isDefault) {
      await resetIcon();
    } else {
      await changeIcon(icon.id);
    }
    activeIconNotifier.value = icon;
  }

  /// Checks if the default primary icon is currently active.
  Future<bool> isDefaultIcon() async {
    final active = await getCurrentIcon();
    return active == 'MainActivityDefault' ||
        active == 'AppIcon' ||
        active.isEmpty;
  }

  /// Retrieves the identifier of the currently active app launcher icon.
  Future<String> getCurrentIcon() {
    return ChameleonIconsPlatform.instance.getCurrentIcon();
  }

  /// Automatically resolves and returns the currently active [ChameleonIconDefinition]
  /// from the provided [icons] list (typically `ChameleonGeneratedIcons.all`).
  ///
  /// Also synchronizes [activeIconNotifier].
  Future<ChameleonIconDefinition> getActiveIcon(
    List<ChameleonIconDefinition> icons,
  ) async {
    final activeName = await getCurrentIcon();
    final matched = icons.firstWhere(
      (icon) => icon.matches(activeName),
      orElse: () =>
          icons.firstWhere((icon) => icon.isDefault, orElse: () => icons.first),
    );
    activeIconNotifier.value = matched;
    return matched;
  }

  /// Initializes and listens to the active icon from [icons].
  ///
  /// Safe to call on app startup or widget initialization.
  Future<ChameleonIconDefinition> initialize(
    List<ChameleonIconDefinition> icons,
  ) {
    return getActiveIcon(icons);
  }

  /// Resets the app launcher icon back to the primary default icon.
  Future<void> resetIcon() async {
    await ChameleonIconsPlatform.instance.resetIcon();
  }
}
