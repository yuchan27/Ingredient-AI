# 食伴 AI Brand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the formal Flutter app's default launcher identity with the friendly `食伴 AI` brand and the plate-lens icon on Android, Web, Windows, and in-app title surfaces.

**Architecture:** Keep package, bundle, Firebase, and backend identifiers unchanged. Centralize user-facing copy in one Dart brand identity class, keep icon artwork as deterministic 1024 px source assets, and let `flutter_launcher_icons` generate platform-specific files from those sources.

**Tech Stack:** Flutter 3 / Dart 3, Python 3 + Pillow for deterministic source artwork, `flutter_launcher_icons 0.14.4`, Android adaptive icons, Web PWA icons, Windows ICO.

## Global Constraints

- Formal display name: `食伴 AI`.
- Brand tagline: `懂你每一餐`.
- Colors: leaf green `#1F7658`, warm apricot `#F3B562`, cream `#FFF8E9`, deep green `#174E3E`.
- Do not change `applicationId`, bundle identifiers, Firebase project IDs, database formats, API routes, or authentication behavior.
- Do not modify or stage unrelated `foodlens_ai/app/.gitignore` and Windows generated-plugin changes already present in the working tree.
- Do not create a branch, pull request, GitHub Release, or push unless separately authorized.

---

### Task 1: Centralize and apply product identity

**Files:**
- Create: `foodlens_ai/app/lib/brand/brand_identity.dart`
- Create: `foodlens_ai/app/test/brand/brand_identity_test.dart`
- Modify: `foodlens_ai/app/test/widget_test.dart`
- Modify: `foodlens_ai/app/lib/app.dart`
- Modify: `foodlens_ai/app/lib/screens/home_screen.dart`
- Modify: `foodlens_ai/app/lib/screens/settings_screen.dart`

**Interfaces:**
- Produces: `BrandIdentity.name`, `BrandIdentity.tagline`, and `BrandIdentity.versionLabel` string constants.
- Consumes: Existing Flutter widget tree; no service or persistence dependencies.

- [ ] **Step 1: Write the failing brand unit test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/brand/brand_identity.dart';

void main() {
  test('defines the approved user-facing brand', () {
    expect(BrandIdentity.name, '食伴 AI');
    expect(BrandIdentity.tagline, '懂你每一餐');
    expect(BrandIdentity.versionLabel, '食伴 AI 1.0.0');
  });
}
```

- [ ] **Step 2: Change the existing setup-state assertion before implementation**

Replace `expect(find.text('FoodLens AI'), findsOneWidget);` with:

```dart
expect(find.text('食伴 AI'), findsOneWidget);
```

- [ ] **Step 3: Run the focused tests and verify they fail**

Run:

```powershell
cd foodlens_ai\app
flutter test test\brand\brand_identity_test.dart test\widget_test.dart
```

Expected: FAIL because `brand_identity.dart` does not exist and the setup screen still renders `FoodLens AI`.

- [ ] **Step 4: Add the minimal brand identity class**

```dart
abstract final class BrandIdentity {
  static const name = '食伴 AI';
  static const tagline = '懂你每一餐';
  static const versionLabel = '$name 1.0.0';
}
```

- [ ] **Step 5: Replace user-facing product copy**

Import `BrandIdentity` into `app.dart`, `home_screen.dart`, and `settings_screen.dart`. Replace `FoodLens AI` title strings with `BrandIdentity.name`, replace the signed-out subtitle with `BrandIdentity.tagline`, and replace the settings footer with `BrandIdentity.versionLabel`. Keep class names, demo email, package names, and Firebase identifiers unchanged.

- [ ] **Step 6: Run the focused tests and verify they pass**

Run:

```powershell
flutter test test\brand\brand_identity_test.dart test\widget_test.dart
```

Expected: both test files PASS.

- [ ] **Step 7: Commit the identity change**

```powershell
git add foodlens_ai/app/lib/brand/brand_identity.dart foodlens_ai/app/lib/app.dart foodlens_ai/app/lib/screens/home_screen.dart foodlens_ai/app/lib/screens/settings_screen.dart foodlens_ai/app/test/brand/brand_identity_test.dart foodlens_ai/app/test/widget_test.dart
git commit -m "feat: apply Food Companion product identity"
```

### Task 2: Update platform display metadata

**Files:**
- Create: `foodlens_ai/app/test/brand/platform_branding_test.dart`
- Modify: `foodlens_ai/app/android/app/src/main/AndroidManifest.xml`
- Modify: `foodlens_ai/app/web/manifest.json`
- Modify: `foodlens_ai/app/web/index.html`
- Modify: `foodlens_ai/app/windows/runner/main.cpp`
- Modify: `foodlens_ai/app/windows/runner/Runner.rc`
- Modify: `foodlens_ai/app/pubspec.yaml`

**Interfaces:**
- Consumes: `食伴 AI`, `懂你每一餐`, and the approved colors from the design specification.
- Produces: Platform launcher/window metadata without changing executable or application identifiers.

- [ ] **Step 1: Write the failing platform metadata test**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform metadata uses the approved brand', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="食伴 AI"'));

    final webManifest = jsonDecode(File('web/manifest.json').readAsStringSync()) as Map<String, dynamic>;
    expect(webManifest['name'], '食伴 AI');
    expect(webManifest['short_name'], '食伴 AI');
    expect(webManifest['background_color'], '#1F7658');
    expect(webManifest['theme_color'], '#1F7658');

    final webIndex = File('web/index.html').readAsStringSync();
    expect(webIndex, contains('<title>食伴 AI</title>'));
    expect(webIndex, contains('content="食伴 AI"'));

    final windowsMain = File('windows/runner/main.cpp').readAsStringSync();
    expect(windowsMain, contains('window.Create(L"食伴 AI"'));
    final windowsResources = File('windows/runner/Runner.rc').readAsStringSync();
    expect(windowsResources, contains('VALUE "ProductName", "食伴 AI"'));
  });
}
```

