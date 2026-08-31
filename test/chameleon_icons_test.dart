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
  Future<void> resetIcon() {
    // TODO: implement resetIcon
    throw UnimplementedError();
  }

  @override
  Future<String> getCurrentIcon() {
    //TODO : implement getCurrentIcon
    throw UnimplementedError();
  }

  @override
  Future<bool> isAlternateIconsSupported() {
    throw UnimplementedError();
  }
}

void main() {
  final ChameleonIconsPlatform initialPlatform =
      ChameleonIconsPlatform.instance;

  test('$MethodChannelChameleonIcons is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelChameleonIcons>());
  });

  test('changeIcon calls platform instance', () async {
    final chameleon = ChameleonIcons();
    final fakePlatform = MockChameleonIconsPlatform();
    ChameleonIconsPlatform.instance = fakePlatform;

    await chameleon.changeIcon("MainActivityDark");
    // expect(fakePlatform.lastChangedIcon, 'MainActivityDark');
  });

  test('getPlatformVersion', () async {
    ChameleonIcons chameleonIconsPlugin = ChameleonIcons();
    MockChameleonIconsPlatform fakePlatform = MockChameleonIconsPlatform();
    ChameleonIconsPlatform.instance = fakePlatform;

    expect(await chameleonIconsPlugin.getPlatformVersion(), '42');
  });
}
