# QuickDrop v1.1.0 — Release Notes

**Release date:** 3 November 2026
**Version:** 1.1.0 (build 3)
**Platforms:** Android 7.0+ (API 24) · Linux desktop (x64) · Windows 10/11 (x64)
**APK artifact:** `release/QuickDrop-1.1.0.apk`
**Linux artifact:** `release/QuickDrop-1.1.0-linux-x64.tar.gz`
**Windows artifact:** `QuickDrop-1.1.0-windows-x64.zip` (built by GitHub Actions)

---

## What QuickDrop is

QuickDrop moves photos, screenshots and arbitrary files directly between a phone and a
computer over the local network. There is no account, no cloud upload, no pairing dance
and no internet requirement. Both devices simply need to reach each other — normal Wi-Fi,
a phone hotspot, a USB tether or a Bluetooth tether all work.

This release builds on the first public **1.0.0** build and completes the offline-link
experience: USB and Bluetooth tethering are now visible everywhere they matter, from the
device card to the transfer screen and the diagnostics panel.

---

## What's new in 1.1.0

### Link-aware device list

- Every nearby device now carries a small link chip: **USB**, **Bluetooth**, **Wi-Fi**,
  **Wired** or **Network**.
- Devices are ordered fastest link first, then by name, while manual IP peers stay at the
  bottom of the list.
- A device reachable over Wi-Fi and USB at the same time appears once, preferring USB.

### Clear transfer-path feedback

- The active transfer panel names the link in use: **Sending over USB**, **Finishing over
  Bluetooth** and so on.
- If a cable is unplugged or a tether is disabled mid-transfer, the failure explains what
  happened and how to recover instead of showing a generic socket error.

### `No Wi-Fi?` help and diagnostics

- The Receive tab has a **No Wi-Fi?** action with step-by-step USB and Bluetooth
  tethering instructions, a live list of detected interfaces, and an Android shortcut to
  tethering settings.
- Settings now includes an **ACTIVE LINKS** section showing each interface's link kind,
  name, IP and priority.

### In-app top notifications

- Completed sends and receives now announce themselves in a banner at the top of the app,
  so progress is visible from any tab.
- Files that arrive together are grouped into one banner instead of flashing once per
  file.
- **View** on a received-file banner opens **Transfers → Received**; sent-file banners
  open the **Sent** view.
- Every in-app status message now uses the same top banner instead of bottom snackbars.
- Linux desktop notifications are unchanged and still appear alongside the in-app banner.

### Windows desktop support

- QuickDrop now has a native Windows runner and ships as a portable x64 ZIP.
- Received images can be copied to the Windows clipboard and incoming files raise a
  native desktop notification.
- Open file, show-in-folder and browser links use the Windows shell, so file
  associations work the same as a double-click.
- Windows adapter names such as **Wi-Fi**, **Ethernet** and **Remote NDIS** are
  classified correctly, while Hyper-V, WSL and VMware adapters are ignored.
- A GitHub Actions workflow now builds the Linux tarball and the Windows ZIP for
  release tags and manual runs.

### Reliability

- Subnet probing now skips every local tether address, not only the primary Wi-Fi IP.
- Removed the temporary visual-test harness and its golden files.
- README documents USB and Bluetooth tethering setup and expected link behavior.

---

## Highlights

### A rebuilt, calmer interface

- New **Send / Receive / Transfers** layout that keeps the next action obvious.
- Responsive layout: a focused single column on phones and a two-column workspace on
  desktop.
- New light "Kinetic Transfer" theme, Inter typeface, custom app icon and refreshed
  empty states.
- Every long-running action now has a visible state: scanning, active transfer,
  completed, failed or canceled.

### Sending

- Nearby devices appear automatically on the Send tab.
- Select one device, then add **one or many files** before sending.
- Drag and drop files straight onto the desktop window.
- Pick files with the system picker or go straight to Photos for images.
- Live progress with per-file status, transfer speed, elapsed time and ETA.
- Cancel an in-flight transfer without leaving the screen.
- A result summary shows what was delivered, what failed, total size and duration.
- **Connect by IP** for networks that block discovery, with remembered manual peers.

### Receiving

- The HTTP receiver is always on while QuickDrop is running.
- A browser-based receiver at `http://<device-ip>:53318/web` lets a device send files
  **without installing QuickDrop**.
- The Receive tab shows the exact URL and a QR code to open it instantly.
- Received files land in a predictable folder and can be opened from the app.
- Copy received images to the desktop clipboard automatically.
- Native desktop notifications for incoming files.

### Transfers

