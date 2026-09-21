/// Data models representing density specifications for Android and iOS launcher icons.
library;

/// Represents an Android launcher icon density tier (e.g. mdpi, hdpi, xxhdpi).
class AndroidIconDensity {
  /// The target mipmap folder name (e.g. `'mipmap-hdpi'`).
  final String folderName;

  /// The icon width and height in pixels.
  final int size;

  const AndroidIconDensity({
    required this.folderName,
    required this.size,
  });

  /// Standard Android launcher icon density specifications.
  static const List<AndroidIconDensity> standardDensities = [
    AndroidIconDensity(folderName: 'mipmap-mdpi', size: 48),
    AndroidIconDensity(folderName: 'mipmap-hdpi', size: 72),
    AndroidIconDensity(folderName: 'mipmap-xhdpi', size: 96),
    AndroidIconDensity(folderName: 'mipmap-xxhdpi', size: 144),
    AndroidIconDensity(folderName: 'mipmap-xxxhdpi', size: 192),
  ];
}

/// Represents an iOS loose alternate icon resolution specification.
class IosIconResolution {
  /// The file suffix appended to the base icon name (e.g. `'@2x.png'`).
  final String suffix;

  /// The icon width and height in pixels.
  final int size;

  const IosIconResolution({
    required this.suffix,
    required this.size,
  });

  /// Standard iOS loose alternate icon resolutions.
  static const List<IosIconResolution> standardResolutions = [
    IosIconResolution(suffix: '@2x.png', size: 120),
    IosIconResolution(suffix: '@3x.png', size: 180),
    IosIconResolution(suffix: '~ipad@2x.png', size: 152),
    IosIconResolution(suffix: '~ipad-pro@2x.png', size: 167),
  ];
}
