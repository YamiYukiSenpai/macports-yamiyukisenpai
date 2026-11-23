# Private MacPorts port tree

My personal MacPorts ports for software that is either outdated or missing in the MacPorts tree. Ports here take precedence over official ports of the same name (see [Setup](#setup)).

## Ports

| Port | Notes |
|---|---|
| `kate`, `konsole` | KDE apps on Qt 6 / KDE Frameworks 6. Override the official KDE4-era 4.14.3 ports. |
| `markdownpart`, `breeze` | Supporting KDE components (Markdown preview for Kate, Breeze widget style and color schemes). |
| `kf6-*`, `kde-extra-cmake-modules` | KDE Frameworks 6, shared by the KDE apps. `kde-extra-cmake-modules` overrides the official 5.x port. |
| `sonora` | Native music streaming client, built from source. Shaders compile at launch by default; `+metal` precompiles them and needs Xcode's Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`). Cargo fetches its git-pinned dependencies during the build. |

## KDE ports

> [!WARNING]
> **The KDE ports deliberately break MacPorts policy and are not suitable for submission to `macports/macports-ports` as-is.** Use them at your own risk.
>
> Several KDE ports install symlinks **outside the MacPorts prefix**, in `/Library/Application Support/`:
>
> | Symlink | Points to | Installed by |
> |---|---|---|
> | `color-schemes` | `${prefix}/share/color-schemes` | `breeze` |
> | `locale` | `${prefix}/share/locale` | `kf6-ki18n` |
> | `kf6` | `${prefix}/share/kf6` | `kf6-kio` |
> | `knotifications6` | `${prefix}/share/knotifications6` | `kf6-knotifications` |
> | `katexmltools` | `${prefix}/share/katexmltools` | `kate` |
> | `kdevappwizard` | `${prefix}/share/kdevappwizard` | `kate` |
>
> **Why:** on macOS, Qt's `QStandardPaths::GenericDataLocation`, which KDE uses to find color schemes, translations, search providers and similar data, only searches `~/Library/Application Support` and `/Library/Application Support`. It never searches `${prefix}/share`. Without these links KDE apps lose their color schemes, translations and more. KDE's own macOS builds avoid this with a patched Qt; this tree uses the official, unpatched `qt6-*` binaries instead.
>
> **Side effects:**
> - The links are visible to *every* Qt/KDE app on the system, including other installs of KDE apps (Homebrew, KDE's DMGs), which will pick up MacPorts' color schemes and translations.
> - Installing fails if any of those names already exists in `/Library/Application Support/`. The links are removed when the owning port is deactivated.
>
> The mechanism is `kf6.link_appsupport` in `_resources/port1.0/group/kf6-1.0.tcl`. To make these ports upstreamable, replace it with patches that add `${prefix}/share` to the affected lookups.

Other KDE notes:

- `kate` registers as a recommended (not default) app for text files in Finder's "Open With" (`kde/kate/files/patch-bundle-plist.diff`).
- DBus, X11/Wayland and Linux-only features are disabled throughout.

## Setup

1. Clone this repo and copy it (without `.git`) to a root-owned location, e.g. `/opt/ports`. `sync-ports.sh` does this and runs `portindex`.
2. Add it to `/opt/local/etc/macports/sources.conf` **above** the default rsync line, so these ports override official ones of the same name:

   ```
   file:///opt/ports [nosync]
   rsync://rsync.macports.org/macports/release/tarballs/ports.tar.gz [default]
   ```

3. Bring official ports up to date first, as prebuilt binaries:

   ```
   port outdated
   sudo port upgrade outdated
   ```

   `-s` (build from source) applies to every port a command touches, including outdated official dependencies. Skipping this step means a later `port -s upgrade` can end up compiling Qt and other large ports from source.

4. Install a port, building the local ports from source:

   ```
   sudo port -vs install <port>
   ```

   Do not use trace mode (`-t`) on macOS 27+: `darwintrace.dylib` cannot load into Apple's arm64e system binaries.

## License

Portfiles, PortGroups and other original files are under the BSD 3-Clause license (see [LICENSE](LICENSE)), the same as the official MacPorts ports tree. Patches in `*/files/` modify upstream sources and fall under the respective upstream project's license.