- Persistent history of sent and received files, grouped into Today, Yesterday and
  Earlier.
- Filter by **All / Sent / Received**.
- Reopen, reveal or clear history entries.
- Long-press or use the item menu to inspect file details.

### Android integration

- QuickDrop appears in the **Android share sheet** for single and multiple files, so a
  screenshot can go from the preview banner to the laptop in a few taps.
- Received files are published to the public **`Download/QuickDrop`** folder through
  MediaStore on Android 10+. On Android 7–9 the file is written directly to public
  Downloads when storage permission allows; otherwise it remains in the app's external
  files folder.
- Received files can be opened in place through a MediaStore content URI, or a
  FileProvider URI for app-private files.
- Shortcuts for Wi-Fi, hotspot/tethering and Downloads settings.

### Desktop integration

- On Linux, images save to `~/Pictures/Screenshots` and other files to
  `~/Downloads/QuickDrop`. On Windows, everything saves to
  `%USERPROFILE%\Downloads\QuickDrop`.
- Linux clipboard copy supports **wl-copy** (Wayland), **xclip** and **xsel** (X11).
  Windows clipboard copy uses the native .NET clipboard API.
- Desktop notifications use `notify-send` on Linux and a native tray notification on
  Windows.
- Files, folders and URLs open through `xdg-open` on Linux and the Windows shell on
  Windows.
- `install_desktop_launcher.sh` installs an application-menu entry and icon on Linux;
  the Windows ZIP is portable and runs directly from its extracted folder.

### Offline link layer

- Detects Wi-Fi, Ethernet, USB tether (`usb0` / `rndis0`) and Bluetooth tether
  (`bnep0` / `bt-pan`) interfaces.
- Discovery advertises on every active subnet, not just the primary Wi-Fi address, and
  falls back to a parallel HTTP probe when a driver drops broadcast packets.
- The same device seen over two links is merged into one peer, preferring the faster
  link.
- Works with Wi-Fi off when USB or Bluetooth tethering is enabled by the user.

### Reliability and discovery

- UDP discovery on port **53317** (broadcast + multicast).
- HTTP transfers on port **53318**.
- Subnet scan fallback for routers, hotspots and Android devices that block discovery
  packets.
- Manual peer addresses survive restarts.
- Legacy `adb reverse` and `127.0.0.1` connection paths remain available for development.

---

## Installation

### Android (sideload)

1. Copy `release/QuickDrop-1.1.0.apk` to the phone, or install over USB:

   ```bash
   adb install -r release/QuickDrop-1.1.0.apk
   ```

2. If installing from the phone's file manager, allow **Install unknown apps** for that
   file manager when prompted.
3. Open QuickDrop once so the receiver starts.
4. Share a screenshot or file to QuickDrop from any app's share sheet, or use the
   **Send** tab inside the app.

> The APK in this release is signed with the local debug keystore so it can be installed
> and tested. Replace the signing config with a private release keystore before
> publishing to a store.

### Linux desktop

Download `release/QuickDrop-1.1.0-linux-x64.tar.gz`, then either run it directly:

```bash
tar -xzf QuickDrop-1.1.0-linux-x64.tar.gz
cd QuickDrop-1.1.0-linux-x64
./quickdrop
```

Or install it into your application menu:

```bash
./install.sh
```

The installer copies the app to `~/.local/opt/quickdrop` and adds a launcher and
icon for the current user. To build from source instead:

```bash
flutter build linux --release
./build/linux/x64/release/bundle/quickdrop
./install_desktop_launcher.sh
```

For untethered Wi-Fi discovery, allow the two ports through the firewall once:

```bash
sudo ufw allow 53318/tcp
sudo ufw allow 53317/udp
```

### Windows desktop

Download `QuickDrop-1.1.0-windows-x64.zip`, then extract the whole folder and run:

```powershell
Expand-Archive QuickDrop-1.1.0-windows-x64.zip -DestinationPath .
.\QuickDrop-1.1.0-windows-x64\quickdrop.exe
```

Keep `quickdrop.exe`, the DLLs and the `data` folder together. The build is portable
and has no installer. Windows may show a SmartScreen warning because the executable is
not code-signed; choose **More info → Run anyway** after verifying the SHA-256 hash.

When Windows Defender Firewall prompts, allow QuickDrop on **Private networks**. If the
prompt was dismissed, allow the app for TCP `53318` and UDP `53317` in Windows Defender
Firewall.

To build from source on Windows:

```powershell
flutter build windows --release
.\tool\package_windows.ps1
```

### Browser receiver

