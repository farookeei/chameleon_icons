import 'dart:io';

import 'package:chameleon_icons/src/config/chameleon_config.dart';
import 'package:chameleon_icons/src/injector/android_manifest_injector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  group('AndroidManifestInjector', () {
    late Directory tempDir;
    late File manifestFile;

    const sampleManifest =
        '''<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="test_app"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>''';

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('chameleon_manifest_test_');
      final manifestDir = Directory('${tempDir.path}/android/app/src/main')
        ..createSync(recursive: true);
      manifestFile = File('${manifestDir.path}/AndroidManifest.xml')
        ..writeAsStringSync(sampleManifest);
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
      'injects metadata and activity aliases into a fresh AndroidManifest.xml',
      () {
        final injector = AndroidManifestInjector(
          config: testConfig,
          projectRoot: tempDir.path,
        );

        injector.inject();

        final updatedContent = manifestFile.readAsStringSync();

        // Ensure valid XML
        final doc = XmlDocument.parse(updatedContent);

        // Verify launcher intent filter is removed from MainActivity
        final mainActivity = doc.findAllElements('activity').first;
        final launcherCategory = mainActivity
            .findAllElements('category')
            .where(
              (cat) =>
                  cat.getAttribute('android:name') ==
                  'android.intent.category.LAUNCHER',
            );
        expect(launcherCategory, isEmpty);

        // Verify metadata exists
        final metadata = doc
            .findAllElements('meta-data')
            .where(
              (m) =>
                  m.getAttribute('android:name') ==
                  AndroidManifestInjector.defaultAliasMetadata,
            );
        expect(metadata.length, 1);
        expect(
          metadata.first.getAttribute('android:value'),
          'MainActivityDefault',
        );

        // Verify activity aliases
        final aliases = doc.findAllElements('activity-alias').toList();
        expect(aliases.length, 3);

        final defaultAlias = aliases.firstWhere(
          (a) => a.getAttribute('android:name') == '.MainActivityDefault',
        );
        expect(defaultAlias.getAttribute('android:enabled'), 'true');
        expect(
          defaultAlias.getAttribute('android:icon'),
          '@mipmap/ic_launcher',
        );
        expect(
          defaultAlias.getAttribute('android:targetActivity'),
          '.MainActivity',
        );

        final darkAlias = aliases.firstWhere(
          (a) => a.getAttribute('android:name') == '.MainActivityDark',
        );
        expect(darkAlias.getAttribute('android:enabled'), 'false');
        expect(
          darkAlias.getAttribute('android:icon'),
          '@mipmap/ic_launcher_dark',
        );

        final goldAlias = aliases.firstWhere(
          (a) => a.getAttribute('android:name') == '.MainActivityGold',
        );
        expect(goldAlias.getAttribute('android:enabled'), 'false');
        expect(
          goldAlias.getAttribute('android:icon'),
          '@mipmap/ic_launcher_gold',
        );

        // Verify markers exist
        expect(
          updatedContent.contains(AndroidManifestInjector.startMarker),
          isTrue,
        );
        expect(
          updatedContent.contains(AndroidManifestInjector.endMarker),
          isTrue,
        );
      },
    );

    test('is strictly idempotent: running multiple times produces identical output without duplicate tags', () {
      final injector = AndroidManifestInjector(
        config: testConfig,
        projectRoot: tempDir.path,
      );

      // Run 1st time
      injector.inject();
      final firstRunContent = manifestFile.readAsStringSync();

      // Run 2nd time
      injector.inject();
      final secondRunContent = manifestFile.readAsStringSync();

      // Run 3rd time
      injector.inject();
      final thirdRunContent = manifestFile.readAsStringSync();

      expect(secondRunContent, firstRunContent);
      expect(thirdRunContent, firstRunContent);

      // Verify no duplicate tags
      final doc = XmlDocument.parse(thirdRunContent);
      expect(doc.findAllElements('activity-alias').length, 3);
      expect(
        doc
            .findAllElements('meta-data')
            .where(
              (m) =>
                  m.getAttribute('android:name') ==
                  AndroidManifestInjector.defaultAliasMetadata,
            )
            .length,
        1,
      );
    });

    test('dynamically updates aliases when configuration changes', () {
      final injector1 = AndroidManifestInjector(
        config: testConfig,
        projectRoot: tempDir.path,
      );
      injector1.inject();

      // Now create a new config with only 1 alternate icon ('dark')
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

      final injector2 = AndroidManifestInjector(
        config: updatedConfig,
        projectRoot: tempDir.path,
      );
      injector2.inject();

      final doc = XmlDocument.parse(manifestFile.readAsStringSync());
      final aliases = doc.findAllElements('activity-alias').toList();

      expect(aliases.length, 2); // Default and Dark only (Gold was pruned!)
      expect(
        aliases.any(
          (a) => a.getAttribute('android:name') == '.MainActivityGold',
        ),
        isFalse,
      );
    });

    test('throws ChameleonInjectionException if AndroidManifest.xml does not exist', () {
      final nonExistentInjector = AndroidManifestInjector(
        config: testConfig,
        projectRoot: '/non/existent/path',
      );

      expect(
        () => nonExistentInjector.inject(),
        throwsA(isA<ChameleonInjectionException>()),
      );
    });

    test('throws ChameleonInjectionException if XML is corrupt and leaves file untouched', () {
      manifestFile.writeAsStringSync('THIS IS NOT VALID XML <<<<<');

      final injector = AndroidManifestInjector(
        config: testConfig,
        projectRoot: tempDir.path,
      );

      expect(
        () => injector.inject(),
        throwsA(isA<ChameleonInjectionException>()),
      );

      // Verify original content was untouched
      expect(manifestFile.readAsStringSync(), 'THIS IS NOT VALID XML <<<<<');
    });

    test(
      'throws ChameleonInjectionException if <application> element is missing',
      () {
        manifestFile.writeAsStringSync('<manifest></manifest>');

        final injector = AndroidManifestInjector(
          config: testConfig,
          projectRoot: tempDir.path,
        );

        expect(
          () => injector.inject(),
          throwsA(isA<ChameleonInjectionException>()),
        );
      },
    );

    test('preserves complex manifests with custom services, receivers, permissions, and extra activities', () {
      const complexManifest = '''<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.example.app">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <application
        android:label="Complex App"
        android:icon="@mipmap/ic_launcher">
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT"/>
            </intent-filter>
        </service>
        <receiver
            android:name=".CustomBroadcastReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <activity
            android:name=".SettingsActivity"
            android:exported="false"/>
    </application>
    <queries>
        <package android:name="com.google.android.apps.maps"/>
    </queries>
</manifest>''';

      manifestFile.writeAsStringSync(complexManifest);

      final injector = AndroidManifestInjector(
        config: testConfig,
        projectRoot: tempDir.path,
      );

      injector.inject();

      final result = manifestFile.readAsStringSync();
      final doc = XmlDocument.parse(result);

      // 1. Verify permissions are preserved
      final permissions = doc
          .findAllElements('uses-permission')
          .map((p) => p.getAttribute('android:name'))
          .toList();
      expect(
        permissions,
        containsAll([
          'android.permission.INTERNET',
          'android.permission.POST_NOTIFICATIONS',
        ]),
      );

      // 2. Verify custom service is preserved
      final services = doc.findAllElements('service').toList();
      expect(services.length, 1);
      expect(
        services.first.getAttribute('android:name'),
        'com.google.firebase.messaging.FirebaseMessagingService',
      );

      // 3. Verify custom receiver is preserved
      final receivers = doc.findAllElements('receiver').toList();
      expect(receivers.length, 1);
      expect(
        receivers.first.getAttribute('android:name'),
        '.CustomBroadcastReceiver',
      );

      // 4. Verify extra activity is preserved
      final activities = doc.findAllElements('activity').toList();
      expect(
        activities.any(
          (a) => a.getAttribute('android:name') == '.SettingsActivity',
        ),
        isTrue,
      );

      // 5. Verify queries are preserved
      final queries = doc.findAllElements('queries').toList();
      expect(queries.length, 1);
      expect(
        queries.first
            .findAllElements('package')
            .first
            .getAttribute('android:name'),
        'com.google.android.apps.maps',
      );

      // 6. Verify chameleon aliases are present
      final aliases = doc.findAllElements('activity-alias').toList();
      expect(aliases.length, 3);
    });
  });
}
