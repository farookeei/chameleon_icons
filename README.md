# Chameleon Icons

[![CI](https://github.com/farookeei/chameleon_icons/actions/workflows/ci.yaml/badge.svg)](https://github.com/farookeei/chameleon_icons/actions/workflows/ci.yaml)
[![Pub Version](https://img.shields.io/pub/v/chameleon_icons?color=blue)](https://pub.dev/packages/chameleon_icons)
[![Pub Points](https://img.shields.io/pub/points/chameleon_icons)](https://pub.dev/packages/chameleon_icons)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A cross-platform Flutter plugin and automated CLI tool to dynamically change app launcher icons at runtime on Android and iOS with zero manual native boilerplate.

---

## Overview

Dynamically changing app icons has traditionally been complex and error-prone:
* **Android:** Requires manual `<activity-alias>` declarations in `AndroidManifest.xml`, multi-density `mipmap` generation (`mdpi` to `xxxhdpi`), and complex `PackageManager` component-state manipulation.
* **iOS:** Requires manual configuration of nested `CFBundleAlternateIcons` dictionaries in `Info.plist`, retina `@2x` / `@3x` asset linking, and `UIApplication.setAlternateIconName` handling.

**Chameleon Icons solves both sides:**
1. **Unified Dart API:** A clean, idiomatic Flutter API (`changeIcon`, `resetIcon`, `getCurrentIcon`, `isAlternateIconsSupported`) that feels natural to Flutter developers.
2. **Automated CLI Engine (Coming in v0.1.0):** Define icons once in `pubspec.yaml`, run `dart run chameleon_icons:generate`, and let the CLI resize all densities and inject all Android XML and iOS Plist configurations automatically.

---

## Platform Support

| Platform | Supported | Switching Engine |
| :--- | :---: | :--- |
| **Android** | **Yes** (API 24+) | `PackageManager.setComponentEnabledSetting` via `<activity-alias>` |
| **iOS** | **Yes** (iOS 15.0+) | `UIApplication.shared.setAlternateIconName(_:)` via `CFBundleAlternateIcons` |

---

## Installation

Add `chameleon_icons` to your `pubspec.yaml`:

```yaml
dependencies:
  chameleon_icons: ^0.0.1
```

Then run:
```bash
flutter pub get
```

---

## Platform Setup (v0.0.1 Manual Setup)

> **Note:** In version **0.1.0**, this setup will be 100% automated using `dart run chameleon_icons:generate`. For version `0.0.1`, follow the manual setup below.

---

### 1. Android Configuration

Open `android/app/src/main/AndroidManifest.xml` and make the following adjustments:

#### Step A: Remove the launcher intent filter from `<activity android:name=".MainActivity">`
Comment out or remove the `<intent-filter>` from your main activity so it is not launched directly without an alias:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <meta-data
        android:name="io.flutter.embedding.android.NormalTheme"
        android:resource="@style/NormalTheme" />
    
    <!-- REMOVE or COMMENT OUT the launcher intent-filter from MainActivity:
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    -->
</activity>
```

#### Step B: Declare the default icon metadata
Inside the `<application>` tag, declare the name of your primary default alias:

```xml
<application ...>

    <!-- Required: Tells ChameleonIcons which alias represents the default icon -->
    <meta-data
        android:name="com.farookjamal.chameleon_icons.DEFAULT_ICON_ALIAS"
        android:value="MainActivityDefault" />

    <!-- ... activities ... -->
```

#### Step C: Add `<activity-alias>` for Default and Alternate Icons
Directly below `<activity android:name=".MainActivity">`, define an `<activity-alias>` for each icon:

```xml
    <!-- Primary Default Icon (Must have android:enabled="true") -->
    <activity-alias
        android:name=".MainActivityDefault"
        android:enabled="true"
        android:exported="true"
        android:icon="@mipmap/ic_launcher"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
    </activity-alias>

    <!-- Alternate Icon 1: Dark (Must have android:enabled="false") -->
    <activity-alias
        android:name=".MainActivityDark"
        android:enabled="false"
        android:exported="true"
        android:icon="@mipmap/ic_launcher_dark"
        android:roundIcon="@mipmap/ic_launcher_dark_round"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
    </activity-alias>

    <!-- Alternate Icon 2: Gold (Must have android:enabled="false") -->
    <activity-alias
        android:name=".MainActivityGold"
        android:enabled="false"
        android:exported="true"
        android:icon="@mipmap/ic_launcher_gold"
        android:roundIcon="@mipmap/ic_launcher_gold_round"
        android:targetActivity=".MainActivity">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
    </activity-alias>

</application>
```

---

### 2. iOS Configuration

#### Step A: Add PNG Assets to your iOS App Bundle
Add your alternate icon PNG files inside `ios/Runner/` at `@2x` (120×120 px) and `@3x` (180×180 px) resolutions:
* `ios/Runner/dark_icon@2x.png`
* `ios/Runner/dark_icon@3x.png`
* `ios/Runner/gold_icon@2x.png`
* `ios/Runner/gold_icon@3x.png`

> **Important:** In Xcode, ensure these image files are checked under **Target Membership -> Runner**.

#### Step B: Configure `Info.plist`
Open `ios/Runner/Info.plist` and add the `CFBundleIcons` dictionary under the root `<dict>` tag:

```xml
<key>CFBundleIcons</key>
<dict>
    <!-- Alternate Icons Configuration -->
    <key>CFBundleAlternateIcons</key>
    <dict>
        <key>MainActivityDark</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>dark_icon</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
        <key>MainActivityGold</key>
        <dict>
            <key>CFBundleIconFiles</key>
            <array>
                <string>gold_icon</string>
            </array>
            <key>UIPrerenderedIcon</key>
            <false/>
        </dict>
    </dict>
    <!-- Primary Default Icon Configuration -->
    <key>CFBundlePrimaryIcon</key>
    <dict>
        <key>CFBundleIconFiles</key>
        <array>
            <string>AppIcon</string>
        </array>
    </dict>
</dict>
```

---

## Dart API Usage

```dart
import 'package:flutter/material.dart';
import 'package:chameleon_icons/chameleon_icons.dart';

final chameleon = ChameleonIcons();

// 1. Check if alternate icons are supported on the device:
final isSupported = await chameleon.isAlternateIconsSupported();
if (isSupported) {
  // 2. Switch to an alternate icon:
  await chameleon.changeIcon("MainActivityDark");

  // 3. Query the currently active icon:
  final currentIcon = await chameleon.getCurrentIcon();
  print("Active icon: $currentIcon"); // Outputs: "MainActivityDark"

  // 4. Reset back to the primary default app icon:
  await chameleon.resetIcon();
}
```

---

## Platform Comparison

| Feature | Android Implementation | iOS Implementation |
| :--- | :--- | :--- |
| **Switching Mechanism** | `<activity-alias>` with `PackageManager.setComponentEnabledSetting` | `UIApplication.shared.setAlternateIconName(_:)` |
| **Default Icon Reset** | Re-enables default launcher alias and disables others | Passes `nil` to `setAlternateIconName(nil)` |
| **Current Icon Detection** | Resolves active launcher intent from `PackageManager` | Inspects `alternateIconName` or `CFBundlePrimaryIcon` |
| **Asset Location** | `android/app/src/main/res/mipmap-*` | `ios/Runner/` bundle resources |
| **Min Supported OS** | Android SDK 24+ (Android 7.0+) | iOS 15.0+ |

---

## Roadmap

* **Phase 1 (v0.0.1):** Core native runtime engine for Android & iOS with decoupled `changeIcon()` and `resetIcon()`. (Completed)
* **Phase 2 (v0.1.0):** Automated CLI image generation (`dart run chameleon_icons:generate`) for automatic multi-density asset resizing.
* **Phase 3 (v0.1.0):** Automated injection into `AndroidManifest.xml` and `Info.plist`.
* **Phase 4 (v0.2.0):** Ready-to-use customizable UI components (Telegram-style `ChameleonIconGrid`).

---

## License

MIT License. Copyright (c) 2026 Farook Jamal.
