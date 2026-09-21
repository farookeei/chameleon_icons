// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../config/chameleon_config.dart';
import '../models/icon_density.dart';

/// Exception thrown when image processing fails.
class ChameleonImageException implements Exception {
  final String message;
  const ChameleonImageException(this.message);

  @override
  String toString() => 'ChameleonImageException: $message';
}

/// Handles decoding, resizing, and writing launcher icons for Android and iOS.
class ImageProcessor {
  final ChameleonConfig config;
  final String projectRoot;

  ImageProcessor({
    required this.config,
    this.projectRoot = '.',
  });

  /// Processes all configured icons (default and alternates) for Android and iOS.
  void process() {
    print('[chameleon_icons] Starting launcher icon generation...\n');

    final androidResDir = Directory('$projectRoot/android/app/src/main/res');
    final iosRunnerDir = Directory('$projectRoot/ios/Runner');

    final hasAndroid = androidResDir.existsSync();
    final hasIos = iosRunnerDir.existsSync();

    if (!hasAndroid && !hasIos) {
      throw const ChameleonImageException(
        'Neither Android (android/app/src/main/res) nor iOS (ios/Runner) directories found in project root.',
      );
    }

    for (final icon in config.allIcons) {
      _processIcon(icon, hasAndroid: hasAndroid, hasIos: hasIos);
    }

    print('\n✅ [chameleon_icons] Icon generation complete!');
  }

  void _processIcon(
    IconConfig icon, {
    required bool hasAndroid,
    required bool hasIos,
  }) {
    final imagePath = '$projectRoot/${icon.imagePath}';
    final file = File(imagePath);

    if (!file.existsSync()) {
      throw ChameleonImageException(
        'Image file for "${icon.key}" not found at: ${file.path}',
      );
    }

    final bytes = file.readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw ChameleonImageException(
        'Failed to decode image file at: ${file.path}. Please verify it is a valid PNG/JPEG/WEBP.',
      );
    }

    print('Processing icon "${icon.key}" from ${icon.imagePath} (${image.width}x${image.height}px)');

    if (hasAndroid) {
      _generateAndroidIcons(image, icon);
    }

    if (hasIos) {
      _generateIosIcons(image, icon);
    }
  }

  void _generateAndroidIcons(img.Image image, IconConfig icon) {
    final resDir = Directory('$projectRoot/android/app/src/main/res');

    for (final density in AndroidIconDensity.standardDensities) {
      final resized = img.copyResize(
        image,
        width: density.size,
        height: density.size,
        interpolation: img.Interpolation.cubic,
      );

      final targetDir = Directory('${resDir.path}/${density.folderName}');
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final targetFile = File('${targetDir.path}/${icon.androidDrawableName}.png');
      targetFile.writeAsBytesSync(img.encodePng(resized));

      print('  ✓ [Android] Generated: ${density.folderName}/${icon.androidDrawableName}.png (${density.size}x${density.size})');
    }
  }

  void _generateIosIcons(img.Image image, IconConfig icon) {
    if (icon.isDefault) {
      _generateIosDefaultAppIcon(image);
    } else {
      _generateIosLooseAlternateIcons(image, icon);
    }
  }

  /// Generates the primary app icon in Assets.xcassets/AppIcon.appiconset
  void _generateIosDefaultAppIcon(img.Image image) {
    final appIconSetDir = Directory(
      '$projectRoot/ios/Runner/Assets.xcassets/AppIcon.appiconset',
    );

    if (!appIconSetDir.existsSync()) {
      appIconSetDir.createSync(recursive: true);
    }

    // Standard 1024x1024 universal icon for iOS 14+
    final resized1024 = img.copyResize(
      image,
      width: 1024,
      height: 1024,
      interpolation: img.Interpolation.cubic,
    );

    const iconFileName = 'Icon-App-1024x1024@1x.png';
    final target1024 = File('${appIconSetDir.path}/$iconFileName');
    target1024.writeAsBytesSync(img.encodePng(resized1024));

    // Update Contents.json with universal asset reference
    final contentsFile = File('${appIconSetDir.path}/Contents.json');
    final contentsJson = {
      'images': [
        {
          'filename': iconFileName,
          'idiom': 'universal',
          'platform': 'ios',
          'size': '1024x1024',
        }
      ],
      'info': {
        'author': 'xcode',
        'version': 1,
      }
    };

    contentsFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(contentsJson),
    );

    print('  ✓ [iOS Default] Generated: AppIcon.appiconset/$iconFileName (1024x1024)');
  }

  /// Generates universal loose PNGs directly in ios/Runner/ for alternate icons
  void _generateIosLooseAlternateIcons(img.Image image, IconConfig icon) {
    final runnerDir = Directory('$projectRoot/ios/Runner');

    for (final res in IosIconResolution.standardResolutions) {
      final resized = img.copyResize(
        image,
        width: res.size,
        height: res.size,
        interpolation: img.Interpolation.cubic,
      );

      final fileName = '${icon.iosAssetName}${res.suffix}';
      final targetFile = File('${runnerDir.path}/$fileName');
      targetFile.writeAsBytesSync(img.encodePng(resized));

      print('  ✓ [iOS Alternate] Generated: Runner/$fileName (${res.size}x${res.size})');
    }
  }
}
