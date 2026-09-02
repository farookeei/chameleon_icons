import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'chameleon_icons_method_channel.dart';

/// The common platform interface for [ChameleonIcons].
///
/// Platform implementations must extend this class and register themselves
/// with [ChameleonIconsPlatform.instance].
abstract class ChameleonIconsPlatform extends PlatformInterface {
  /// Constructs a [ChameleonIconsPlatform].
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

  /// Returns the platform version of the host operating system.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Checks whether alternate launcher icons are supported on the current device.
  Future<bool> isAlternateIconsSupported() {
    throw UnimplementedError(
      'isAlternateIconsSupported() has not been implemented.',
    );
  }

  /// Changes the app launcher icon to the specified [targetIconClassName].
  Future<void> changeIcon(String targetIconClassName) {
    throw UnimplementedError('changeIcon() has not been implemented.');
  }

  /// Resets the app launcher icon to the default primary icon.
  Future<void> resetIcon() {
    throw UnimplementedError('resetIcon() has not been implemented.');
  }

  /// Retrieves the active app launcher icon identifier.
  Future<String> getCurrentIcon() {
    throw UnimplementedError('getCurrentIcon() has not been implemented.');
  }
}
