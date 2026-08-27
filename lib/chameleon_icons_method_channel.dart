import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'chameleon_icons_platform_interface.dart';

/// An implementation of [ChameleonIconsPlatform] that uses method channels.
class MethodChannelChameleonIcons extends ChameleonIconsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('chameleon_icons');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> changeIcon(String targetIconClassName) async {
    await methodChannel.invokeMethod("changeIcon", {
      "targetIcon": targetIconClassName,
    });
  }

  // @override
  // Future<String?> getCurrentIconClassName() async {
  //   final val = await methodChannel.invokeMethod("getCurrentIconClassName");
  //   return val;
  // }

  @override
  Future<void> resetIcon() async {
    await methodChannel.invokeMethod("resetIcon");
  }
}