- [ ] **Step 2: Run the metadata test and verify it fails**

Run: `flutter test test\brand\platform_branding_test.dart`

Expected: FAIL on the first old `FoodLens AI` or `foodlens_ai_app` value.

- [ ] **Step 3: Apply platform metadata**

Set Android `android:label` to `食伴 AI`; Web `name`, `short_name`, Apple mobile title, HTML title, description, `background_color`, and `theme_color` to the approved values; Windows window title, `FileDescription`, and `ProductName` to `食伴 AI`. Keep `InternalName`, `OriginalFilename`, `BINARY_NAME`, namespace, and application ID unchanged. Update `pubspec.yaml` description to `食伴 AI local-first nutrition analysis application.`.

- [ ] **Step 4: Run the metadata test and verify it passes**

Run: `flutter test test\brand\platform_branding_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the metadata change**

```powershell
git add foodlens_ai/app/android/app/src/main/AndroidManifest.xml foodlens_ai/app/web/manifest.json foodlens_ai/app/web/index.html foodlens_ai/app/windows/runner/main.cpp foodlens_ai/app/windows/runner/Runner.rc foodlens_ai/app/pubspec.yaml foodlens_ai/app/test/brand/platform_branding_test.dart
git commit -m "feat: update Food Companion platform titles"
```

### Task 3: Generate launcher artwork and platform assets

**Files:**
- Create: `foodlens_ai/app/tool/generate_brand_icon.py`
- Create: `foodlens_ai/app/tool/test_brand_assets.py`
- Create: `foodlens_ai/app/assets/branding/app_icon.png`
- Create: `foodlens_ai/app/assets/branding/app_icon_foreground.png`
- Create: `foodlens_ai/app/assets/branding/app_icon_monochrome.png`
- Create: `foodlens_ai/app/flutter_launcher_icons.yaml`
- Modify: `foodlens_ai/app/pubspec.yaml`
- Modify: generated Android mipmap/adaptive icon files under `foodlens_ai/app/android/app/src/main/res/`
- Modify: generated Web icons under `foodlens_ai/app/web/`
- Modify: `foodlens_ai/app/windows/runner/resources/app_icon.ico`
- Modify: `foodlens_ai/app/lib/app.dart`

**Interfaces:**
- Consumes: Approved geometry and brand colors.
- Produces: Deterministic 1024 px master, adaptive foreground/monochrome sources, and all existing Android/Web/Windows launcher assets.

- [ ] **Step 1: Record the default icon hashes and write a failing asset test**

Create this standard-library-only test:

```python
EXPECTED_PNG_SIZES = {
    "assets/branding/app_icon.png": (1024, 1024),
    "assets/branding/app_icon_foreground.png": (1024, 1024),
    "assets/branding/app_icon_monochrome.png": (1024, 1024),
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
    "web/icons/Icon-192.png": (192, 192),
    "web/icons/Icon-512.png": (512, 512),
}

