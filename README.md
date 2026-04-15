# AetherDE

**A native Qt6/Wayland desktop environment for FreeBSD and Linux.**

AetherDE is built entirely on Qt6 and the Wayland protocol stack.  There is
no X11 dependency.  Every pixel is rendered through OpenGL ES 2 / EGL over
the native DRM/KMS backend (or whatever the system EGL platform provides).

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                          aether-session                              │
│  PAM login · env setup · D-Bus · logind · process watchdog          │
└───────────────┬──────────────────────────┬───────────────────────────┘
                │ fork                     │ fork
                ▼                          ▼
┌──────────────────────────┐  ┌────────────────────────────────────────┐
│    aether-compositor     │  │            aether-shell                │
│                          │  │  (Wayland client of the compositor)    │
│  Qt6 WaylandCompositor   │  │                                        │
│  xdg-shell v6            │  │  Panel (wlr-layer-shell TOP)           │
│  wlr-layer-shell v4      │  │  ├ Launcher (app grid + search)        │
│  presentation-time       │  │  ├ Taskbar  (per-window buttons)       │
│  xdg-output v3           │  │  ├ System Tray (SNI spec)              │
│                          │  │  ├ Status area (vol/net/bat)           │
│  libinput seat           │  │  └ Clock + notification badge          │
│  xkbcommon keyboard      │  │                                        │
│  DRM / EGL output        │  │  Wallpaper (layer-shell BACKGROUND)    │
│  Multi-monitor arrange   │  │  Notification toasts (OVERLAY)         │
│  Window decorations QML  │  │  Notification center (slide-in)        │
│  Keybinding dispatch     │  │                                        │
└──────────────────────────┘  │  D-Bus: org.freedesktop.Notifications  │
                               │          org.kde.StatusNotifierWatcher │
                               │          org.AetherDE.Shell            │
                               └────────────────────────────────────────┘
```

### Component summary

| Binary | Role | Key Qt6 module |
|--------|------|----------------|
| `aether-compositor` | Wayland compositor + window manager | `Qt6::WaylandCompositor` |
| `aether-shell` | Desktop shell (panel, launcher, notifications, tray, wallpaper) | `Qt6::WaylandClient` |
| `aether-session` | Session lifecycle, PAM, logind, process watchdog | `Qt6::Core` + `Qt6::DBus` |

---

## Directory structure

```
aetherde/
├── CMakeLists.txt            root build
├── build.sh                  convenience build/install script
├── cmake/
│   └── WaylandScanner.cmake  wayland-scanner integration helper
├── protocols/
│   ├── CMakeLists.txt
│   └── wlr-layer-shell-unstable-v1.xml
├── shared/
│   ├── configmanager.{h,cpp}     INI config + live reload
│   └── keybindingmanager.{h,cpp} keybinding parser + dispatcher
├── compositor/
│   ├── main.cpp
│   ├── compositor.{h,cpp}        QWaylandCompositor subclass
│   ├── xdgview.{h,cpp}           one instance per xdg-toplevel window
│   ├── output.{h,cpp}            per-screen QWaylandOutput wrapper
│   ├── layershell.{h,cpp}        wlr-layer-shell server + box-model arranger
│   ├── inputmanager.{h,cpp}      libinput + xkbcommon seat
│   └── qml/
│       ├── compositor.qml        render scene root
│       ├── XdgToplevelChrome.qml window chrome (title bar, buttons, resize)
│       ├── WindowButton.qml      min/max/close buttons
│       └── ResizeHandle.qml      drag-to-resize edges
├── shell/
│   ├── main.cpp
│   ├── shellwindow.{h,cpp}       wlr-layer-shell client surface (native Wayland)
│   ├── shellquickwindow.{h,cpp}  QQuickWindow + layer-shell (QML-registerable)
│   ├── desktopmodel.{h,cpp}      XDG .desktop file parser + QAbstractListModel
│   ├── notificationmanager.{h,cpp} org.freedesktop.Notifications daemon
│   ├── systraymanager.{h,cpp}    org.kde.StatusNotifierWatcher + host
│   ├── wallpapermanager.{h,cpp}  wallpaper + slideshow engine
│   ├── dbus/
│   │   └── shelldbusadaptor.{h,cpp} org.AetherDE.Shell
│   └── qml/
│       ├── shell.qml             root, mounts all windows
│       ├── LayerWindow.qml       QML wrapper for ShellQuickWindow
│       ├── Panel.qml             top bar
│       ├── PanelButton.qml       reusable panel button
│       ├── PanelSeparator.qml    thin vertical rule
│       ├── Clock.qml             time + date tooltip
│       ├── Taskbar.qml           running window list
│       ├── TaskButton.qml        single window button
│       ├── SystemTray.qml        SNI icon row
│       ├── StatusArea.qml        volume / network / battery
│       ├── NotificationBadge.qml count badge + click
│       ├── LauncherPopup.qml     app grid + search + power actions
│       ├── AppDelegate.qml       single app icon tile
│       ├── NotificationOverlay.qml toast stack
│       ├── ToastItem.qml         animated notification card
│       ├── NotificationCenter.qml slide-in all-notifications list
│       └── WallpaperView.qml     background layer image + gradient
├── session/
│   ├── main.cpp
│   └── sessionmanager.{h,cpp}    process watchdog + PAM + logind + D-Bus
├── data/
│   ├── config/
│   │   ├── compositor.conf       default compositor settings
│   │   ├── shell.conf            default shell settings
│   │   └── keybindings.conf      default keybindings
│   ├── wayland-sessions/aetherde.desktop
│   ├── xsessions/aetherde.desktop
│   └── pam/aetherde              PAM service file (Linux)
└── pkg/
    ├── freebsd/Makefile          FreeBSD ports framework
    └── debian/control            Debian package metadata
