#!/bin/bash

echo "Building for Linux"
flutter build linux

echo "Building for Linux AppImage"
flutter_distributor package --platform linux --targets appimage

echo "Building for Linux Deb"
flutter_distributor package --platform linux --targets deb

echo "Building for Linux RPM"
flutter_distributor package --platform linux --targets rpm

echo "Building for Linux Zip"
flutter_distributor package --platform linux --targets zip

