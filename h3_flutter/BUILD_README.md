# H3 Flutter Build Process

## Quick Start

### One-Command Build (Recommended)
```bash
./build_all.sh
```

This script performs the complete end-to-end build process:
1. ✓ Checks prerequisites (CMake, Xcode, Flutter, Dart)
2. ✓ Initializes H3 C library submodule
3. ✓ Builds dynamic framework for iOS/macOS
4. ✓ Verifies framework structure and code signing
5. ✓ Runs integration tests
6. ✓ Provides detailed summary

### Manual Build Steps

If you prefer to run steps individually:

#### 1. Build Framework Only
```bash
cd bindings/scripts
./build_darwin_static_lib.sh
```

#### 2. Run Tests
```bash
cd example
flutter clean
flutter test integration_test/app_test.dart -d macos
```

## Prerequisites

- **macOS**: Required for iOS/macOS framework building
- **Xcode**: Install from App Store
- **CMake**: `brew install cmake`
- **Flutter**: Latest stable version
- **Dart**: Included with Flutter

## Output

After building, you'll find:
```
h3_flutter/
└── darwin/
    └── Libs/
        └── h3.xcframework/
            ├── ios-arm64/
            │   └── h3.framework/
            ├── ios-arm64_x86_64-simulator/
            │   └── h3.framework/
            └── macos-arm64_x86_64/
                └── h3.framework/
```

## Verification

The build script automatically verifies:
- ✓ Framework structure is correct
- ✓ Symbols are exported (dlsym compatible)
- ✓ Code signing is applied
- ✓ Tests pass

## Troubleshooting

### CMake not found
```bash
brew install cmake
```

### Xcode not configured
```bash
sudo xcode-select --switch /Applications/Xcode.app
```

### Submodule issues
```bash
cd ..  # Go to h3_dart root
git submodule update --init --recursive
```

### Build fails
1. Clean and try again:
   ```bash
   rm -rf bindings/build
   rm -rf darwin/Libs/h3.xcframework
   ./build_all.sh
   ```

2. Check logs in `/tmp/h3_flutter_test.log`

## Using the Built Framework

See [INTEGRATION_GUIDE.md](../../INTEGRATION_GUIDE.md) for details on using this in your Flutter projects.

## CI/CD Integration

For GitHub Actions or other CI:

```yaml
- name: Build H3 Flutter Framework
  run: |
    cd h3_flutter
    ./build_all.sh
```

## Clean Build

To completely clean and rebuild:
```bash
# Clean framework
rm -rf darwin/Libs/h3.xcframework

# Clean build artifacts
rm -rf bindings/build

# Clean example
cd example
flutter clean

# Rebuild
cd ..
./build_all.sh
```

## Framework Details

### Size
- iOS Device (arm64): ~163 KB
- iOS Simulator (arm64 + x86_64): ~339 KB
- macOS (arm64 + x86_64): ~339 KB

### Deployment Targets
- iOS: 12.0+
- macOS: 10.13+

### Architecture Support
- iOS: arm64 (device), arm64 + x86_64 (simulator)
- macOS: arm64 + x86_64 (universal)

## Build Time

Typical build times on Apple Silicon Mac:
- First build: ~2-3 minutes
- Incremental: ~1 minute
- With tests: ~3-5 minutes total
