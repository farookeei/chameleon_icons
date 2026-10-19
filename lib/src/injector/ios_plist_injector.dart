// ignore_for_file: avoid_print

import 'dart:io';

import 'package:xml/xml.dart';

import '../config/chameleon_config.dart';
import 'android_manifest_injector.dart';

/// Injects and updates chameleon_icons configuration in ios/Runner/Info.plist safely and idempotently.
class IosPlistInjector {
  final ChameleonConfig config;
  final String projectRoot;

  IosPlistInjector({required this.config, this.projectRoot = '.'});

  String get plistPath => '$projectRoot/ios/Runner/Info.plist';

  /// Performs safe, idempotent injection into Info.plist.
  void inject() {
    final file = File(plistPath);
    if (!file.existsSync()) {
      throw ChameleonInjectionException(
        'Info.plist not found at "$plistPath". Make sure this is a Flutter project with iOS support.',
      );
    }

    final originalContent = file.readAsStringSync();

    // 1. Pre-flight verification: verify valid XML structure
    XmlDocument document;
    try {
      document = XmlDocument.parse(originalContent);
    } catch (e) {
      throw ChameleonInjectionException(
        'Failed to parse $plistPath: Invalid XML/Plist structure. $e',
      );
    }

    final plistElement = document.findAllElements('plist').firstOrNull;
    final rootDict = plistElement?.findElements('dict').firstOrNull;
    if (rootDict == null) {
      throw const ChameleonInjectionException(
        'Missing root <dict> inside <plist> in Info.plist.',
      );
    }

    // 2. Build the new CFBundleIcons and CFBundleIcons~ipad blocks
    final iconsBlock = _buildIconsBlock(keyName: 'CFBundleIcons');
    final ipadIconsBlock = _buildIconsBlock(keyName: 'CFBundleIcons~ipad');

    String modifiedContent = originalContent;

    // A. Replace or insert CFBundleIcons
    modifiedContent = _injectOrReplaceDictEntry(
      modifiedContent,
      'CFBundleIcons',
      iconsBlock,
    );

    // B. Replace or insert CFBundleIcons~ipad
    modifiedContent = _injectOrReplaceDictEntry(
      modifiedContent,
      'CFBundleIcons~ipad',
      ipadIconsBlock,
    );

    // 3. Post-flight verification: ensure result is 100% valid XML before writing
    try {
      XmlDocument.parse(modifiedContent);
    } catch (e) {
      throw ChameleonInjectionException(
        'Generated Info.plist resulted in invalid XML. Aborting without saving changes. $e',
      );
    }

    // 4. Atomic write via temporary file
    _writeAtomically(file, modifiedContent);
    print(
      '  ✓ [iOS] Injected CFBundleIcons & CFBundleIcons~ipad into Info.plist',
    );
  }

  /// Builds a complete `<key>CFBundleIcons</key><dict>...</dict>` block.
  String _buildIconsBlock({required String keyName}) {
    final buffer = StringBuffer();
    buffer.writeln('\t<key>$keyName</key>');
    buffer.writeln('\t<dict>');

    // Primary default icon
    buffer.writeln('\t\t<key>CFBundlePrimaryIcon</key>');
    buffer.writeln('\t\t<dict>');
    buffer.writeln('\t\t\t<key>CFBundleIconFiles</key>');
    buffer.writeln('\t\t\t<array>');
    buffer.writeln(
      '\t\t\t\t<string>${config.defaultIcon.iosAssetName}</string>',
    );
    buffer.writeln('\t\t\t</array>');
    buffer.writeln('\t\t\t<key>UIPrerenderedIcon</key>');
    buffer.writeln('\t\t\t<false/>');
    buffer.writeln('\t\t</dict>');

    // Alternate icons
    buffer.writeln('\t\t<key>CFBundleAlternateIcons</key>');
    buffer.writeln('\t\t<dict>');
    for (final alt in config.alternateIcons) {
      buffer.writeln('\t\t\t<key>${alt.name}</key>');
      buffer.writeln('\t\t\t<dict>');
      buffer.writeln('\t\t\t\t<key>CFBundleIconFiles</key>');
      buffer.writeln('\t\t\t\t<array>');
      buffer.writeln('\t\t\t\t\t<string>${alt.iosAssetName}</string>');
      buffer.writeln('\t\t\t\t</array>');
      buffer.writeln('\t\t\t\t<key>UIPrerenderedIcon</key>');
      buffer.writeln('\t\t\t\t<false/>');
      buffer.writeln('\t\t\t</dict>');
    }
    buffer.writeln('\t\t</dict>');

    buffer.write('\t</dict>');
    return buffer.toString();
  }

  /// In-place replacement or insertion of a nested dictionary entry under root `<dict>`.
  String _injectOrReplaceDictEntry(
    String content,
    String targetKey,
    String newBlock,
  ) {
    final keyPattern = '<key>$targetKey</key>';
    final keyIndex = content.indexOf(keyPattern);

    if (keyIndex != -1) {
      // Find the start of the key line (including leading whitespace)
      int lineStart = content.lastIndexOf('\n', keyIndex);
      lineStart = (lineStart == -1) ? 0 : lineStart + 1;

      // Find the associated <dict> after the key
      final dictOpenIndex = content.indexOf(
        '<dict',
        keyIndex + keyPattern.length,
      );
      if (dictOpenIndex != -1) {
        // Track depth to find the matching closing </dict>
        final dictCloseEnd = _findMatchingDictClose(content, dictOpenIndex);
        if (dictCloseEnd != -1) {
          final before = content.substring(0, lineStart);
          final after = content.substring(dictCloseEnd);
          return '$before$newBlock$after';
        }
      }
    }

    // If key not present: insert directly after the root <plist><dict>
    final rootDictIndex = content.indexOf('<dict>');
    if (rootDictIndex != -1) {
      final insertIndex = rootDictIndex + '<dict>'.length;
      final before = content.substring(0, insertIndex);
      final after = content.substring(insertIndex);
      return '$before\n$newBlock$after';
    }

    throw const ChameleonInjectionException(
      'Could not locate root <dict> in Info.plist',
    );
  }

  /// Finds the end index of the matching closing `</dict>` tag by counting depth.
  int _findMatchingDictClose(String content, int startIndex) {
    int depth = 0;
    int currentIndex = startIndex;

    while (currentIndex < content.length) {
      final nextOpen = content.indexOf('<dict', currentIndex);
      final nextClose = content.indexOf('</dict>', currentIndex);

      if (nextClose == -1) {
        return -1; // Unbalanced XML
      }

      if (nextOpen != -1 && nextOpen < nextClose) {
        // Found opening <dict>
        depth++;
        currentIndex = content.indexOf('>', nextOpen) + 1;
      } else {
        // Found closing </dict>
        depth--;
        currentIndex = nextClose + '</dict>'.length;
        if (depth == 0) {
          return currentIndex;
        }
      }
    }

    return -1;
  }

  /// Atomically writes content to file using a temporary file and rename.
  void _writeAtomically(File targetFile, String content) {
    final tempFile = File('${targetFile.path}.chameleon_tmp');
    try {
      tempFile.writeAsStringSync(content);
      tempFile.renameSync(targetFile.path);
    } catch (e) {
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
