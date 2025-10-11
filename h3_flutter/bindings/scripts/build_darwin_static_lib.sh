#!/bin/bash

set -euo pipefail

# Absolute path to script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Clean build dir
rm -rf build
mkdir build
cd build

# Number of cores for parallel build
NUM_CORES=$(sysctl -n hw.ncpu)

##########
# iOS
##########

mkdir ios
cd ios
cmake ../.. \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_SYSROOT=$(xcodebuild -version -sdk iphoneos Path) \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/install \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_NAME_DIR="@rpath"
make -j"$NUM_CORES"
make install
cd ..

##########
# iOS Simulator
##########

mkdir ios-simulator
cd ios-simulator
cmake ../.. \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DCMAKE_OSX_SYSROOT=$(xcodebuild -version -sdk iphonesimulator Path) \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/install \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_NAME_DIR="@rpath"
make -j"$NUM_CORES"
make install
cd ..

##########
# macOS
##########

mkdir macos
cd macos
cmake ../.. \
    -DCMAKE_SYSTEM_NAME=Darwin \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DCMAKE_OSX_SYSROOT=$(xcodebuild -version -sdk macosx Path) \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13 \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/install \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_NAME_DIR="@rpath"
make -j"$NUM_CORES"
make install
cd ..

##########
# Create Framework Bundles
##########

echo "Creating framework bundles..."

# Function to create an iOS framework bundle (flat structure)
create_ios_framework() {
    local PLATFORM_DIR=$1
    local FRAMEWORK_NAME="h3"
    local FRAMEWORK_DIR="${PLATFORM_DIR}/install/${FRAMEWORK_NAME}.framework"
    
    mkdir -p "${FRAMEWORK_DIR}/Headers"
    
    # Copy dylib as the framework binary
    cp "${PLATFORM_DIR}/install/lib/libh3.dylib" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
    
    # Update install name to use framework path
    install_name_tool -id "@rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
        "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
    
    # Copy headers
    cp -R "${PLATFORM_DIR}/install/include/"* "${FRAMEWORK_DIR}/Headers/"
    
    # Create Info.plist at root level (iOS requirement)
    cat > "${FRAMEWORK_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.uber.h3</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>4.2.1</string>
    <key>CFBundleVersion</key>
    <string>4.2.1</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF
    
    # Sign the framework
    codesign --sign - --force "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
}

# Function to create a macOS framework bundle (versioned structure)
create_macos_framework() {
    local PLATFORM_DIR=$1
    local FRAMEWORK_NAME="h3"
    local FRAMEWORK_DIR="${PLATFORM_DIR}/install/${FRAMEWORK_NAME}.framework"
    
    mkdir -p "${FRAMEWORK_DIR}/Versions/A/Headers"
    mkdir -p "${FRAMEWORK_DIR}/Versions/A/Resources"
    
    # Copy dylib as the framework binary
    cp "${PLATFORM_DIR}/install/lib/libh3.dylib" "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"
    
    # Update install name to use framework path
    install_name_tool -id "@rpath/${FRAMEWORK_NAME}.framework/Versions/A/${FRAMEWORK_NAME}" \
        "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"
    
    # Copy headers
    cp -R "${PLATFORM_DIR}/install/include/"* "${FRAMEWORK_DIR}/Versions/A/Headers/"
    
    # Create symbolic links (macOS style)
    ln -sf "A" "${FRAMEWORK_DIR}/Versions/Current"
    ln -sf "Versions/Current/${FRAMEWORK_NAME}" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
    ln -sf "Versions/Current/Headers" "${FRAMEWORK_DIR}/Headers"
    ln -sf "Versions/Current/Resources" "${FRAMEWORK_DIR}/Resources"
    
    # Create Info.plist
    cat > "${FRAMEWORK_DIR}/Versions/A/Resources/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.uber.h3</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>4.2.1</string>
    <key>CFBundleVersion</key>
    <string>4.2.1</string>
</dict>
</plist>
EOF
    
    # Sign the framework
    codesign --sign - --force "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"
}

# Create frameworks for each platform
create_ios_framework "ios"
create_ios_framework "ios-simulator"
create_macos_framework "macos"

##########
# Create XCFramework
##########

echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework ios/install/h3.framework \
    -framework ios-simulator/install/h3.framework \
    -framework macos/install/h3.framework \
    -output h3.xcframework

cd ..

##########
# Copy output
##########

rm -rf ../darwin/Libs/h3.xcframework
mkdir -p ../darwin/Libs
cp -r build/h3.xcframework ../darwin/Libs/

# Clean build folder
rm -rf build

echo "✅ Dynamic framework built and signed successfully!"
echo "Output: darwin/Libs/h3.xcframework"
