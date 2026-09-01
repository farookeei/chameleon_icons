## 0.0.1

* Initial release of Chameleon Icons.
* Support for dynamic app launcher icon switching at runtime on Android (`<activity-alias>`) and iOS (`CFBundleAlternateIcons`).
* Added `changeIcon(String targetIconClassName)` to switch to an alternate app icon.
* Added `resetIcon()` to restore the primary default app icon.
* Added `getCurrentIcon()` to dynamically query the active launcher icon.
* Added `isAlternateIconsSupported()` to check device and OS platform capability.
* Interactive example application.
