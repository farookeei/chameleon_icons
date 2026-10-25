/// Represents a metadata model for an icon definition managed by Chameleon Icons.
///
/// Can represent either the primary default icon or an alternate icon.
class ChameleonIconDefinition {
  /// Unique key in configuration (e.g. 'default', 'dark', 'gold').
  final String key;

  /// The Android activity-alias / iOS alternate icon identifier (e.g. 'MainActivityDark').
  final String id;

  /// Human-friendly display label (e.g. 'Default', 'Dark', 'Gold').
  final String label;

  /// The original source image asset path (e.g. 'assets/icons/dark.png').
  final String assetPath;

  /// Whether this is the primary default app icon.
  final bool isDefault;

  const ChameleonIconDefinition({
    required this.key,
    required this.id,
    required this.label,
    required this.assetPath,
    this.isDefault = false,
  });

  /// Checks whether this icon definition matches the currently active icon name
  /// returned by [ChameleonIcons.getCurrentIcon].
  ///
  /// Seamlessly handles cross-platform default identifiers (e.g. `'MainActivityDefault'`,
  /// `'AppIcon'`, or empty string on iOS).
  bool matches(String? currentActiveIconName) {
    if (currentActiveIconName == null) return false;
    if (isDefault) {
      return currentActiveIconName == id ||
          currentActiveIconName == 'AppIcon' ||
          currentActiveIconName.isEmpty;
    }
    return currentActiveIconName == id;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChameleonIconDefinition &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          id == other.id &&
          label == other.label &&
          assetPath == other.assetPath &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      key.hashCode ^
      id.hashCode ^
      label.hashCode ^
      assetPath.hashCode ^
      isDefault.hashCode;

  @override
  String toString() =>
      'ChameleonIconDefinition(key: $key, id: $id, label: $label, assetPath: $assetPath, isDefault: $isDefault)';
}
