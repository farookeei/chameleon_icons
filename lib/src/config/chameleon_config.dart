import 'dart:io';
import 'package:yaml/yaml.dart';

/// Exception thrown when the `chameleon_icons` configuration in pubspec.yaml is invalid.
class ChameleonConfigException implements Exception {
  final String message;
  const ChameleonConfigException(this.message);

  @override
  String toString() => 'ChameleonConfigException: $message';
}

/// Represents the configuration for a single icon (default or alternate).
class IconConfig {
  /// The config key (e.g. 'default', 'dark', 'gold').
  final String key;

  /// The Android alias / iOS alternate icon name (e.g. 'MainActivityDark').
  final String name;

  /// The path to the source master PNG image (e.g. 'assets/icons/dark.png').
  final String imagePath;

  /// Whether this represents the primary default app icon.
  final bool isDefault;

  const IconConfig({
    required this.key,
    required this.name,
    required this.imagePath,
    this.isDefault = false,
  });

  /// The base filename used in Android resources (e.g. 'ic_launcher' or 'ic_launcher_dark').
  String get androidDrawableName =>
      isDefault ? 'ic_launcher' : 'ic_launcher_${key.toLowerCase()}';

  /// The base filename used in iOS bundle resources (e.g. 'AppIcon' or 'dark_icon').
  String get iosAssetName =>
      isDefault ? 'AppIcon' : '${key.toLowerCase()}_icon';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconConfig &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          name == other.name &&
          imagePath == other.imagePath &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      key.hashCode ^ name.hashCode ^ imagePath.hashCode ^ isDefault.hashCode;

  @override
  String toString() =>
      'IconConfig(key: $key, name: $name, imagePath: $imagePath, isDefault: $isDefault)';
}

/// Holds the parsed configuration for Chameleon Icons from `pubspec.yaml`.
class ChameleonConfig {
  /// The primary default app icon.
  final IconConfig defaultIcon;

  /// The list of alternate icons.
  final List<IconConfig> alternateIcons;

  const ChameleonConfig({
    required this.defaultIcon,
    required this.alternateIcons,
  });

  /// All icons combined (default + alternates).
  List<IconConfig> get allIcons => [defaultIcon, ...alternateIcons];

  /// Loads and parses the configuration directly from a `pubspec.yaml` file.
  factory ChameleonConfig.loadFromPubspec([String pubspecPath = 'pubspec.yaml']) {
    final file = File(pubspecPath);
    if (!file.existsSync()) {
      throw ChameleonConfigException(
        'Could not find $pubspecPath at ${file.absolute.path}',
      );
    }

    final content = file.readAsStringSync();
    return ChameleonConfig.fromYaml(content);
  }

  /// Parses the configuration from raw YAML string content.
  factory ChameleonConfig.fromYaml(String yamlContent) {
    final dynamic yaml = loadYaml(yamlContent);

    if (yaml == null || yaml is! YamlMap) {
      throw const ChameleonConfigException('Invalid or empty pubspec.yaml file.');
    }

    final dynamic chameleonSection = yaml['chameleon_icons'];
    if (chameleonSection == null || chameleonSection is! YamlMap) {
      throw const ChameleonConfigException(
        'Missing "chameleon_icons:" configuration block in pubspec.yaml.',
      );
    }

    // 1. Parse default_icon
    final dynamic defaultSection = chameleonSection['default_icon'];
    if (defaultSection == null || defaultSection is! YamlMap) {
      throw const ChameleonConfigException(
        '"chameleon_icons.default_icon" is required in pubspec.yaml.',
      );
    }

    final String? defaultPath = defaultSection['image_path']?.toString();
    if (defaultPath == null || defaultPath.trim().isEmpty) {
      throw const ChameleonConfigException(
        '"chameleon_icons.default_icon.image_path" is required.',
      );
    }

    final String defaultName =
        defaultSection['name']?.toString() ?? 'MainActivityDefault';

    final defaultIcon = IconConfig(
      key: 'default',
      name: defaultName,
      imagePath: defaultPath.trim(),
      isDefault: true,
    );

    // 2. Parse alternate_icons
    final List<IconConfig> alternateIcons = [];
    final dynamic alternateSection = chameleonSection['alternate_icons'];

    if (alternateSection != null) {
      if (alternateSection is! YamlMap) {
        throw const ChameleonConfigException(
          '"chameleon_icons.alternate_icons" must be a map of icon definitions.',
        );
      }

      for (final entry in alternateSection.entries) {
        final key = entry.key.toString();
        final dynamic value = entry.value;

        if (value is! YamlMap) {
          throw ChameleonConfigException(
            'Invalid configuration for alternate icon "$key". Must be a map containing "image_path".',
          );
        }

        final String? imagePath = value['image_path']?.toString();
        if (imagePath == null || imagePath.trim().isEmpty) {
          throw ChameleonConfigException(
            'Missing "image_path" for alternate icon "$key".',
          );
        }

        // Auto-generate PascalCase name if not provided (e.g. 'dark' -> 'MainActivityDark')
        final String name = value['name']?.toString() ??
            'MainActivity${_capitalize(key)}';

        alternateIcons.add(
          IconConfig(
            key: key,
            name: name,
            imagePath: imagePath.trim(),
            isDefault: false,
          ),
        );
      }
    }

    return ChameleonConfig(
      defaultIcon: defaultIcon,
      alternateIcons: alternateIcons,
    );
  }

  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}
