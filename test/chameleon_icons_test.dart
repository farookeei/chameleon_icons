import 'package:flutter_test/flutter_test.dart';
import 'package:chameleon_icons/chameleon_icons.dart';
import 'package:chameleon_icons/chameleon_icons_platform_interface.dart';
import 'package:chameleon_icons/chameleon_icons_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockChameleonIconsPlatform
    with MockPlatformInterfaceMixin
    implements ChameleonIconsPlatform {
  String? lastChangedIcon;
  bool resetIconCalled = false;

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> isAlternateIconsSupported() => Future.value(true);

  @override
  Future<void> changeIcon(String targetIconClassName) async {
    lastChangedIcon = targetIconClassName;
  }

  @override
  Future<void> resetIcon() async {
    resetIconCalled = true;
  }

  @override
  Future<String?> getCurrentIcon() => Future.value('MainActivityDark');
}

void main() {
  final ChameleonIconsPlatform initialPlatform =
      ChameleonIconsPlatform.instance;

  test('$MethodChannelChameleonIcons is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelChameleonIcons>());
  });

  test('getPlatformVersion', () async {
    final chameleon = ChameleonIcons();
    final fakePlatform = MockChameleonIconsPlatform();
    ChameleonIconsPlatform.instance = fakePlatform;

    expect(await chameleon.getPlatformVersion(), '42');
  });

  test('changeIcon calls platform instance', () async {
    final chameleon = ChameleonIcons();
    final fakePlatform = MockChameleonIconsPlatform();
    ChameleonIconsPlatform.instance = fakePlatform;

    await chameleon.changeIcon("MainActivityDark");
    expect(fakePlatform.lastChangedIcon, 'MainActivityDark');
  });

  test('resetIcon calls platform instance', () async {
    final chameleon = ChameleonIcons();
    final fakePlatform = MockChameleonIconsPlatform();
    ChameleonIconsPlatform.instance = fakePlatform;

    await chameleon.resetIcon();
    expect(fakePlatform.resetIconCalled, true);
  });

  test('getCurrentIcon calls platform instance', () async {
    final chameleon = ChameleonIcons();
    final fakePlatform = MockChameleonIconsPlatform();
    ChameleonIconsPlatform.instance = fakePlatform;

    expect(await chameleon.getCurrentIcon(), 'MainActivityDark');
  });

  test('isAlternateIconsSupported calls platform instance', () async {
    final chameleon = ChameleonIcons();
    final fakePlatform = MockChameleonIconsPlatform();
    ChameleonIconsPlatform.instance = fakePlatform;

    expect(await chameleon.isAlternateIconsSupported(), true);
  });
}
