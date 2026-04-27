#!/bin/sh
# build.sh  –  Configure, build, and optionally install AetherDE
# Usage: ./build.sh [--prefix PREFIX] [--build-type TYPE] [--install] [--jobs N]
# SPDX-License-Identifier: MIT

set -e

##############################################################################
# Defaults
##############################################################################
PREFIX="/usr/local"
BUILD_TYPE="Release"
DO_INSTALL=0
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
BUILD_DIR="build"

##############################################################################
# Parse arguments
##############################################################################
while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)      PREFIX="$2";     shift 2 ;;
        --build-type)  BUILD_TYPE="$2"; shift 2 ;;
        --install)     DO_INSTALL=1;    shift   ;;
        --jobs|-j)     JOBS="$2";       shift 2 ;;
        --clean)       rm -rf "$BUILD_DIR"; shift ;;
        --help|-h)
            echo "Usage: $0 [--prefix PREFIX] [--build-type Release|Debug|RelWithDebInfo]"
            echo "          [--install] [--jobs N] [--clean]"
            exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

##############################################################################
# Detect OS
##############################################################################
OS=$(uname -s)
echo "==> AetherDE build  OS=${OS}  BUILD_TYPE=${BUILD_TYPE}  PREFIX=${PREFIX}"

##############################################################################
# Dependency check
##############################################################################
check_dep() {
    if ! pkg-config --exists "$1" 2>/dev/null; then
        echo "ERROR: pkg-config module '$1' not found."
        echo "       Install the development package for: $1"
        MISSING=1
    fi
}

MISSING=0
check_dep wayland-server
check_dep wayland-client
check_dep wayland-protocols
check_dep xkbcommon
check_dep libinput
check_dep libdrm
check_dep egl

if [ "$MISSING" = "1" ]; then
    echo ""
    echo "Missing dependencies detected.  On:"
    echo "  FreeBSD: pkg install qt6-base qt6-wayland qt6-declarative"
    echo "                       wayland wayland-protocols libinput"
    echo "                       libxkbcommon mesa-libs libdrm"
    echo ""
    echo "  Debian/Ubuntu: apt install qt6-base-dev qt6-wayland-dev"
    echo "                             qt6-declarative-dev libwayland-dev"
    echo "                             wayland-protocols libxkbcommon-dev"
    echo "                             libinput-dev libudev-dev libdrm-dev"
    echo "                             libegl-dev libgles2-mesa-dev libpam0g-dev"
    echo ""
    echo "  Fedora/RHEL:   dnf install qt6-qtbase-devel qt6-qtwayland-devel"
    echo "                             qt6-qtdeclarative-devel wayland-devel"
    echo "                             wayland-protocols-devel libxkbcommon-devel"
    echo "                             libinput-devel systemd-devel libdrm-devel"
    echo "                             mesa-libEGL-devel pam-devel"
    exit 1
fi

##############################################################################
# CMake configure
##############################################################################
mkdir -p "$BUILD_DIR"
cmake -S . -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

##############################################################################
# Build
##############################################################################
cmake --build "$BUILD_DIR" --parallel "$JOBS"

echo ""
echo "==> Build successful."

##############################################################################
# Install (optional)
##############################################################################
if [ "$DO_INSTALL" = "1" ]; then
    echo "==> Installing to ${PREFIX} ..."
    cmake --install "$BUILD_DIR"
    echo "==> Installation complete."
    echo ""
    echo "    To start AetherDE, select 'AetherDE (Wayland)' in your"
    echo "    display manager, or run:  aether-session"
fi
