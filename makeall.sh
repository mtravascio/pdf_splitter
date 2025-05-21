#!/bin/bash

echo "Building for Linux"
flutter build linux --release

echo "Building for Linux AppImage"
fastforge package --platform linux --targets appimage

echo "Building for Linux Deb"
fastforge package --platform linux --targets deb

echo "Building for Linux RPM"
fastforge package --platform linux --targets rpm

echo "Building for Linux Zip"
fastforge package --platform linux --targets zip


#Need to install flatpak and flatpak-builder
#sudo apt install flatpak flatpak-builder
#flatpak install flathub org.freedesktop.Sdk//23.08
#flatpak install flathub org.freedesktop.Platform//23.08

cd ./linux/pdf_splitter_app
echo "Building for Linux flatpak"
mkdir -p bundle
cp -r ../../build/linux/x64/release/bundle/* bundle/

flatpak-builder --force-clean build-dir flatpak/manifest.yaml

#flatpak-builder --run build-dir flatpak/manifest.yaml pdf_splitter per eseguirlo!


flatpak-builder --repo=repo --force-clean build-dir flatpak/manifest.yaml #Crea la dir repo!

flatpak build-bundle repo pdf_splitter.flatpak net.regeomaria.pdf_splitter #Crea il file pdf_splitter.flatpak! nella dir corrente

#flatpak install --reinstall --user pdf_splitter.flatpak #Installa il pacchetto flatpak appena creato

#flatpak run net.regeomaria.pdf_splitter #Esegue il pacchetto flatpak appena creato

#flatpak uninstall net.regeomaria.pdf_splitter #Disinstalla il pacchetto flatpak appena creato


