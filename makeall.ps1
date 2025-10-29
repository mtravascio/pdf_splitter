
echo "Building for Windows"
flutter build windows

echo "Building for Windows Setup.exe"
fastforge package --platform windows --targets exe

echo "Building for Windows Zip"
fastforge package --platform windows --targets zip

echo "Building for Windows MSIX (Requires KEY PASSWORD & ver info in make_config.yaml!)"
fastforge package --platform windows --targets msix

