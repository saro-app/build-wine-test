#!/bin/sh

# Copyright (C) 2025 Ethan Uppal and Josh Chan
#
# This file is part of build-wine-test.
# build-wine-test is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# build-wine-test is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with build-wine-test. If not, see <https://www.gnu.org/licenses/>.

# Rosetta is known as "OAH" internally
if ! /usr/bin/pgrep -q oahd;
  then softwareupdate --install-rosetta --agree-to-license;
  else echo "Rosetta already installed"
fi

# Install homebrew for both regular and rosetta
NONINTERACTIVE=1
if ! [ -f /opt/homebrew/bin/brew ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" \
    || { echo "Failed to install arm64 homebrew"; exit 1; };
    echo >> ~/.zprofile;
    echo eval '"$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile;
    eval "$(/opt/homebrew/bin/brew shellenv)";
fi;
if ! [ -f /usr/local/bin/brew ]; then
    arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" \
    || { echo "Failed to install x86_64 homebrew"; exit 1; };
    echo >> ~/.zprofile
    echo eval '"$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/usr/local/bin/brew shellenv)"
fi;

/opt/homebrew/bin/brew install --formula bison mingw-w64 pkgconfig wget
arch -x86_64 /usr/local/bin/brew install --formula freetype gnutls molten-vk sdl2 gstreamer
export PATH="/opt/homebrew/opt/bison/bin:$PATH"

# mkdir -p ~/.pkg-config
# echo 'PKG_CONFIG_PATH="/usr/local/opt/gnutls/lib/pkgconfig:$PKG_CONFIG_PATH"' > ~/.pkg-config/env
# source ~/.pkg-config/env
# arch -x86_64 pkg-config --list-all | grep gnutls || { echo "gnutls not found in pkg-config"; exit 1; }

export CC="arch -x86_64 cc"
export CXX="arch -x86_64 c++"
export CPP="arch -x86_64 cpp"
export CFLAGS="-m64"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
# export PKG_CONFIG_PATH="/usr/local/Cellar/pkgconf/2.4.3/lib/pkgconfig/"

cd sources

echo "Running configure..."
./configure \
    --host=x86_64-darwin \
    --build=x86_64-darwin \
    --enable-archs=i386,x86_64 \
    --enable-win64 \
    --disable-tests \
    --without-alsa \
    --without-capi \
    --with-coreaudio \
    --with-cups \
    --without-dbus \
    --with-freetype \
    --with-gettext \
    --without-gettextpo \
    --without-gphoto \
    --with-gnutls \
    --without-gssapi \
    --without-krb5 \
    --with-mingw \
    --without-netapi \
    --with-opencl \
    --with-opengl \
    --without-oss \
    --with-pcap \
    --with-pcsclite \
    --with-pthread \
    --without-pulse \
    --without-sane \
    --with-sdl \
    --with-gstreamer \
    --without-udev \
    --with-unwind \
    --without-usb \
    --without-v4l2 \
    --with-vulkan \
    --without-wayland \
    --without-x \
    CFLAGS="$(arch -x86_64 /usr/local/bin/pkg-config gnutls freetype2 -cflags)" \
    LDFLAGS="$(arch -x86_64 /usr/local/bin/pkg-config gnutls freetype2 --libs)" \
    || { echo "Configure failed"; exit 1; }
# Note ffmpeg, libinotify removed

echo "Running make..."
make -j$(sysctl -n hw.logicalcpu) || { echo "Make failed"; exit 1; }

echo "Build completed successfully. ez"

DYLD_FALLBACK_LIBRARY_PATH="/usr/local/lib" ./wine notepad.exe
