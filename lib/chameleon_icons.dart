import 'chameleon_icons_platform_interface.dart';

class ChameleonIcons {
  Future<String?> getPlatformVersion() {
    return ChameleonIconsPlatform.instance.getPlatformVersion();
  }
}
