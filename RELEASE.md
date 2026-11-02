# QuickDrop v1.0.0 — Release Notes

**Release date:** 2 November 2026
**Version:** 1.0.0 (build 1)
**Platforms:** Android 7.0+ (API 24) · Linux desktop (x64)
**APK artifact:** `QuickDrop-1.0.0.apk`

---

## What QuickDrop is

QuickDrop moves photos, screenshots and arbitrary files directly between a phone and a
computer over the local network. There is no account, no cloud upload, no pairing dance
and no internet requirement. Both devices simply need to reach each other — normal Wi-Fi,
a phone hotspot, a USB tether or a Bluetooth tether all work.

This is the first public **1.0.0** build and the first release with the redesigned
three-tab interface.

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

### Linux integration

- Images save to `~/Pictures/Screenshots`; other files save to `~/Downloads/QuickDrop`.
- Clipboard copy supports **wl-copy** (Wayland), **xclip** and **xsel** (X11).
- Desktop notifications through `notify-send`.
- Open files and folders with `xdg-open`.
- `install_desktop_launcher.sh` installs an application-menu entry and icon.

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

1. Copy `QuickDrop-1.0.0.apk` to the phone, or install over USB:

   ```bash
   adb install -r QuickDrop-1.0.0.apk
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

Run the release bundle from a Flutter build, then optionally install the launcher:

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
| Linux desktop | x64 build of the Flutter Linux bundle |
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
- USB/Bluetooth links are detected and used, but the per-device link badge and the
  active-link diagnostics panel described in the design document are not exposed in this
  build.
- No resume or mid-transfer link migration. If a cable is unplugged or Wi-Fi drops, the
  in-flight file fails and must be retried.
- The Android receiver runs while the app is open; there is no background service.
- Linux Bluetooth PAN setup is operating-system work. The app can use `bnep0` once the
  PAN connection exists, but cannot create it.
- iOS, Windows and macOS builds are not part of this release.
- Browser uploads are intentionally limited to the local receiver page; there is no
  remote relay.

---

## Verification for this build

| Check | Result |
| --- | --- |
| `flutter analyze` | Clean (0 issues) |
| `flutter test` | 25 tests passing |
| Toolchain | Flutter 3.47.7 / Dart 3.13.5 |
| Build mode | `flutter build apk --release` |
| APK size | 53.9 MB (53,890,384 bytes) |
| APK SHA-256 | `4cf9f3cfcddee1bdde77ae8fce6f0682f42b6c415bbf8cbcdf5730db89345769` |

Verify the downloaded APK:

```bash
sha256sum QuickDrop-1.0.0.apk
```

---

## Upgrade notes

This is the first 1.0.0 build. If a debug build was installed previously, install over it
with `adb install -r`; app settings and transfer history are kept. If Android reports a
signature mismatch, uninstall the old build first — doing so clears local settings and
history.

---

## Release checklist

- [x] Code, assets and platform integrations committed
- [x] `flutter analyze` clean
- [x] All automated tests passing
- [x] Release APK built and copied to the repository root
- [ ] APK signed with a production keystore
- [ ] GitHub release created and APK attached
- [ ] Store listing and screenshots prepared

---

## Credits

Built with [Flutter](https://flutter.dev). UI typeface: [Inter](https://rsms.me/inter/),
licensed under the SIL Open Font License. QuickDrop is a local-first utility; please
report issues and include the Android version, desktop distribution and network setup.