FORBIDDEN_DEFAULT_HASHES = {
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": "c7c0c0189145e4e32a401c61c9bdc615754b0264e7afae24e834bb81049eaf81",
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": "6a7c8f0d703e3682108f9662f813302236240d3f8f638bb391e32bfb96055fef",
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": "e14aa40904929bf313fded22cf7e7ffcbf1d1aac4263b5ef1be8bfce650397aa",
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": "4d470bf22d5c17d84edc5f82516d1ba8a1c09559cd761cefb792f86d9f52b540",
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": "3c34e1f298d0c9ea3455d46db6b7759c8211a49e9ec6e44b635fc5c87dfb4180",
    "web/icons/Icon-192.png": "3dce99077602f70421c1c6b2a240bc9b83d64d86681d45f2154143310c980be3",
    "web/icons/Icon-512.png": "baccb205ae45f0b421be1657259b4943ac40c95094ab877f3bcbe12cd544dcbe",
    "windows/runner/resources/app_icon.ico": "c098d3fc85cacff98b8e69811b48e9f0d852fcee278132d794411d978869cbf8",
}

def png_size(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    return tuple(int.from_bytes(data[offset:offset + 4], "big") for offset in (16, 20))

def main():
    import hashlib
    from pathlib import Path

    root = Path(__file__).resolve().parents[1]
    for relative, expected in EXPECTED_PNG_SIZES.items():
        path = root / relative
        assert path.exists(), f"Missing {relative}"
        assert png_size(path) == expected, f"Wrong size for {relative}"
    for relative, forbidden in FORBIDDEN_DEFAULT_HASHES.items():
        digest = hashlib.sha256((root / relative).read_bytes()).hexdigest()
        assert digest != forbidden, f"Default icon remains: {relative}"
    assert (root / "windows/runner/resources/app_icon.ico").read_bytes()[:4] == b"\x00\x00\x01\x00"
    print("Brand asset verification passed.")

if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the asset test and verify it fails**

Run:

```powershell
& 'C:\Users\wuwu6\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tool\test_brand_assets.py
```

Expected: FAIL because the three approved 1024 px sources do not exist.

- [ ] **Step 3: Implement the deterministic master-art generator**

Create the deterministic generator:

```python
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "branding"
GREEN = "#1F7658"
APRICOT = "#F3B562"
CREAM = "#FFF8E9"
DEEP_GREEN = "#174E3E"

def sparkle(draw, center, outer, inner, fill):
    cx, cy = center
    points = [
        (cx, cy - outer), (cx + inner, cy - inner),
        (cx + outer, cy), (cx + inner, cy + inner),
        (cx, cy + outer), (cx - inner, cy + inner),
        (cx - outer, cy), (cx - inner, cy - inner),
    ]
    draw.polygon(points, fill=fill)

def foreground(colorized=True):
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    main = CREAM if colorized else "#FFFFFF"
    inner = APRICOT if colorized else "#FFFFFF"
    ink = DEEP_GREEN if colorized else "#FFFFFF"
    draw.line((690, 690, 842, 842), fill=main, width=112)
    draw.ellipse((202, 180, 750, 728), fill=main)
    draw.ellipse((300, 278, 652, 630), fill=inner)
    if colorized:
        draw.ellipse((395, 420, 431, 456), fill=ink)
        draw.ellipse((535, 420, 571, 456), fill=ink)
        draw.arc((390, 418, 584, 566), 28, 152, fill=ink, width=26)
        draw.arc((236, 214, 684, 662), 206, 288, fill="#FFFFFF", width=22)
    sparkle(draw, (778, 198), 72, 20, main)
    return image

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    fg = foreground(colorized=True)
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse((210, 200, 770, 760), fill=(13, 62, 46, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    master = Image.new("RGBA", (SIZE, SIZE), GREEN)
    master.alpha_composite(shadow)
    master.alpha_composite(fg)
    master.save(OUT / "app_icon.png", optimize=True)
    fg.save(OUT / "app_icon_foreground.png", optimize=True)
    foreground(colorized=False).save(OUT / "app_icon_monochrome.png", optimize=True)

if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Add reproducible launcher generation configuration**

Add `flutter_launcher_icons: ^0.14.4` under `dev_dependencies`, declare `assets/branding/app_icon.png` as a Flutter asset, and create:

```yaml
flutter_launcher_icons:
  android: true
  image_path: assets/branding/app_icon.png
  min_sdk_android: 23
  adaptive_icon_background: "#1F7658"
  adaptive_icon_foreground: assets/branding/app_icon_foreground.png
  adaptive_icon_monochrome: assets/branding/app_icon_monochrome.png
  adaptive_icon_foreground_inset: 18
  web:
    generate: true
    image_path: assets/branding/app_icon.png
    background_color: "#1F7658"
    theme_color: "#1F7658"
  windows:
    generate: true
    image_path: assets/branding/app_icon.png
    icon_size: 256
```

- [ ] **Step 5: Generate platform icons**

Run:

```powershell
& 'C:\Users\wuwu6\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tool\generate_brand_icon.py
flutter pub get
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

Expected: Android, Web, and Windows icons report successful generation.

- [ ] **Step 6: Reuse the master icon in the sign-in screen**

Replace the generic `Icons.food_bank_outlined` sign-in glyph in `app.dart` with:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(18),
  child: Image.asset(
    'assets/branding/app_icon.png',
    width: 72,
    height: 72,
  ),
)
```

- [ ] **Step 7: Run asset and Flutter tests**

Run:

```powershell
& 'C:\Users\wuwu6\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tool\test_brand_assets.py
flutter test
flutter analyze
```

Expected: asset test PASS, all Flutter tests PASS, analyze reports no issues.

- [ ] **Step 8: Commit artwork and generated assets**

Stage only the source art, generator/tests, launcher configuration, expected generated icon paths, `pubspec.yaml`, `pubspec.lock`, and the sign-in widget. Do not stage pre-existing generated plugin files.

Commit: `feat: add Food Companion launcher icon`.

### Task 4: Android build and emulator verification

**Files:**
- Verify only; no new product files expected.

**Interfaces:**
- Consumes: Completed brand identity and generated launcher resources.
- Produces: Evidence that the formal Android app compiles, installs, and presents the new identity.

- [ ] **Step 1: Run clean source checks**

Run:

```powershell
git diff --check
flutter test
flutter analyze
```

Expected: no whitespace errors, all tests PASS, analyze reports no issues.

- [ ] **Step 2: Build the Android debug APK**

Run: `flutter build apk --debug`

Expected: `build\app\outputs\flutter-apk\app-debug.apk` is produced successfully.

- [ ] **Step 3: Install on the available Pixel 9 emulator**

Run:

```powershell
adb devices
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Expected: one emulator is listed and installation reports `Success`.

- [ ] **Step 4: Inspect the launcher and app screens**

Launch `com.foodlens.foodlens_ai_app`, verify the launcher label `食伴 AI`, the plate-lens icon, the sign-in title `食伴 AI`, tagline `懂你每一餐`, and the authenticated home title. Capture screenshots only as ignored local verification artifacts.

- [ ] **Step 5: Audit Git scope and final commit state**

Run:

```powershell
git status --short
git log -5 --oneline
```

Expected: only unrelated pre-existing `.gitignore` and Windows plugin-registry changes remain unstaged; all brand commits are on `main`.
