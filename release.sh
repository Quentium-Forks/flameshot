#!/bin/bash
VERSION=13.3.0.0
DIR=flameshot-$VERSION
ARCH=$(uname -m)
ARCH_DPKG=$(dpkg --print-architecture)
export VERSION=$VERSION

# cleanup
rm -rf build release data/translations/*.qm rpm/BUILD rpm/BUILDROOT rpm/*RPMS rpm/SOURCES debug*.list elfbins.list

# Download Qt-Color-Widgets for launchpad builds and extract into external folder
mkdir -p external
if [ ! -d "external/Qt-Color-Widgets" ]; then
    wget -q https://gitlab.com/mattbas/Qt-Color-Widgets/-/archive/master/Qt-Color-Widgets-master.tar.gz -O /tmp/Qt-Color-Widgets.tar.gz
    tar -xzf /tmp/Qt-Color-Widgets.tar.gz -C external
    rm /tmp/Qt-Color-Widgets.tar.gz
    rm -rf external/Qt-Color-Widgets
    mv external/Qt-Color-Widgets-master external/Qt-Color-Widgets
fi

# Check if kdsingleapplication dependencies are installed
if dpkg -s libkdsingleapplication-qt6-dev > /dev/null 2>&1; then
    EXTRA_FLAGS="-DUSE_BUNDLED_KDSINGLEAPPLICATION=OFF"
else
    EXTRA_FLAGS="-DUSE_BUNDLED_KDSINGLEAPPLICATION=ON"
    # Download KDSingleApplication for launchpad builds and extract into external folder
    if [ ! -d "external/KDSingleApplication" ]; then
        wget -q https://github.com/KDAB/KDSingleApplication/archive/refs/heads/master.tar.gz -O /tmp/KDSingleApplication.tar.gz
        tar -xzf /tmp/KDSingleApplication.tar.gz -C external
        rm /tmp/KDSingleApplication.tar.gz
        rm -rf external/KDSingleApplication
        mv external/KDSingleApplication-master external/KDSingleApplication
    fi
fi

# build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr $EXTRA_FLAGS
cmake --build build -j $(nproc)
strip -s build/src/flameshot

# assets
mkdir -p release/$DIR
cp -r src external data CMakeLists.txt cmake packaging/debian README.md release/$DIR

# translations
export QT_SELECT=qt6
# Expand PATH to find lupdate & lrelease
export PATH="/usr/lib/$QT_SELECT/bin:$PATH"
lupdate src/ -ts data/translations/*.ts
lrelease data/translations/*.ts
mkdir -p release/$DIR/flameshot/translations
cp data/translations/*.qm release/$DIR/flameshot/translations

# Change architecture
sed -i "s/^Architecture:\s\+.*$/Architecture: $ARCH_DPKG/g" release/$DIR/debian/control

# tarball
tar -czf release/$DIR.tar.gz -C release $DIR

rm -rf external/Qt-Color-Widgets

# appimagetool
wget -qc https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimagetool-.*-$ARCH.AppImage" | head -n 1 | cut -d '"' -f 2) -O appimagetool-$ARCH.AppImage
chmod +x appimagetool-$ARCH.AppImage

# appimage
DESTDIR=../release/$DIR cmake --build build --target install -j $(nproc)
./appimagetool-$ARCH.AppImage -s deploy release/$DIR/usr/share/applications/org.flameshot.Flameshot.desktop
./appimagetool-$ARCH.AppImage release/$DIR
mv Flameshot-$VERSION-$ARCH.AppImage release

rm appimagetool-$ARCH.AppImage

# debian package
cd release/$DIR
# Export CMake prefix path for debuild using aqtinstall
if [ -z "$QT_PLUGIN_PATH" ]; then
    QT_ROOT=$(dirname "$QT_PLUGIN_PATH")
    export CMAKE_PREFIX_PATH="$QT_ROOT/lib/cmake"
fi
dh_make --createorig --indep --yes
debuild --preserve-envvar=CMAKE_PREFIX_PATH \
    --preserve-envvar=QT_PLUGIN_PATH \
    --preserve-envvar=LD_LIBRARY_PATH \
    --no-lintian -us -uc
cd ../..

# rpm package
mkdir -p rpm/SOURCES
cp release/$DIR.tar.gz rpm/SOURCES
# Change architecture
sed -i "s/^BuildArch:\s\+.*$/BuildArch:      $ARCH/g" rpm/SPECS/flameshot.spec
rpmbuild -bb --build-in-place --define "_topdir $(pwd)/rpm" rpm/SPECS/flameshot.spec
mv rpm/RPMS/$ARCH/flameshot-$VERSION-1.$ARCH.rpm release/flameshot-$VERSION.$ARCH.rpm
