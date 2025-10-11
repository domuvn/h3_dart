<p>
<a href="https://github.com/festelo/h3_dart/actions"><img src="https://github.com/festelo/h3_dart/actions/workflows/tests.yml/badge.svg" alt="Build & Test"></a>
<a href="https://codecov.io/gh/festelo/h3_dart"><img src="https://codecov.io/gh/festelo/h3_dart/branch/master/graph/badge.svg" alt="codecov"></a>
<a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License: Apache 2.0"></a>
</p>

## H3 Flutter

Cross‑platform Flutter plugin for Uber's [H3](https://github.com/uber/h3) library.
Internally it delegates to [h3_ffi](https://pub.dev/packages/h3_ffi) on the VM and to [h3_web](https://pub.dev/packages/h3_web) on the web.

### ⚡ Dynamic Framework Support (iOS Fix)

This fork includes a **critical fix for iOS FFI symbol lookup issues**. The original package used static linking (`.a` libraries), which caused runtime errors on iOS:
```
Failed to lookup symbol 'degsToRads': dlsym(RTLD_DEFAULT, degsToRads): symbol not found
```

**What We Changed:**
- ✅ Converted from **static** to **dynamic framework** (`.dylib`)
- ✅ Created proper framework bundles for CocoaPods compatibility
- ✅ Fixed FFI `dlsym()` symbol lookup on iOS devices
- ✅ Added automated build and test scripts
- ✅ Maintains full backward compatibility (except header imports)

**Why This Was Necessary:**

Dart's FFI on iOS uses `DynamicLibrary.process()` which calls `dlsym(RTLD_DEFAULT, symbol_name)` to lookup symbols at runtime. Static libraries don't export symbols to the dynamic symbol table, making them invisible to `dlsym()`. Dynamic frameworks solve this by exporting all symbols, allowing FFI to find them successfully.

See [BUILDING_DYNAMIC_FRAMEWORK.md](BUILDING_DYNAMIC_FRAMEWORK.md) for technical details.

```dart
final h3Factory = const H3Factory();
final h3 = h3Factory.load();
// Get hexagons in specified triangle.
final hexagons = h3.polyfill(
  resolution: 5,
  coordinates: [
    GeoCoord(20.4522, 54.7104),
    GeoCoord(37.6173, 55.7558),
    GeoCoord(39.7015, 47.2357),
  ],
);
```  

There are also a few methods ported from the JS library [Geojson2H3](https://github.com/uber/geojson2h3). To access them, instantiate the `Geojson2H3` class using `const Geojson2H3(h3)`. It uses [package:geojson2h3](https://pub.dev/packages/geojson2h3) internally.

## Setup

### iOS (Using This Fork)

This fork uses dynamic frameworks. Add to your `pubspec.yaml`:

**Option 1: Git Dependency (Recommended)**
```yaml
dependencies:
  h3_flutter:
    git:
      url: https://github.com/domuvn/h3_dart.git
      path: h3_flutter
      ref: dynamic-framework
```

**Option 2: Local Path (Development)**
```yaml
dependencies:
  h3_flutter:
    path: /path/to/your/h3_dart/h3_flutter
```

**Then in your Dart code:**
```dart
import 'package:h3_flutter/h3_flutter.dart';

final h3 = const H3Factory().load();
final geojson2h3 = Geojson2H3(h3);
```

**Setup steps:**
```bash
flutter pub get
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter clean
flutter run
```

**Important for Custom Bridging Headers:**
If your project imports h3 headers, update to framework-style import:
```objc
// Old
#import <h3api.h>

// New (required)
#import <h3/h3api.h>
```

See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) for detailed setup and troubleshooting.

### Android, Desktop, Web

No changes required. Add `h3_flutter` package to `pubspec.yaml`, import it, and load:
```dart
import 'package:h3_flutter/h3_flutter.dart';

final h3 = const H3Factory().load();
final geojson2h3 = Geojson2H3(h3);
```

### Web

Web version is built on top of `h3-js` v4.2.1, you have to include it.  
Add next line to your `index.html`:
```html
<script defer src="https://unpkg.com/h3-js@4.2.1"></script>
```  
*Note: Make sure to place this <script> tag before the main.dart.js import in your index.html.*

-------------
## For Contributors

### Building the Dynamic Framework

**Quick Start (Automated):**
```bash
cd h3_flutter
./build_all.sh
```

This automated script:
1. Checks prerequisites (CMake, Xcode, Flutter, Dart)
2. Initializes H3 C library submodule
3. Builds dynamic framework for iOS/macOS
4. Verifies framework structure and code signing
5. Runs integration tests
6. Provides detailed summary

See [h3_flutter/BUILD_README.md](h3_flutter/BUILD_README.md) for manual build steps and troubleshooting.

**Manual Build:**
```bash
cd h3_flutter/bindings/scripts
./build_darwin_static_lib.sh
```

**Prerequisites:**
- macOS (required for iOS/macOS builds)
- Xcode with command-line tools
- CMake: `brew install cmake`
- Flutter SDK

**Output:**
The build creates `h3_flutter/darwin/Libs/h3.xcframework` containing:
- iOS device framework (arm64)
- iOS simulator framework (arm64 + x86_64)
- macOS framework (arm64 + x86_64)

### Testing

**Run all tests:**
```bash
cd h3_flutter/example
flutter test integration_test/app_test.dart -d macos
```

**Verify framework:**
```bash
# Check symbols are exported
nm -gU darwin/Libs/h3.xcframework/ios-arm64/h3.framework/h3 | grep degsToRads

# Verify code signing
codesign -dv darwin/Libs/h3.xcframework/ios-arm64/h3.framework/h3
```

### Upgrading H3 Library Version
  
As this library is built on top of `h3_web` and `h3_ffi`, you must update these packages first:
1. Update the H3 C library submodule in `h3_ffi/c/h3`
2. Regenerate FFI bindings (see h3_ffi README)
3. Update h3_web bindings (see h3_web README)
4. Rebuild the dynamic framework: `./build_all.sh`
5. Run tests on all platforms

### Documentation

- **[BUILDING_DYNAMIC_FRAMEWORK.md](BUILDING_DYNAMIC_FRAMEWORK.md)** - Technical deep dive on static vs dynamic linking
- **[INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)** - How to use this fork in your projects
- **[h3_flutter/BUILD_README.md](h3_flutter/BUILD_README.md)** - Build process details and troubleshooting
