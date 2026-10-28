## 0.2.0

* **Type-Safe Icon Generation (`chameleon_icons.g.dart`)**:
  * Running `dart run chameleon_icons:generate` now automatically outputs `lib/chameleon_icons.g.dart` containing strongly-typed `ChameleonGeneratedIcons` (`defaultIcon`, individual alternates, `alternateIcons`, and `all`).
  * Added `ChameleonIconDefinition` model encapsulating `key`, `id`, `label`, `assetPath`, and `isDefault`.
  * Added `ChameleonIconDefinition.matches(activeIconName)` to cleanly resolve cross-platform active icon identifiers (Android alias, iOS `AppIcon`, or empty defaults) without hardcoding strings in UI.
* **Declarative & Reactive State Management**:
  * Added `ChameleonIcons.activeIconNotifier`: a `ValueNotifier<ChameleonIconDefinition?>` that can be directly bound to Flutter's `ValueListenableBuilder`.
  * Added `setIcon(ChameleonIconDefinition icon)` to switch or reset the icon and immediately synchronize `activeIconNotifier`.
  * Added `getActiveIcon(List<ChameleonIconDefinition> icons)` and `initialize(icons)` to resolve and broadcast the active icon without manual `initState` boilerplate.
  * Added `isDefaultIcon()` convenience check.
* **Android Manifest Launcher Resolution Fix**:
  * Resolved `package identifier or launch activity not found` during clean `flutter run` invocations caused by Flutter tooling ignoring `<activity-alias>` when inspecting source manifests before an APK is built.
  * The injector now adds `xmlns:tools` to `<manifest>` and injects a `tools:node="remove"` launcher `<intent-filter>` on `.MainActivity` so Flutter tools detect the launch activity while the Android Gradle manifest merger cleanly strips it from the final APK.
* **Refactored Example App**:
  * Migrated the example app to consume `ChameleonGeneratedIcons.all` and `activeIconNotifier` with a clean, zero-boilerplate Telegram-style icon picker.

## 0.1.0

* **Automated CLI Generator (`dart run chameleon_icons:generate`)**:
  * Added configuration schema parser for `pubspec.yaml` (`chameleon_icons:` block) and custom config paths via `--path`.
  * **Multi-density Image Processor**: Automatically decodes and generates all required Android launcher densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) and iOS retina densities (`@2x`, `@3x`, `~ipad@2x`, `~ipad-pro@2x`, and `AppIcon.appiconset`).
  * **Automated Android Manifest Injection**:
    * Safely removes the launcher `<intent-filter>` from the primary activity.
    * Automatically injects default metadata and `<activity-alias>` tags for all configured icons.
    * Uses anchor comments (`<!-- [chameleon_icons:start] -->`) for byte-for-byte idempotency on repeated runs.
  * **Automated iOS Plist Injection**:
    * Parses and injects nested `CFBundleIcons` and `CFBundleIcons~ipad` dictionaries in `Info.plist`.
    * Depth-balanced dictionary replacement preserving all user keys and formatting.
  * **Safe Atomic File Operations**: Built with atomic temporary write and rename semantics (`.tmp` + `renameSync`) to eliminate risk of native file corruption.

## 0.0.1

* Initial release of Chameleon Icons.
* Support for dynamic app launcher icon switching at runtime on Android (`<activity-alias>`) and iOS (`CFBundleAlternateIcons`).
* Added `changeIcon(String targetIconClassName)` to switch to an alternate app icon.
* Added `resetIcon()` to restore the primary default app icon.
* Added `getCurrentIcon()` to dynamically query the active launcher icon.
* Added `isAlternateIconsSupported()` to check device and OS platform capability.
* Interactive example application.
