cmake_minimum_required(VERSION 3.22)
project(AetherDE VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ── Qt6 ────────────────────────────────────────────────────────────────────────
find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Qml
    Quick
    QuickControls2
    WaylandCompositor
    WaylandClient
    DBus
)

qt_standard_project_setup()

# ── System dependencies ────────────────────────────────────────────────────────
find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND_SERVER  REQUIRED wayland-server>=1.21)
pkg_check_modules(WAYLAND_CLIENT  REQUIRED wayland-client>=1.21)
pkg_check_modules(WAYLAND_SCANNER REQUIRED wayland-scanner)
pkg_check_modules(WAYLAND_PROTOS  REQUIRED wayland-protocols>=1.31)
pkg_check_modules(XKBCOMMON       REQUIRED xkbcommon>=1.5)
pkg_check_modules(LIBINPUT        REQUIRED libinput>=1.22)
pkg_check_modules(UDEV            REQUIRED libudev)
pkg_check_modules(DRM             REQUIRED libdrm)
pkg_check_modules(EGL             REQUIRED egl)
pkg_check_modules(GLESV2          REQUIRED glesv2)

# ── wayland-scanner helper ─────────────────────────────────────────────────────
include(cmake/WaylandScanner.cmake)

# ── Wayland protocols data dir ─────────────────────────────────────────────────
execute_process(
    COMMAND ${PKG_CONFIG_EXECUTABLE} --variable=pkgdatadir wayland-protocols
    OUTPUT_VARIABLE WL_PROTOCOLS_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(WL_PROTOCOLS_DIR "${WL_PROTOCOLS_DIR}" CACHE PATH "wayland-protocols data dir")

# ── Install paths ──────────────────────────────────────────────────────────────
include(GNUInstallDirs)
set(AETHER_DATADIR   "${CMAKE_INSTALL_FULL_DATADIR}/aetherde")
set(AETHER_SYSCONFDIR "${CMAKE_INSTALL_FULL_SYSCONFDIR}/aetherde")

add_compile_definitions(
    AETHER_VERSION="${PROJECT_VERSION}"
    AETHER_DATADIR="${AETHER_DATADIR}"
    AETHER_SYSCONFDIR="${AETHER_SYSCONFDIR}"
)

# ── Sub-projects ───────────────────────────────────────────────────────────────
add_subdirectory(protocols)
add_subdirectory(shared)
add_subdirectory(compositor)
add_subdirectory(shell)
add_subdirectory(session)
add_subdirectory(data)

# ── CPack packaging ────────────────────────────────────────────────────────────
set(CPACK_PACKAGE_NAME            "AetherDE")
set(CPACK_PACKAGE_VENDOR          "AetherDE Project")
set(CPACK_PACKAGE_VERSION         "${PROJECT_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "AetherDE Qt6/Wayland Desktop Environment")
set(CPACK_GENERATOR               "TGZ;DEB;RPM")
set(CPACK_DEBIAN_PACKAGE_DEPENDS
    "libqt6waylandclient6, libqt6waylandcompositor6, libqt6qml6, "
    "libqt6quick6, libwayland-client0, libwayland-server0, "
    "libinput10, libxkbcommon0, libudev1, libegl1")
set(CPACK_RPM_PACKAGE_REQUIRES
    "qt6-qtwayland, wayland, libinput, libxkbcommon, systemd-libs, mesa-libEGL")
include(CPack)
