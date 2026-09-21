import 'dart:io';
import 'package:chameleon_icons/src/config/chameleon_config.dart';
import 'package:chameleon_icons/src/models/icon_density.dart';
import 'package:chameleon_icons/src/processor/image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageProcessor', () {
    late Directory tempDir;
    late File masterImageFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('chameleon_test_');

      // Create a dummy 512x512 PNG master icon
      final dummyImage = img.Image(width: 512, height: 512);
      img.fill(dummyImage, color: img.ColorRgba8(0, 128, 255, 255));
      final pngBytes = img.encodePng(dummyImage);

      final assetsDir = Directory('${tempDir.path}/assets/icons')..createSync(recursive: true);
      masterImageFile = File('${assetsDir.path}/master.png')..writeAsBytesSync(pngBytes);

      // Create Android res dirs
      Directory('${tempDir.path}/android/app/src/main/res').createSync(recursive: true);

      // Create iOS Runner and AppIcon dirs
      Directory('${tempDir.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset').createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates all expected Android and iOS density assets', () {
      final config = ChameleonConfig(
        defaultIcon: IconConfig(
          key: 'default',
          name: 'MainActivityDefault',
          imagePath: 'assets/icons/master.png',
          isDefault: true,
        ),
        alternateIcons: [
          IconConfig(
            key: 'dark',
            name: 'MainActivityDark',
            imagePath: 'assets/icons/master.png',
            isDefault: false,
          ),
        ],
      );

      final processor = ImageProcessor(
        config: config,
        projectRoot: tempDir.path,
      );

      processor.process();

      // Verify Android densities for default icon
      final androidRes = '${tempDir.path}/android/app/src/main/res';
      for (final density in AndroidIconDensity.standardDensities) {
        expect(
          File('$androidRes/${density.folderName}/ic_launcher.png').existsSync(),
          isTrue,
          reason: 'Missing default ${density.folderName}/ic_launcher.png',
        );
        expect(
          File('$androidRes/${density.folderName}/ic_launcher_dark.png').existsSync(),
          isTrue,
          reason: 'Missing alternate ${density.folderName}/ic_launcher_dark.png',
        );
      }

      // Verify iOS default icon
      expect(
        File('${tempDir.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png').existsSync(),
        isTrue,
      );
      expect(
        File('${tempDir.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json').existsSync(),
        isTrue,
      );

      // Verify iOS alternate loose icons
      final runnerDir = '${tempDir.path}/ios/Runner';
      expect(File('$runnerDir/dark_icon@2x.png').existsSync(), isTrue);
      expect(File('$runnerDir/dark_icon@3x.png').existsSync(), isTrue);
      expect(File('$runnerDir/dark_icon~ipad@2x.png').existsSync(), isTrue);
      expect(File('$runnerDir/dark_icon~ipad-pro@2x.png').existsSync(), isTrue);
    });

    test('throws ChameleonImageException when master image does not exist', () {
      final config = ChameleonConfig(
        defaultIcon: const IconConfig(
          key: 'default',
          name: 'MainActivityDefault',
          imagePath: 'non_existent_file.png',
          isDefault: true,
        ),
        alternateIcons: const [],
      );

      final processor = ImageProcessor(
        config: config,
        projectRoot: tempDir.path,
      );

      expect(
        () => processor.process(),
        throwsA(isA<ChameleonImageException>()),
      );
    });

    test('throws ChameleonImageException when no platform directories exist', () {
      final emptyDir = Directory.systemTemp.createTempSync('empty_dir_');
      try {
        final config = ChameleonConfig(
          defaultIcon: IconConfig(
            key: 'default',
            name: 'MainActivityDefault',
            imagePath: masterImageFile.path,
            isDefault: true,
          ),
          alternateIcons: const [],
        );

        final processor = ImageProcessor(
          config: config,
          projectRoot: emptyDir.path,
        );

        expect(
          () => processor.process(),
          throwsA(isA<ChameleonImageException>()),
        );
      } finally {
        emptyDir.deleteSync(recursive: true);
      }
    });
  });
}
