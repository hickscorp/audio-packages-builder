#!/usr/bin/env bash
set -e
BASE_PATH="$(cd "$(dirname "$0")" ; pwd -P)"
BUILD_PATH=$BASE_PATH/_build
mkdir -p $BUILD_PATH

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
  REPO_PATH=$BUILD_PATH/cadence

  echo "  - Installing missing dependencies..."
  BUILD_TOOLS="build-essential git libtool automake"
  BUILD_DEPS="qtbase5-dev pyqt5-dev-tools"
  DEPS="qt5-default python3-dbus.mainloop.pyqt5 python3-pyqt5.qtsvg ladish jack-capture"
  installMissing "$BUILD_TOOLS $BUILD_DEPS $DEPS"

  echo "  - Cloning source code repository..."
  [ -e $REPO_PATH ] && rm -rf $REPO_PATH
  git clone https://github.com/falkTX/Cadence.git $REPO_PATH
  cd $REPO_PATH

  echo "  - Building and installing Cadence binaries..."
  make && sudo make install

  echo "  - You might want to uninstall the following dev dependencies if you don't need them:"
  echo "    $BUILD_DEPS"
  echo "  - Cleaning up..."
}

function buildCarla {
  echo "- Running cadence build script..."
  REPO_PATH=$BUILD_PATH/carla

  echo "  - Installing missing dependencies..."
  BUILD_TOOLS="build-essential git libtool automake"
  BUILD_DEPS="libmagic-dev liblo-dev qtbase5-dev pyqt5-dev-tools libx11-dev libasound2-dev libpulse-dev libgtk2.0-dev libgtk-3-dev libqt4-dev libsndfile1-dev libfluidsynth-dev"
  DEPS="fluidsynth python3-rdflib qt5-default liblo7 python3-liblo"
  installMissing "$BUILD_TOOLS $BUILD_DEPS $DEPS"

  echo "  - Cloning source code repository..."
  [ -e $REPO_PATH ] && rm -rf $REPO_PATH
  git clone https://github.com/falkTX/Carla $REPO_PATH
  cd $REPO_PATH

  echo "  - Building and installing Carla binaries..."
  make && sudo make install

  echo "  - You might want to uninstall the following dev dependencies if you don't need them:"
  echo "    $BUILD_DEPS"
  echo "  - Cleaning up..."
}

function buildZynfusion {
  echo "- Running Zyn-Fusion build script..."
  REPO_PATH=$BUILD_PATH/zynfusion

  echo "  - Installing missing dependencies..."
  BUILD_TOOLS="build-essential git ruby libtool automake cmake bison cxxtest"
  BUILD_DEPS="libmxml-dev libfftw3-dev libjack-jackd2-dev liblo-dev libz-dev libasound2-dev mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev libcairo2-dev libfontconfig1-dev portaudio19-dev"
  DEPS="libmxml1 libjack-jackd2-0 libfftw3-long3 libfftw3-quad3 liblo7 libasound2 libgl1-mesa-glx libglu1-mesa libcairo2 libportaudio2"
  installMissing "$BUILD_TOOLS $BUILD_DEPS $DEPS"

  echo "  - Cloning source code repository..."
  [ -e $REPO_PATH ] && rm -rf $REPO_PATH
  git clone https://github.com/zynaddsubfx/zyn-fusion-build $REPO_PATH
  cd $REPO_PATH

  echo "  - Please wait - building Zyn-Fusion..."
  sudo rm /usr/lib/lv2/ZynAddSubFX.lv2presets || true
  ruby build-linux.rb

  echo "  - Copying built packages in safe location..."
  tmp=$(mktemp -d)
  tar -jxf $REPO_PATH/zyn-fusion-linux-64bit-3.0.3-patch1-release.tar.bz2 -C $tmp
  cd $tmp/zyn-fusion
  sudo ./install-linux.sh
  rm -rf $tmp

  echo "  - You might want to uninstall the following dev dependencies if you don't need them:"
  echo "    $BUILD_DEPS"
}

function buildWolfShaper() {
  echo "- Running Wolf-Shaper build script..."
  REPO_PATH=$BUILD_PATH/wolfshaper

  echo "  - Installing missing dependencies..."

  echo "  - Cloning source code repository..."
  [ -e $REPO_PATH ] && rm -rf $REPO_PATH
  git clone --recursive https://github.com/pdesaulniers/wolf-shaper.git $REPO_PATH
  cd $REPO_PATH

  echo "  - Please wait - building Wolf-Shaper..."
  BUILD_VST2=true BUILD_LV2=true BUILD_DSSI=true BUILD_JACK=true make

  echo "  - Build complete, installing..."
  sudo make install
}

function buildWolfSpectrum() {
  echo "- Running Wolf-Spectrum build script..."
  REPO_PATH=$BUILD_PATH/wolfspectrum

  echo "  - Installing missing dependencies..."

  echo "  - Cloning source code repository..."
  [ -e $REPO_PATH ] && rm -rf $REPO_PATH
  git clone --recursive https://github.com/pdesaulniers/wolf-spectrum.git $REPO_PATH
  cd $REPO_PATH

  echo "  - Please wait - building Wolf-Spectrum..."
   BUILD_VST2=true BUILD_LV2=true BUILD_JACK=true make

  echo "  - Build complete, installing..."
  sudo make install
}

for thing in $@; do
  case $thing in
    "cadence")
      buildCadence
      ;;
    "carla")
      buildCarla
      ;;
    "zynfusion")
      buildZynfusion
      ;;
    "wolfshaper")
      buildWolfShaper
      ;;
    "wolfspectrum")
      buildWolfSpectrum
      ;;
    *)
      echo "Unlnown build option $thing."
      ;;
  esac
done
rm -rf _build
