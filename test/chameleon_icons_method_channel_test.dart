import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chameleon_icons/chameleon_icons_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelChameleonIcons platform = MethodChannelChameleonIcons();
  const MethodChannel channel = MethodChannel('chameleon_icons');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('isAlternateIconsSupported invokes channel method', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'isAlternateIconsSupported') {
            return true;
          }
          return null;
        });

    expect(await platform.isAlternateIconsSupported(), true);
  });

  test('changeIcon passes targetIcon map argument', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          receivedCall = methodCall;
          return true;
        });

    await platform.changeIcon('MainActivityDark');
    expect(receivedCall?.method, 'changeIcon');
    expect(receivedCall?.arguments, {'targetIcon': 'MainActivityDark'});
  });

  test('resetIcon invokes channel method', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          receivedCall = methodCall;
          return true;
        });

    await platform.resetIcon();
    expect(receivedCall?.method, 'resetIcon');
  });

  test('getCurrentIcon returns active icon string', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getCurrentIcon') {
            return 'MainActivityDark';
          }
          return null;
        });

    expect(await platform.getCurrentIcon(), 'MainActivityDark');
  });
}
