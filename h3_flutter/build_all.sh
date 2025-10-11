#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variable

##############################################################################
# H3 Flutter - Complete Build Script
# 
# This script performs an end-to-end build of h3_flutter with dynamic framework:
# 1. Builds the H3 dynamic framework for iOS/macOS
# 2. Runs tests to verify the build
# 3. Cleans up build artifacts
##############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Absolute path to h3_flutter directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}H3 Flutter - End-to-End Build${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

##############################################################################
# Step 1: Check Prerequisites
##############################################################################

echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"

# Check for CMake
if ! command -v cmake &> /dev/null; then
    echo -e "${RED}✗ CMake not found. Install it with: brew install cmake${NC}"
    exit 1
fi
echo -e "${GREEN}✓ CMake found: $(cmake --version | head -n1)${NC}"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}✗ Xcode not found. Install Xcode from the App Store.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Xcode found: $(xcodebuild -version | head -n1)${NC}"

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found. Install Flutter first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -n1)${NC}"

# Check for Dart
if ! command -v dart &> /dev/null; then
    echo -e "${RED}✗ Dart not found. Flutter should include Dart.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dart found: $(dart --version | head -n1)${NC}"

echo ""

##############################################################################
# Step 2: Initialize Submodules
##############################################################################

echo -e "${YELLOW}[2/5] Initializing H3 C library submodule...${NC}"

cd "$SCRIPT_DIR/.."
if [ ! -d "h3_ffi/c/h3/src" ]; then
    echo "Initializing git submodules..."
    git submodule update --init --recursive
    echo -e "${GREEN}✓ Submodules initialized${NC}"
else
    echo -e "${GREEN}✓ Submodules already initialized${NC}"
fi

echo ""

##############################################################################
# Step 3: Build Dynamic Framework
##############################################################################

echo -e "${YELLOW}[3/5] Building H3 dynamic framework...${NC}"

cd "$SCRIPT_DIR"
echo "Running build script: bindings/scripts/build_darwin_static_lib.sh"

if bindings/scripts/build_darwin_static_lib.sh; then
    echo -e "${GREEN}✓ Framework built successfully${NC}"
else
    echo -e "${RED}✗ Framework build failed${NC}"
    exit 1
fi

# Verify framework structure
echo ""
echo "Verifying framework structure..."
if [ -d "darwin/Libs/h3.xcframework/ios-arm64/h3.framework" ]; then
    echo -e "${GREEN}✓ iOS framework structure verified${NC}"
else
    echo -e "${RED}✗ iOS framework not found${NC}"
    exit 1
fi

if [ -d "darwin/Libs/h3.xcframework/macos-arm64_x86_64/h3.framework" ]; then
    echo -e "${GREEN}✓ macOS framework structure verified${NC}"
else
    echo -e "${RED}✗ macOS framework not found${NC}"
    exit 1
fi

# Verify symbols are exported
echo ""
echo "Verifying symbol export..."
if nm -gU darwin/Libs/h3.xcframework/ios-arm64/h3.framework/h3 | grep -q degsToRads; then
    echo -e "${GREEN}✓ Symbols exported correctly (degsToRads found)${NC}"
else
    echo -e "${RED}✗ Symbol export verification failed${NC}"
    exit 1
fi

# Verify code signing
echo ""
echo "Verifying code signing..."
if codesign -dv darwin/Libs/h3.xcframework/ios-arm64/h3.framework/h3 2>&1 | grep -q "Signature="; then
    echo -e "${GREEN}✓ Framework is code signed${NC}"
else
    echo -e "${RED}✗ Framework is not code signed${NC}"
    exit 1
fi

echo ""

##############################################################################
# Step 4: Run Tests
##############################################################################

echo -e "${YELLOW}[4/5] Running tests...${NC}"

cd "$SCRIPT_DIR/example"

# Clean first
echo "Cleaning previous builds..."
flutter clean > /dev/null 2>&1

# Run macOS integration test
echo ""
echo "Running integration test on macOS..."
if flutter test integration_test/app_test.dart -d macos 2>&1 | tee /tmp/h3_flutter_test.log | grep -q "All tests passed"; then
    echo -e "${GREEN}✓ All tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed. Check /tmp/h3_flutter_test.log for details${NC}"
    exit 1
fi

echo ""

##############################################################################
# Step 5: Summary
##############################################################################

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Complete! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Summary:"
echo "  • Dynamic framework: darwin/Libs/h3.xcframework"
echo "  • Platforms: iOS, iOS Simulator, macOS"
echo "  • Tests: Passed"
echo "  • Status: Ready to use"
echo ""
echo "Framework details:"
cd "$SCRIPT_DIR"
echo "  iOS device:"
ls -lh darwin/Libs/h3.xcframework/ios-arm64/h3.framework/h3 | awk '{print "    Size: " $5}'
echo "  iOS simulator:"
ls -lh darwin/Libs/h3.xcframework/ios-arm64_x86_64-simulator/h3.framework/h3 | awk '{print "    Size: " $5}'
echo "  macOS:"
ls -lh darwin/Libs/h3.xcframework/macos-arm64_x86_64/h3.framework/h3 | awk '{print "    Size: " $5}'
echo ""
echo "Next steps:"
echo "  1. Use in your project via local path dependency"
echo "  2. See INTEGRATION_GUIDE.md for details"
echo "  3. Commit and push changes to Git"
echo ""
echo -e "${GREEN}Done!${NC}"
