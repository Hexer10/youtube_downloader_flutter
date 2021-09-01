#!/bin/sh

# Create Application Directory
mkdir -p AppDir

# Create AppRun file(required by AppImage)
echo '#!/bin/sh

cd "$(dirname "$0")"
exec ./youtube_downloader_flutter' > AppDir/AppRun
sudo chmod +x AppDir/AppRun

# Copy All build files to AppDir
cp -r build/linux/x64/release/bundle/* AppDir

## Add Application metadata
# Copy app icon
sudo mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps/
cp android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png AppDir/youtube_downloader_flutter.png
sudo cp AppDir/youtube_downloader_flutter.png AppDir/usr/share/icons/hicolor/256x256/apps/youtube_downloader_flutter.png

sudo mkdir -p AppDir/usr/share/applications

# Either copy .desktop file content from file or with echo command
# cp assets/youtube_downloader_flutter.desktop AppDir/youtube_downloader_flutter.desktop

echo '[Desktop Entry]
Version=1.0
Type=Application
Name=Youtube downloader flutter
Icon=youtube_downloader_flutter
Exec=youtube_downloader_flutter %u
StartupWMClass=youtube_downloader_flutter
Categories=Utility;' > AppDir/youtube_downloader_flutter.desktop

# Also copy the same .desktop file to usr folder
sudo cp AppDir/youtube_downloader_flutter.desktop AppDir/usr/share/applications/youtube_downloader_flutter.desktop

## Start build
test ! -e appimagetool-x86_64.AppImage && curl -L https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -o appimagetool-x86_64.AppImage
sudo chmod +x appimagetool-x86_64.AppImage
ARCH=x86_64 ./appimagetool-x86_64.AppImage AppDir/ youtube_downloader_flutter-x86_64.AppImage