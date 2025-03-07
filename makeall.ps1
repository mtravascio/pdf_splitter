
echo "Building for Windows"
flutter build windows

echo "Building for Windows Setup.exe"
flutter_distributor package --platform windows --targets exe

echo "Building for Windows Zip"
flutter_distributor package --platform windows --targets zip

echo "Building for Windows MSIX (Requires KEY PASSWORD & ver info in make_config.yaml!)"
flutter_distributor package --platform windows --targets msix