```

---

## Building

### Prerequisites

**All platforms**
- CMake ≥ 3.22
- Qt 6.5+ (`Core Gui Widgets Qml Quick QuickControls2 WaylandCompositor WaylandClient DBus`)
- wayland ≥ 1.21 (server + client)
- wayland-protocols ≥ 1.31
- wayland-scanner
- xkbcommon ≥ 1.5
- libinput ≥ 1.22
- libdrm, EGL, GLESv2

**Linux only**
- libudev
- libpam (optional; greeter usually handles auth before the session starts)

#### FreeBSD

```sh
pkg install cmake ninja pkgconf \
    qt6-base qt6-wayland qt6-declarative qt6-quickcontrols2 \
    wayland wayland-protocols libinput libxkbcommon \
    mesa-libs libdrm dbus
```

#### Debian / Ubuntu 24.04+

```sh
apt install cmake ninja-build pkg-config \
    qt6-base-dev qt6-wayland-dev qt6-declarative-dev \
    libqt6waylandclient6-dev libqt6waylandcompositor6-dev \
    libwayland-dev wayland-protocols \
    libxkbcommon-dev libinput-dev libudev-dev \
    libdrm-dev libegl-dev libgles2-mesa-dev libpam0g-dev
```

#### Fedora / RHEL 9+

```sh
dnf install cmake ninja-build pkgconfig \
    qt6-qtbase-devel qt6-qtwayland-devel qt6-qtdeclarative-devel \
    wayland-devel wayland-protocols-devel \
    libxkbcommon-devel libinput-devel systemd-devel \
    libdrm-devel mesa-libEGL-devel pam-devel
```

### Compile & install

```sh
# Quick build in release mode
./build.sh --prefix /usr/local --install

# Manual CMake workflow
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build --parallel $(nproc)
cmake --install build
```

---

## Running

### From a display manager (recommended)

After installing, `aetherde.desktop` is placed in `/usr/local/share/wayland-sessions/`.
Select **AetherDE (Wayland)** in SDDM, GDM, or LightDM at the login screen.

### From a TTY (no display manager)

```sh
# Ensure XDG_RUNTIME_DIR exists
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"

