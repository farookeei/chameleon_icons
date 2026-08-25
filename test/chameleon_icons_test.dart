import 'package:flutter_test/flutter_test.dart';
import 'package:chameleon_icons/chameleon_icons.dart';
import 'package:chameleon_icons/chameleon_icons_platform_interface.dart';
import 'package:chameleon_icons/chameleon_icons_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockChameleonIconsPlatform
    with MockPlatformInterfaceMixin
    implements ChameleonIconsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> changeIcon(String targetIconClassName) {
    // TODO: implement changeIcon
    throw UnimplementedError();
  }

  @override
  Future<String?> getCurrentIconClassName() {
    // TODO: implement getCurrentIconClassName
    throw UnimplementedError();
  }
}

void main() {
  final ChameleonIconsPlatform initialPlatform =
      ChameleonIconsPlatform.instance;

  test('$MethodChannelChameleonIcons is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelChameleonIcons>());
  });

  test('getPlatformVersion', () async {
    ChameleonIcons chameleonIconsPlugin = ChameleonIcons();
    MockChameleonIconsPlatform fakePlatform = MockChameleonIconsPlatform();
    ChameleonIconsPlatform.instance = fakePlatform;

    expect(await chameleonIconsPlugin.getPlatformVersion(), '42');
  });
}
