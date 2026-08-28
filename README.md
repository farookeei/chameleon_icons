# Chameleon Icons

A cross-platform Flutter plugin and automated CLI tool to dynamically change app launcher icons at runtime on Android and iOS with zero manual native boilerplate.

---

## Overview

Dynamically changing app icons has traditionally been complex and error-prone:
* **Android:** Requires manual `<activity-alias>` declarations in `AndroidManifest.xml`, multi-density `mipmap` generation (mdpi to xxxhdpi), and complex `PackageManager` component-state manipulation.
* **iOS:** Requires manual configuration of nested `CFBundleAlternateIcons` dictionaries in `Info.plist`, retina `@2x` / `@3x` asset linking, and `UIApplication.setAlternateIconName` handling.

**Chameleon Icons solves both sides:**
1. **Unified Dart API:** A clean, idiomatic Flutter API (`changeIcon`, `resetIcon`, `getCurrentIconClassName`) that feels natural to Flutter developers.
2. **Automated CLI Engine:** Define your icons once in `pubspec.yaml`, run `dart run chameleon_icons:generate`, and let the CLI resize all densities and inject all Android XML and iOS Plist configurations automatically.

---

## Status and Roadmap

| Phase | Milestone | Status | Description |
| :--- | :--- | :---: | :--- |
| **Phase 1** | **Project Setup and Architecture** | Done | Modern Kotlin and Swift Package Manager (SwiftPM) setup with FVM. |
| **Phase 2** | **Native Proof of Concept** | Done | Verified native runtime switching on Android (Activity-Alias) and iOS (UIKit). |
| **Phase 3** | **Platform Interface and Dart API** | Done | Established clean public interface with decoupled `resetIcon()` and `changeIcon()`. |
| **Phase 4** | **CLI Image Processing Engine** | Next | Automate resizing source PNGs to all Android densities (`mipmap-*`) and iOS `@2x`/`@3x` assets. |
| **Phase 5** | **Automated Native Injection** | Planned | Automatic parsing and injection into `AndroidManifest.xml` and `Info.plist`. |
| **Phase 6** | **Type-Safe Code Generation** | Planned | Automatic generation of `app_icons.g.dart` with type-safe `enum` values. |
| **Phase 7** | **Pub.dev Release** | Planned | Comprehensive test coverage, documentation, and pub.dev publication. |

---

## Architecture and Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                       Developer Workflow                    │
│                                                             │
│   1. Add icon PNGs in assets/icons/                         │
│   2. Configure pubspec.yaml                                 │
│   3. Run: dart run chameleon_icons:generate                 │
└──────────────────────────────┬──────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
┌───────────────────────┐             ┌───────────────────────┐
│     Android Engine    │             │       iOS Engine      │
│ ├─ mipmap-mdpi..xxxhdpi│            │ ├─ @2x & @3x PNGs     │
│ ├─ <activity-alias>   │             │ ├─ CFBundleIcons      │
│ └─ PackageManager API │             │ └─ UIApplication API  │
└───────────────────────┘             └───────────────────────┘
```

---

## Configuration and Usage

### 1. Configure `pubspec.yaml`
```yaml
chameleon_icons:
  default_icon:
    image_path: "assets/icons/default.png"
  
  alternate_icons:
    dark:
      image_path: "assets/icons/dark.png"
    gold:
      image_path: "assets/icons/gold.png"
    premium:
      image_path: "assets/icons/premium.png"
```

### 2. Run the CLI Generator
```bash
dart run chameleon_icons:generate
```
This command will:
- Resize source PNGs to all native Android and iOS resolutions.
- Inject `<activity-alias>` entries into `android/app/src/main/AndroidManifest.xml`.
- Inject `CFBundleAlternateIcons` entries into `ios/Runner/Info.plist`.
- Generate type-safe Dart enums (`AppIcon.dark`, `AppIcon.gold`).

---

## Dart API Preview

```dart
import 'package:chameleon_icons/chameleon_icons.dart';

final chameleon = ChameleonIcons();

// 1. Switch to an alternate icon:
await chameleon.changeIcon("MainActivityDark");

// 2. Reset back to the primary default app icon:
await chameleon.resetIcon();

// 3. Retrieve the currently active icon:
final currentIcon = await chameleon.getCurrentIconClassName();
print("Current active icon: $currentIcon");
```

---

## Platform Comparison

| Feature | Android Implementation | iOS Implementation |
| :--- | :--- | :--- |
| **Switching Mechanism** | `<activity-alias>` with `PackageManager.setComponentEnabledSetting` | `UIApplication.shared.setAlternateIconName(_:)` |
| **Default Icon Reset** | Enables primary launcher alias and disables others | Passes `nil` to `setAlternateIconName(nil)` |
| **Asset Location** | `android/app/src/main/res/mipmap-*` | `ios/Runner/` bundle resources |
| **App Lifecycle Impact** | Android OS recreates task window when default alias changes | iOS updates icon in-place with system confirmation alert |
| **Min Supported OS** | Android SDK 24+ (Android 7.0+) | iOS 15.0+ |

---

## Testing and Development

### Run Example App:
```bash
cd example
flutter run
```

### Run Unit and Integration Tests:
```bash
# Android native unit tests:
./gradlew testDebugUnitTest

# Flutter integration tests:
flutter test integration_test/plugin_integration_test.dart -r expanded
```

---

## License
MIT License. Developed by Farook Jamal.
