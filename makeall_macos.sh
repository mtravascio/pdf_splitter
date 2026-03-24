#!/bin/bash

echo "Cleaning up previous builds"
flutter clean

echo "Building for macOS DMG"
fastforge package --platform macos --targets dmg

echo "Building for macOS PKG (richiede firma) per ora saltato"
#fastforge package --platform macos --targets pkg

echo "Building for macOS Zip"
fastforge package --platform macos --targets zip
