#!/bin/bash

rm -rf build data/translations/*.qm

# Check if kdsingleapplication dependencies are installed
if dpkg -s libkdsingleapplication-qt6-dev > /dev/null 2>&1; then
    EXTRA_FLAGS="-DUSE_BUNDLED_KDSINGLEAPPLICATION=OFF"
else
    EXTRA_FLAGS="-DUSE_BUNDLED_KDSINGLEAPPLICATION=ON"
fi

cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug $EXTRA_FLAGS
cmake --build build -j $(nproc)

./build/src/flameshot