# Start the session manager (launches compositor + shell automatically)
exec aether-session --vt 1
```

### Development run (compositor only, inside an existing Wayland session)

```sh
# Nested compositor for testing – renders into a window
export QT_QPA_PLATFORM=xcb    # or wayland
aether-compositor --socket wayland-aether &
export WAYLAND_DISPLAY=wayland-aether
aether-shell &
```

---

## Configuration

All config files live in `$XDG_CONFIG_HOME/aetherde/` (default `~/.config/aetherde/`).
Defaults are copied from `/etc/aetherde/` (or `/usr/local/etc/aetherde/` on FreeBSD)
on first run.

| File | Purpose |
|------|---------|
| `compositor.conf` | Wayland socket, VSync, input settings, XKB layout, per-output scale |
| `shell.conf` | Panel, wallpaper, launcher columns, theme accent colour |
| `keybindings.conf` | All keyboard shortcuts |

All files support **live-reload** — edit and save; changes take effect immediately
without restarting.

---

## Implemented Wayland protocols

| Protocol | Role | Side |
|----------|------|------|
| `xdg-shell v6` | Application windows (toplevel + popup) | server + client |
| `wlr-layer-shell-unstable-v1 v4` | Panel, wallpaper, lock screen surfaces | server + client |
| `xdg-output-unstable-v1 v3` | Multi-monitor layout | server + client |
| `wp-presentation-time` | Frame timing | server |
| `wl-seat` | Unified pointer/keyboard/touch seat | server |

---

## D-Bus services

| Service name | Object path | Interface | Provided by |
|---|---|---|---|
| `org.freedesktop.Notifications` | `/org/freedesktop/Notifications` | FDO Notifications v1.2 | `aether-shell` |
| `org.kde.StatusNotifierWatcher` | `/StatusNotifierWatcher` | KDE SNI Watcher | `aether-shell` |
| `org.AetherDE.Shell` | `/org/AetherDE/Shell` | Window list, launch, lock | `aether-shell` |
| `org.AetherDE.Session` | `/org/AetherDE/Session` | Logout, shutdown, reboot | `aether-session` |

---

## Default keybindings (excerpt)

| Shortcut | Action |
|---|---|
| `Super + Return` | Open terminal (foot) |
| `Super + Space` | Toggle application launcher |
| `Super + Q` / `Alt+F4` | Close window |
| `Super + F` | Toggle fullscreen |
| `Super + M` | Toggle maximise |
| `Super + N / H` | Minimise window |
| `Super + ←/→/↑/↓` | Snap window to half/quarter |
| `Alt + Tab` | Cycle windows |
| `Super + 1–5` | Switch to workspace N |
| `Super + L` | Lock screen |
| `Print` | Screenshot |
| `Super + Shift + E` | Log out |

All bindings are fully customisable in `keybindings.conf`.

---

## Roadmap

- [ ] Virtual desktop (workspace) manager with animations
- [ ] HiDPI fractional scaling via `wp-fractional-scale-v1`
- [ ] Screen capture via `wlr-screencopy-v1`
- [ ] Screen sharing / remote desktop via `xdg-desktop-portal-wlr`
- [ ] Lock screen (layer OVERLAY + PAM re-authentication)
- [ ] Settings application (Qt Widgets / QML)
- [ ] Bluetooth quick-settings via bluez D-Bus
- [ ] Network manager applet (NM D-Bus)
- [ ] PipeWire / PulseAudio volume control
- [ ] UPower battery widget
- [ ] Wayland IME (`text-input-v3`)
- [ ] Vulkan renderer backend
- [ ] FreeBSD port submission to ports tree

---

## License

MIT — see [LICENSE](LICENSE) for the full text.