With QuickDrop open on the receiving device, open the URL shown on the Receive tab:

```text
http://<receiver-ip>:53318/web
```

or scan the QR code. The sender does not need QuickDrop installed.

---

## Requirements

| Item | Requirement |
| --- | --- |
| Android | 7.0 (API 24) or newer |
| Linux desktop | x64 with GTK 3 |
| Windows desktop | Windows 10 or 11, x64 |
| Windows runtime | Microsoft Visual C++ 2015-2022 Redistributable (x64) |
| Network | Both devices on the same LAN, hotspot or tether |
| Ports | UDP 53317 for discovery, TCP 53318 for transfers |
| Internet | Not required |

Wi-Fi, USB tethering and Bluetooth tethering are enabled by the user in the operating
system. QuickDrop detects the resulting interfaces but does not toggle tethering itself.

---

## Privacy and security

- Files travel directly between the two devices. Nothing is uploaded to a server and
  there is no telemetry or account system.
- Transfers are **not encrypted** and there is **no authentication**. Anyone who can
  reach the receiver URL on the same network can send a file, and anyone who knows the
  URL can open the browser receiver.
- Use QuickDrop on networks you trust. Do not expose ports 53317/53318 to the public
  internet.

---

## Known limitations

- The APK uses the debug signing key; a production release keystore is still required.
- No transport encryption or peer authentication yet.
- USB/Bluetooth links are detected and used automatically once the operating system
  enables tethering; the app does not toggle tethering itself.
- No resume or mid-transfer link migration. If a cable is unplugged or Wi-Fi drops, the
  in-flight file fails with a link-specific message and must be retried.
- The Android receiver runs while the app is open; there is no background service.
- Linux Bluetooth PAN setup is operating-system work. The app can use `bnep0` once the
  PAN connection exists, but cannot create it.
- iOS and macOS builds are not part of this release.
- The Windows ZIP is unsigned, so SmartScreen may warn on first launch.
- Windows Bluetooth PAN setup is operating-system work, as it is on Linux.
- Browser uploads are intentionally limited to the local receiver page; there is no
  remote relay.

---

## Verification for this build

| Check | Result |
| --- | --- |
| `flutter analyze` | Clean (0 issues) |
| `flutter test` | 45 tests passing |
| Toolchain | Flutter 3.47.7 / Dart 3.13.5 |
| Build mode | `flutter build apk --release` and `flutter build linux --release` |
| Windows build | `flutter build windows --release` on GitHub Actions `windows-latest` |
| APK size | 53.7 MB (53,726,752 bytes) |
| APK SHA-256 | `7645639ec1751a1bf09c3fc5d8b23ba6146e7633884e72598f9b539a28d352d3` |
| Linux bundle SHA-256 | Attached as `QuickDrop-1.1.0-linux-x64.tar.gz.sha256` |
| Windows bundle SHA-256 | Attached as `QuickDrop-1.1.0-windows-x64.zip.sha256` |

Verify the downloaded files:

```bash
sha256sum release/QuickDrop-1.1.0.apk
sha256sum -c QuickDrop-1.1.0-linux-x64.tar.gz.sha256
```

On Windows, compare the output of this command with the adjacent `.sha256` file:

```powershell
Get-FileHash QuickDrop-1.1.0-windows-x64.zip -Algorithm SHA256
```

The desktop archives are built in CI, so each release attaches its own `.sha256` file
next to the archive. The APK hash is also listed in `release/SHA256SUMS`.

---

## Upgrade notes

This release installs over 1.0.0 with `adb install -r`; app settings and transfer history
are kept. The link UI requires no new permissions and no changes to the transfer protocol,
so 1.1.0 can exchange files with 1.0.0 devices. If Android reports a signature mismatch,
uninstall the old build first — doing so clears local settings and history.

---

## Release checklist

- [x] Code, assets and platform integrations committed
- [x] `flutter analyze` clean
- [x] All automated tests passing
- [x] Release APK built and copied to `release/`
- [x] Linux x64 bundle packaged in `release/`
- [x] Windows runner and desktop integrations added
- [x] GitHub Actions workflow builds Linux and Windows artifacts
- [ ] APK signed with a production keystore
- [x] GitHub release created and APK attached
- [x] Windows ZIP built and attached by the release workflow
- [ ] Store listing and screenshots prepared

---

## Credits

Built with [Flutter](https://flutter.dev). UI typeface: [Inter](https://rsms.me/inter/),
licensed under the SIL Open Font License. QuickDrop is a local-first utility; please
report issues and include the Android version, desktop distribution and network setup.
