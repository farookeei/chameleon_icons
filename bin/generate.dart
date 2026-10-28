// ignore_for_file: avoid_print

/// The CLI generator executable for Chameleon Icons.
///
/// Run via:
/// ```bash
/// dart run chameleon_icons:generate
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:chameleon_icons/src/config/chameleon_config.dart';
import 'package:chameleon_icons/src/generator/dart_code_generator.dart';
import 'package:chameleon_icons/src/injector/android_manifest_injector.dart';
import 'package:chameleon_icons/src/injector/ios_plist_injector.dart';
import 'package:chameleon_icons/src/processor/image_processor.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      defaultsTo: 'pubspec.yaml',
      help: 'Path to the pubspec.yaml file containing chameleon_icons configuration.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display this help message.',
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Chameleon Icons Generator CLI\n');
      print('Usage: dart run chameleon_icons:generate [options]\n');
      print(parser.usage);
      exit(0);
    }

    final pubspecPath = results['path'] as String;
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      stderr.writeln('❌ Error: pubspec.yaml not found at "$pubspecPath"');
      exit(1);
    }

    // Determine project root directory from pubspec location
    final projectRoot = pubspecFile.parent.path.isEmpty
        ? '.'
        : pubspecFile.parent.path;

    print('Reading configuration from $pubspecPath...');
    final config = ChameleonConfig.loadFromPubspec(pubspecPath);

    print('Found ${config.allIcons.length} icon definitions:');
    print(
      '  - Default: ${config.defaultIcon.key} (${config.defaultIcon.imagePath})',
    );
    for (final alt in config.alternateIcons) {
      print('  - Alternate: ${alt.key} (${alt.imagePath}) -> ${alt.name}');
    }
    print('');

    // 1. Process and generate image densities for Android and iOS
    final processor = ImageProcessor(config: config, projectRoot: projectRoot);
    processor.process();

    // 2. Inject AndroidManifest.xml configuration (if Android exists)
    final androidManifestFile = File(
      '$projectRoot/android/app/src/main/AndroidManifest.xml',
    );
    if (androidManifestFile.existsSync()) {
      final androidInjector = AndroidManifestInjector(
        config: config,
        projectRoot: projectRoot,
      );
      androidInjector.inject();
    }

    // 3. Inject Info.plist configuration (if iOS exists)
    final iosPlistFile = File('$projectRoot/ios/Runner/Info.plist');
    if (iosPlistFile.existsSync()) {
      final iosInjector = IosPlistInjector(
        config: config,
        projectRoot: projectRoot,
      );
      iosInjector.inject();
    }

    // 4. Generate typed Dart code (lib/chameleon_icons.g.dart)
    final dartGen = DartCodeGenerator(config: config, projectRoot: projectRoot);
    final generatedFile = dartGen.generate();
    print('  ✓ [Dart] Generated typed icons: ${generatedFile.path}');

    print(
      '\n [chameleon_icons] Full setup complete! All images generated, native configs injected, and Dart code generated.',
    );
  } on FormatException catch (e) {
    stderr.writeln('❌ Invalid CLI argument: ${e.message}');
    stderr.writeln(parser.usage);
    exit(1);
  } on ChameleonConfigException catch (e) {
    stderr.writeln('❌ Configuration Error: ${e.message}');
    exit(1);
  } on ChameleonImageException catch (e) {
    stderr.writeln('❌ Image Processing Error: ${e.message}');
    exit(1);
  } on ChameleonInjectionException catch (e) {
    stderr.writeln('❌ Native Injection Error: ${e.message}');
    exit(1);
  } on ChameleonGeneratorException catch (e) {
    stderr.writeln('❌ Code Generation Error: ${e.message}');
    exit(1);
  } catch (e, st) {
    stderr.writeln('❌ Unexpected error: $e');
    stderr.writeln(st);
    exit(1);
  }
}
