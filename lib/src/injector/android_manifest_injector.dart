// ignore_for_file: avoid_print

import 'dart:io';

import 'package:xml/xml.dart';

import '../config/chameleon_config.dart';

/// Exception thrown when native manifest or plist injection fails.
class ChameleonInjectionException implements Exception {
  final String message;
  const ChameleonInjectionException(this.message);

  @override
  String toString() => 'ChameleonInjectionException: $message';
}

/// Injects and updates chameleon_icons configuration in AndroidManifest.xml safely and idempotently.
class AndroidManifestInjector {
  final ChameleonConfig config;
  final String projectRoot;

  static const startMarker = '<!-- [chameleon_icons:start] -->';
  static const endMarker = '<!-- [chameleon_icons:end] -->';
  static const defaultAliasMetadata =
      'com.farookjamal.chameleon_icons.DEFAULT_ICON_ALIAS';

  AndroidManifestInjector({required this.config, this.projectRoot = '.'});

  String get manifestPath =>
      '$projectRoot/android/app/src/main/AndroidManifest.xml';

  /// Performs safe, idempotent injection into AndroidManifest.xml.
  void inject() {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      throw ChameleonInjectionException(
        'AndroidManifest.xml not found at "$manifestPath". Make sure this is a Flutter project with Android support.',
      );
    }

    final originalContent = file.readAsStringSync();

    // 1. Pre-flight verification: verify valid XML structure
    XmlDocument document;
    try {
      document = XmlDocument.parse(originalContent);
    } catch (e) {
      throw ChameleonInjectionException(
        'Failed to parse $manifestPath: Invalid XML structure. $e',
      );
    }

    final applicationElement = document
        .findAllElements('application')
        .firstOrNull;
    if (applicationElement == null) {
      throw const ChameleonInjectionException(
        'Missing <application> element in AndroidManifest.xml.',
      );
    }

    // 2. Identify the main launcher Activity
    final activityElement = _findMainActivity(document);
    if (activityElement == null) {
      throw const ChameleonInjectionException(
        'Could not find the main launcher <activity> (or .MainActivity) in AndroidManifest.xml.',
      );
    }

    final targetActivityName =
        activityElement.getAttribute('android:name') ?? '.MainActivity';

    // 3. Transform content non-destructively
    String modifiedContent = originalContent;
    final managedBlock = _buildManagedBlock(targetActivityName);

    if (modifiedContent.contains(startMarker) &&
        modifiedContent.contains(endMarker)) {
      // In-place replacement of the existing managed block for perfect byte-for-byte idempotency
      final blockRegex = RegExp(
        RegExp.escape(startMarker) + r'[\s\S]*?' + RegExp.escape(endMarker),
        multiLine: true,
      );
      modifiedContent = modifiedContent.replaceFirst(
        blockRegex,
        managedBlock.trim(),
      );
    } else {
      // Clean up any un-anchored/manual legacy activity-aliases or metadata for these icons
      modifiedContent = _removeLegacyMatchingAliases(modifiedContent);

      // Remove the launcher intent-filter from MainActivity if still present
      modifiedContent = _removeLauncherIntentFilterFromMainActivity(
        modifiedContent,
        targetActivityName,
      );

      // Insert the managed block right after MainActivity's closing tag
      modifiedContent = _insertManagedBlock(
        modifiedContent,
        targetActivityName,
        managedBlock,
      );
    }

    // 4. Post-flight verification: ensure result is 100% valid XML before writing
    try {
      XmlDocument.parse(modifiedContent);
    } catch (e) {
      throw ChameleonInjectionException(
        'Generated AndroidManifest.xml resulted in invalid XML. Aborting without saving changes. $e',
      );
    }

