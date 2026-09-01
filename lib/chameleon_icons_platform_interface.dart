import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'chameleon_icons_method_channel.dart';

abstract class ChameleonIconsPlatform extends PlatformInterface {
  /// Constructs a ChameleonIconsPlatform.
  ChameleonIconsPlatform() : super(token: _token);

  static final Object _token = Object();

  static ChameleonIconsPlatform _instance = MethodChannelChameleonIcons();

  /// The default instance of [ChameleonIconsPlatform] to use.
  ///
  /// Defaults to [MethodChannelChameleonIcons].
  static ChameleonIconsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ChameleonIconsPlatform] when
  /// they register themselves.
  static set instance(ChameleonIconsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> isAlternateIconsSupported() {
    throw UnimplementedError(
      "isAlternateIconsSupported() has not been implemented.",
    );
  }

  Future<void> changeIcon(String targetIconClassName) {
    throw UnimplementedError('changeIcon() has not been implemented.');
  }

  Future<void> resetIcon() {
    throw UnimplementedError('resetIcon() has not been implemented.');
  }

  Future<String> getCurrentIcon() {
    throw UnimplementedError('getCurrentIcon() has not been implemented.');
  }
}
