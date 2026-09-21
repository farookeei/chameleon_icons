import 'package:chameleon_icons/src/config/chameleon_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChameleonConfig', () {
    test('parses minimal valid configuration with default fallbacks', () {
      const yaml = '''
chameleon_icons:
  default_icon:
    image_path: "assets/icons/default.png"
  alternate_icons:
    dark:
      image_path: "assets/icons/dark.png"
    gold:
      image_path: "assets/icons/gold.png"
''';

      final config = ChameleonConfig.fromYaml(yaml);

      expect(config.defaultIcon.key, 'default');
      expect(config.defaultIcon.name, 'MainActivityDefault');
      expect(config.defaultIcon.imagePath, 'assets/icons/default.png');
      expect(config.defaultIcon.isDefault, true);
      expect(config.defaultIcon.androidDrawableName, 'ic_launcher');
      expect(config.defaultIcon.iosAssetName, 'AppIcon');

      expect(config.alternateIcons.length, 2);

      final darkIcon = config.alternateIcons[0];
      expect(darkIcon.key, 'dark');
      expect(darkIcon.name, 'MainActivityDark');
      expect(darkIcon.imagePath, 'assets/icons/dark.png');
      expect(darkIcon.isDefault, false);
      expect(darkIcon.androidDrawableName, 'ic_launcher_dark');
      expect(darkIcon.iosAssetName, 'dark_icon');

      final goldIcon = config.alternateIcons[1];
      expect(goldIcon.key, 'gold');
      expect(goldIcon.name, 'MainActivityGold');
      expect(goldIcon.imagePath, 'assets/icons/gold.png');
      expect(goldIcon.androidDrawableName, 'ic_launcher_gold');
      expect(goldIcon.iosAssetName, 'gold_icon');

      expect(config.allIcons.length, 3);
    });

    test('parses custom explicit names when specified', () {
      const yaml = '''
chameleon_icons:
  default_icon:
    name: "CustomDefault"
    image_path: "assets/icons/default.png"
  alternate_icons:
    midnight:
      name: "CustomMidnight"
      image_path: "assets/icons/midnight.png"
''';

      final config = ChameleonConfig.fromYaml(yaml);
      expect(config.defaultIcon.name, 'CustomDefault');
      expect(config.alternateIcons[0].name, 'CustomMidnight');
      expect(
        config.alternateIcons[0].androidDrawableName,
        'ic_launcher_midnight',
      );
      expect(config.alternateIcons[0].iosAssetName, 'midnight_icon');
    });

    test(
      'throws ChameleonConfigException when chameleon_icons block is missing',
      () {
        const yaml = '''
name: my_app
dependencies:
  flutter:
    sdk: flutter
''';

        expect(
          () => ChameleonConfig.fromYaml(yaml),
          throwsA(isA<ChameleonConfigException>()),
        );
      },
    );

    test('throws ChameleonConfigException when default_icon is missing', () {
      const yaml = '''
chameleon_icons:
  alternate_icons:
    dark:
      image_path: "assets/icons/dark.png"
''';

      expect(
        () => ChameleonConfig.fromYaml(yaml),
        throwsA(isA<ChameleonConfigException>()),
      );
    });

    test('throws ChameleonConfigException when alternate icon is missing image_path', () {
      const yaml = '''
chameleon_icons:
  default_icon:
    image_path: "assets/icons/default.png"
  alternate_icons:
    dark:
      name: "MainActivityDark"
''';

      expect(
        () => ChameleonConfig.fromYaml(yaml),
        throwsA(isA<ChameleonConfigException>()),
      );
    });
  });
}