    // 5. Atomic write via temporary file
    _writeAtomically(file, modifiedContent);
    print(
      '  ✓ [Android] Injected activity aliases and metadata into AndroidManifest.xml',
    );
  }

  /// Locates the primary launcher activity (or .MainActivity).
  XmlElement? _findMainActivity(XmlDocument document) {
    final activities = document.findAllElements('activity');
    for (final act in activities) {
      // Check if it has a launcher intent-filter
      for (final filter in act.findElements('intent-filter')) {
        for (final cat in filter.findElements('category')) {
          if (cat.getAttribute('android:name') ==
              'android.intent.category.LAUNCHER') {
            return act;
          }
        }
      }
    }

    // Fallback: search by name containing MainActivity
    return activities.where((act) {
      final name = act.getAttribute('android:name') ?? '';
      return name.endsWith('MainActivity');
    }).firstOrNull;
  }

  /// Removes legacy manual aliases or default metadata matching our configured names.
  String _removeLegacyMatchingAliases(String content) {
    String cleaned = content;

    // Remove legacy metadata
    final metadataRegex = RegExp(
      r'[ \t]*<meta-data[^>]*android:name="' +
          RegExp.escape(defaultAliasMetadata) +
          r'"[^>]*/>[ \t]*\n?',
    );
    cleaned = cleaned.replaceAll(metadataRegex, '');

    // Remove legacy aliases for configured icon names
    final allNames = config.allIcons.map((i) => i.name).toSet();
    for (final name in allNames) {
      final aliasRegex = RegExp(
        r'[ \t]*<activity-alias[^>]*android:name="(\.' +
            RegExp.escape(name) +
            r'|[^"]*' +
            RegExp.escape(name) +
            r')"[^>]*>[\s\S]*?</activity-alias>[ \t]*\n?',
        multiLine: true,
      );
      cleaned = cleaned.replaceAll(aliasRegex, '');
    }

    return cleaned;
  }

  /// Removes or comments out the launcher intent-filter inside the main activity.
  String _removeLauncherIntentFilterFromMainActivity(
    String content,
    String activityName,
  ) {
    final activityBlockRegex = RegExp(
      r'(<activity[^>]*android:name="' +
          RegExp.escape(activityName) +
          r'"[^>]*>)([\s\S]*?)(</activity>)',
      multiLine: true,
    );

    return content.replaceFirstMapped(activityBlockRegex, (match) {
      final openingTag = match.group(1)!;
      String inner = match.group(2)!;
      final closingTag = match.group(3)!;

      // Match intent-filter containing android.intent.category.LAUNCHER
      // Also handles case where the filter was already commented out
      final launcherFilterRegex = RegExp(
        r'[ \t]*(<!--\s*)?<intent-filter>[\s\S]*?android\.intent\.category\.LAUNCHER[\s\S]*?</intent-filter>(\s*-->)?[ \t]*\n?',
        multiLine: true,
      );

      inner = inner.replaceAll(launcherFilterRegex, '');
      // Clean up any empty comment tags left behind if comments were per-line
      inner = inner.replaceAll(
        RegExp(r'[ \t]*<!--\s*-->[ \t]*\n?', multiLine: true),
        '',
      );
      return '$openingTag$inner$closingTag';
    });
  }

  /// Builds the XML block containing the default metadata and all activity-aliases.
  String _buildManagedBlock(String targetActivity) {
    final buffer = StringBuffer();
    buffer.writeln('        $startMarker');
    buffer.writeln(
      '        <!-- Automatically generated by chameleon_icons. Do not modify manually. -->',
    );
    buffer.writeln('        <meta-data');
    buffer.writeln('            android:name="$defaultAliasMetadata"');
    buffer.writeln(
      '            android:value="${config.defaultIcon.name}" />\n',
    );

    // Default icon alias (enabled: true)
    buffer.writeln('        <activity-alias');
    buffer.writeln('            android:name=".${config.defaultIcon.name}"');
    buffer.writeln('            android:enabled="true"');
    buffer.writeln('            android:exported="true"');
    buffer.writeln(
      '            android:icon="@mipmap/${config.defaultIcon.androidDrawableName}"',
    );
    buffer.writeln('            android:targetActivity="$targetActivity">');
    buffer.writeln('            <intent-filter>');
    buffer.writeln(
      '                <action android:name="android.intent.action.MAIN" />',
    );
    buffer.writeln(
      '                <category android:name="android.intent.category.LAUNCHER" />',
    );
    buffer.writeln('            </intent-filter>');
    buffer.writeln('        </activity-alias>');

    // Alternate icon aliases (enabled: false)
    for (final alt in config.alternateIcons) {
      buffer.writeln('\n        <activity-alias');
      buffer.writeln('            android:name=".${alt.name}"');
      buffer.writeln('            android:enabled="false"');
      buffer.writeln('            android:exported="true"');
      buffer.writeln(
        '            android:icon="@mipmap/${alt.androidDrawableName}"',
      );
      buffer.writeln('            android:targetActivity="$targetActivity">');
      buffer.writeln('            <intent-filter>');
      buffer.writeln(
        '                <action android:name="android.intent.action.MAIN" />',
      );
      buffer.writeln(
        '                <category android:name="android.intent.category.LAUNCHER" />',
      );
      buffer.writeln('            </intent-filter>');
      buffer.writeln('        </activity-alias>');
    }

    buffer.write('        $endMarker');
    return buffer.toString();
  }

  /// Inserts the managed block right after MainActivity's closing tag `</activity>`.
  String _insertManagedBlock(
    String content,
    String activityName,
    String managedBlock,
  ) {
    final activityCloseRegex = RegExp(
      r'(<activity[^>]*android:name="' +
          RegExp.escape(activityName) +
          r'"[\s\S]*?</activity>)',
      multiLine: true,
    );

    if (activityCloseRegex.hasMatch(content)) {
      return content.replaceFirstMapped(activityCloseRegex, (match) {
        return '${match.group(1)}\n\n$managedBlock';
      });
    }

    // Fallback: insert before </application>
    return content.replaceFirst(
      '</application>',
      '\n$managedBlock\n    </application>',
    );
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
