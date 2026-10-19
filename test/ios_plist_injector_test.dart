import 'dart:io';

import 'package:chameleon_icons/src/config/chameleon_config.dart';
import 'package:chameleon_icons/src/injector/android_manifest_injector.dart';
import 'package:chameleon_icons/src/injector/ios_plist_injector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  group('IosPlistInjector', () {
    late Directory tempDir;
    late File plistFile;

    const sampleFreshPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>Test App</string>
	<key>CFBundleIdentifier</key>
	<string>com.example.test</string>
</dict>
</plist>''';

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('chameleon_plist_test_');
      final runnerDir = Directory('${tempDir.path}/ios/Runner')
        ..createSync(recursive: true);
      plistFile = File('${runnerDir.path}/Info.plist')
        ..writeAsStringSync(sampleFreshPlist);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final testConfig = ChameleonConfig(
      defaultIcon: const IconConfig(
        key: 'default',
        name: 'MainActivityDefault',
        imagePath: 'assets/icons/default.png',
        isDefault: true,
      ),
      alternateIcons: const [
        IconConfig(
          key: 'dark',
          name: 'MainActivityDark',
          imagePath: 'assets/icons/dark.png',
          isDefault: false,
        ),
        IconConfig(
          key: 'gold',
          name: 'MainActivityGold',
          imagePath: 'assets/icons/gold.png',
          isDefault: false,
        ),
      ],
    );

    test(
      'injects CFBundleIcons and CFBundleIcons~ipad into fresh Info.plist',
      () {
        final injector = IosPlistInjector(
          config: testConfig,
          projectRoot: tempDir.path,
        );

        injector.inject();

        final updatedContent = plistFile.readAsStringSync();

        // Ensure valid XML
        final doc = XmlDocument.parse(updatedContent);

        // Verify other keys remain intact
        final keys = doc
            .findAllElements('key')
            .map((k) => k.innerText)
            .toList();
        expect(keys, contains('CFBundleDisplayName'));
        expect(keys, contains('CFBundleIdentifier'));
        expect(keys, contains('CFBundleIcons'));
        expect(keys, contains('CFBundleIcons~ipad'));

        expect(updatedContent, contains('MainActivityDark'));
        expect(updatedContent, contains('dark_icon'));
        expect(updatedContent, contains('MainActivityGold'));
        expect(updatedContent, contains('gold_icon'));
      },
    );

    test('is strictly idempotent: running multiple times produces identical output', () {
      final injector = IosPlistInjector(
        config: testConfig,
        projectRoot: tempDir.path,
      );

      injector.inject();
      final firstRun = plistFile.readAsStringSync();

      injector.inject();
      final secondRun = plistFile.readAsStringSync();

      injector.inject();
      final thirdRun = plistFile.readAsStringSync();

      expect(secondRun, firstRun);
      expect(thirdRun, firstRun);

      final doc = XmlDocument.parse(thirdRun);
      final iconsKeys = doc
          .findAllElements('key')
          .where((k) => k.innerText == 'CFBundleIcons');
      expect(iconsKeys.length, 1);
    });

    test('dynamically updates alternate icons when config changes', () {
      final injector1 = IosPlistInjector(
        config: testConfig,
        projectRoot: tempDir.path,
      );
      injector1.inject();

      // Config with only 'dark'
      final updatedConfig = ChameleonConfig(
        defaultIcon: const IconConfig(
          key: 'default',
          name: 'MainActivityDefault',
          imagePath: 'assets/icons/default.png',
          isDefault: true,
        ),
        alternateIcons: const [
          IconConfig(
            key: 'dark',
            name: 'MainActivityDark',
            imagePath: 'assets/icons/dark.png',
            isDefault: false,
          ),
        ],
      );

      final injector2 = IosPlistInjector(
        config: updatedConfig,
        projectRoot: tempDir.path,
      );
      injector2.inject();

      final content = plistFile.readAsStringSync();
      expect(content, contains('MainActivityDark'));
      expect(content, isNot(contains('MainActivityGold'))); // Pruned!
    });

    test('throws ChameleonInjectionException if Info.plist does not exist', () {
      final nonExistentInjector = IosPlistInjector(
        config: testConfig,
        projectRoot: '/non/existent/path',
      );

      expect(
        () => nonExistentInjector.inject(),
        throwsA(isA<ChameleonInjectionException>()),
      );
    });

    test('throws ChameleonInjectionException if Info.plist is invalid XML', () {
      plistFile.writeAsStringSync('MALFORMED PLIST CONTENT <<<<<');

      final injector = IosPlistInjector(
        config: testConfig,
        projectRoot: tempDir.path,
      );

      expect(
        () => injector.inject(),
        throwsA(isA<ChameleonInjectionException>()),
      );
      expect(plistFile.readAsStringSync(), 'MALFORMED PLIST CONTENT <<<<<');
    });

    test('preserves complex Info.plist with custom permissions, background modes, and URL schemes', () {
      const complexPlist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>Complex App</string>
	<key>NSCameraUsageDescription</key>
	<string>This app needs camera access to scan barcodes.</string>
	<key>UIBackgroundModes</key>
	<array>
		<string>fetch</string>
		<string>remote-notification</string>
	</array>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>customscheme</string>
			</array>
		</dict>
	</array>
</dict>
</plist>''';

      plistFile.writeAsStringSync(complexPlist);

      final injector = IosPlistInjector(
        config: testConfig,
        projectRoot: tempDir.path,
      );

      injector.inject();

      final result = plistFile.readAsStringSync();
      final doc = XmlDocument.parse(result);

      // Verify custom keys are preserved
      expect(result, contains('<key>NSCameraUsageDescription</key>'));
      expect(
        result,
        contains(
          '<string>This app needs camera access to scan barcodes.</string>',
        ),
      );
      expect(result, contains('<key>UIBackgroundModes</key>'));
      expect(result, contains('<string>remote-notification</string>'));
      expect(result, contains('<key>CFBundleURLSchemes</key>'));
      expect(result, contains('<string>customscheme</string>'));

      // Verify CFBundleIcons and CFBundleIcons~ipad are present and valid
      expect(result, contains('<key>CFBundleIcons</key>'));
      expect(result, contains('<key>CFBundleIcons~ipad</key>'));
      expect(result, contains('dark_icon'));
      expect(result, contains('gold_icon'));

      // Ensure root dict has valid structure
      final dicts = doc.findAllElements('dict');
      expect(dicts, isNotEmpty);
    });
  });
}
