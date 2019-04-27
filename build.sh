#!/usr/bin/env bash
set -e
BASE_PATH="$(cd "$(dirname "$0")" ; pwd -P)"

mkdir -p $BASE_PATH/_build $BASE_PATH/debs

function installMissing {
  stringarray=($1)
  export MISSING=""
  for dep in "${stringarray[@]}"; do
    if [ $(dpkg-query -W -f='${Status}' $dep 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
      MISSING+=" $dep"
    fi
  done
  if [ "$MISSING" != "" ]; then
    sudo apt install --yes $MISSING
  fi
}

function buildCadence {
  echo "- Running cadence build script..."
  BUILD_PATH=$BASE_PATH/_build/cadence
  REPO_PATH=$BUILD_PATH/cadence-git
  mkdir -p $BUILD_PATH

  echo "  - Installing missing dependencies..."
  BUILD_DEPS="debhelper fakeroot libdrm-dev libexpat1-dev libfreetype6-dev libglib2.0-dev libglvnd-core-dev libglvnd-dev libice-dev libpcre3-dev libpixman-1-dev libpng-dev libpthread-stubs0-dev libsm-dev libx11-xcb-dev libxau-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-shape0-dev libxcb-shm0-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb1-dev libxdamage-dev libxdmcp-dev libxext-dev libxfixes-dev libxrender-dev libxshmfence-dev libxxf86vm-dev libx11-dev libruby2.5 rake ruby-minitest ruby-net-telnet ruby-power-assert ruby-test-unit ruby-xmlrpc ruby2.5 rubygems-integration uuid-dev x11proto-core-dev x11proto-damage-dev x11proto-dev x11proto-fixes-dev x11proto-xext-dev x11proto-xf86vidmode-dev libglib2.0-dev-bin xtrans-dev portaudio19-dev libjack-jackd2-dev libfftw3-dev libxpm-dev libfltk1.3-dev liblash-compat-dev"
  installMissing "$BUILD_DEPS \
    fonts-lato libcairo-script-interpreter2 libfftw3-bin libfftw3-long3 libfftw3-quad3 libgles1 \
    liblash-compat-1debian0 libopengl0 libpcre16-3 libpcre32-3 libpng-tools python3-dbus.mainloop.pyqt5 \
  "

  echo "  - Cloning source code repository..."
  [ -e $REPO_PATH ] && rm -rf $REPO_PATH
  git clone https://github.com/falkTX/Cadence.git $REPO_PATH
  cd $REPO_PATH

  echo "  - Copying packaging files..."
  cp -pr  $BASE_PATH/cadence-debian ./debian

  echo "  - Patching packaging files to match git build..."
  CURRENTBUILDDATE=$(LANG=en_us_88591; date --utc '+%a, %d %b %Y %H:%M:%S %z')
  CURRENTDATE=$(LANG=en_us_88591; date +%Y%m%d)
  CURRENTGITHASH=$(git rev-parse --short=8 HEAD)
  sed -i "s/insertdate/$CURRENTDATE/g" debian/changelog
  sed -i "s/githash/$CURRENTGITHASH/g" debian/changelog
  sed -i "s/buildtimeanddate/$CURRENTBUILDDATE/g" debian/changelog

  echo "  - Please wait - building packages..."
  dpkg-buildpackage -uc -us -b

  echo "  - Copying built packages in safe location..."
  [ -e $BASE_PATH/debs/cadence ] && rm -rf $BASE_PATH/debs/cadence
  mkdir -p $BASE_PATH/debs/cadence
  cp $BUILD_PATH/*.deb $BASE_PATH/debs/cadence/

  echo "  - Installing cadence packages..."
  cd $BASE_PATH
  for pkg in cadence-data cadence-toolscatarina catia claudia cadence; do
    sudo dpkg -i $BASE_PATH/debs/cadence/${pkg}-git_*_*.deb
  done

  echo "  - Uninstalling build dependencies..."
  sudo apt remove --yes --purge $BUILD_DEPS
}

function buildZynfusion {
  echo "- Running Zyn-Fusion build script..."
  BUILD_PATH=$BASE_PATH/_build/zynfusion
  REPO_PATH=$BUILD_PATH/zynfusion-git
  mkdir -p $BUILD_PATH

  echo "  - Installing missing dependencies..."
  BUILD_DEPS="liblash-compat-dev pyqt5-dev-tools qt5-default qtbase5-dev"
  installMissing "$BUILD_DEPS \
    liblash-compat-1debian0 python3-pyqt5\
  "

  echo "  - Cloning source code repository..."
  [ -e $REPO_PATH ] && rm -rf $REPO_PATH
  git clone https://github.com/zynaddsubfx/zyn-fusion-build $REPO_PATH
  cd $REPO_PATH

  echo "  - Please wait - building packages..."
  sudo rm /usr/lib/lv2/ZynAddSubFX.lv2presets || true
  ruby build-linux.rb

  echo "  - Copying built packages in safe location..."
  cd $BUILD_PATH
  [ -e $BASE_PATH/debs/zynfusion ] && rm -rf $BASE_PATH/debs/zynfusion
  mkdir -p $BASE_PATH/debs/zynfusion
  cp $REPO_PATH/*.bz2 $BASE_PATH/debs/zynfusion/

  tmp=$(mktemp -d)
  tar -jxf $BASE_PATH/debs/zynfusion/zyn-fusion-linux-64bit-3.0.3-patch1-release.tar.bz2 -C $tmp
  ls $tmp
  cd $tmp/zyn-fusion
  sudo ./install-linux.sh
  rm -rf $tmp

  echo "  - Uninstalling build dependencies..."
  sudo apt remove --yes --purge $BUILD_DEPS
}

buildCadence
buildZynfusion
