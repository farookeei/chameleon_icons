import 'chameleon_icons_platform_interface.dart';

class ChameleonIcons {
  Future<String?> getPlatformVersion() {
    return ChameleonIconsPlatform.instance.getPlatformVersion();
  }

  Future<bool> isAlternateIconsSupported() {
    return ChameleonIconsPlatform.instance.isAlternateIconsSupported();
  }

  Future<void> changeIcon(String targetIconClassName) {
    return ChameleonIconsPlatform.instance.changeIcon(targetIconClassName);
  }

  Future<String> getCurrentIcon() {
    return ChameleonIconsPlatform.instance.getCurrentIcon();
  }

  Future<void> resetIcon() {
    return ChameleonIconsPlatform.instance.resetIcon();
  }
}
