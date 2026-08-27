import 'chameleon_icons_platform_interface.dart';

class ChameleonIcons {
  Future<String?> getPlatformVersion() {
    return ChameleonIconsPlatform.instance.getPlatformVersion();
  }

  Future<void> changeIcon(String targetIconClassName) {
    return ChameleonIconsPlatform.instance.changeIcon(targetIconClassName);
  }

  // Future<String?> getCurrentIconClassName() {
  //   return ChameleonIconsPlatform.instance.getCurrentIconClassName();
  // }

  Future<void> resetIcon() {
    return ChameleonIconsPlatform.instance.resetIcon();
  }
}
