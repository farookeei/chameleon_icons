import 'dart:io';

import 'package:chameleon_icons/chameleon_icons.dart';
import 'package:chameleon_icons/src/config/chameleon_config.dart';
import 'package:chameleon_icons/src/generator/dart_code_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartCodeGenerator', () {
    late Directory tempDir;
    late ChameleonConfig sampleConfig;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'chameleon_generator_test_',
      );

      sampleConfig = const ChameleonConfig(
        defaultIcon: IconConfig(
          key: 'default',
          name: 'MainActivityDefault',
          imagePath: 'assets/icons/default.png',
          isDefault: true,
        ),
        alternateIcons: [
          IconConfig(
            key: 'dark',
            name: 'MainActivityDark',
            imagePath: 'assets/icons/dark.png',
            isDefault: false,
          ),
          IconConfig(
            key: 'luxury_gold',
            name: 'MainActivityGold',
            imagePath: 'assets/icons/gold.png',
            isDefault: false,
          ),
        ],
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'generateCode produces valid Dart code containing typed definitions',
      () {
        final generator = DartCodeGenerator(
          config: sampleConfig,
          projectRoot: tempDir.path,
        );

        final code = generator.generateCode();

        expect(code, contains('class ChameleonGeneratedIcons'));
        expect(
          code,
          contains('static const defaultIcon = ChameleonIconDefinition('),
        );
        expect(code, contains("key: 'default'"));
        expect(code, contains("id: 'MainActivityDefault'"));
        expect(code, contains("label: 'Default'"));
        expect(code, contains("assetPath: 'assets/icons/default.png'"));
        expect(code, contains('isDefault: true'));

        expect(code, contains('static const dark = ChameleonIconDefinition('));
        expect(code, contains("key: 'dark'"));
        expect(code, contains("id: 'MainActivityDark'"));
        expect(code, contains("label: 'Dark'"));
        expect(code, contains("assetPath: 'assets/icons/dark.png'"));

        expect(
          code,
          contains('static const luxuryGold = ChameleonIconDefinition('),
        );
        expect(code, contains("key: 'luxury_gold'"));
        expect(code, contains("id: 'MainActivityGold'"));
        expect(code, contains("label: 'Luxury Gold'"));
        expect(code, contains("assetPath: 'assets/icons/gold.png'"));

        expect(
          code,
          contains(
            'static const List<ChameleonIconDefinition> alternateIcons = [',
          ),
        );
        expect(code, contains('dark,'));
        expect(code, contains('luxuryGold,'));

        expect(
          code,
          contains('static const List<ChameleonIconDefinition> all = ['),
        );
        expect(code, contains('defaultIcon,'));
      },
    );

    test('generate writes output file to designated path', () {
      final generator = DartCodeGenerator(
        config: sampleConfig,
        projectRoot: tempDir.path,
        outputPath: 'lib/chameleon_icons.g.dart',
      );

      final file = generator.generate();

      expect(file.existsSync(), isTrue);
      expect(
        file.readAsStringSync(),
        contains('class ChameleonGeneratedIcons'),
      );
      expect(file.path, equals('${tempDir.path}/lib/chameleon_icons.g.dart'));
    });

    test('ChameleonIconDefinition matches correctly handles default and alternate icons', () {
      const defaultIcon = ChameleonIconDefinition(
        key: 'default',
        id: 'MainActivityDefault',
        label: 'Default',
        assetPath: 'assets/default.png',
        isDefault: true,
      );

      const altIcon = ChameleonIconDefinition(
        key: 'dark',
        id: 'MainActivityDark',
        label: 'Dark',
        assetPath: 'assets/dark.png',
        isDefault: false,
      );

      // Default icon matches on Android ID, iOS AppIcon, or empty string
      expect(defaultIcon.matches('MainActivityDefault'), isTrue);
      expect(defaultIcon.matches('AppIcon'), isTrue);
      expect(defaultIcon.matches(''), isTrue);
      expect(defaultIcon.matches('MainActivityDark'), isFalse);
      expect(defaultIcon.matches(null), isFalse);

      // Alternate icon matches only its specific ID
      expect(altIcon.matches('MainActivityDark'), isTrue);
      expect(altIcon.matches('MainActivityDefault'), isFalse);
      expect(altIcon.matches('AppIcon'), isFalse);
      expect(altIcon.matches(''), isFalse);
    });
  });
}
