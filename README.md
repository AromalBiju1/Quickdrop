# QuickDrop ⚡📸

<p align="center">
  <img src="assets/images/quickdrop_logo.png" alt="QuickDrop logo" width="240">
</p>

> **Zero-Friction Phone-to-Computer Screenshot & Photo Transfer**<br>
> Direct peer-to-peer Wi-Fi streaming to Linux or Windows with zero cloud, zero social media, and zero USB/Bluetooth pairing hassle.

**Latest release:** [v1.1.0 — release notes](release/RELEASE.md)

---

## ✨ Highlights

- **Three-Tab Workflow:** Send, Receive and Transfers, with a nearby-device picker, drag-and-drop, live progress/ETA, and a persistent transfer history.
- **Top In-App Notifications:** Completed sends and receives slide in above every screen, group multi-file arrivals into one banner, and jump straight to the matching transfer history.
- **Linux & Windows Desktop Receivers:** Ready-to-run desktop builds receive files from Android and expose the QR/browser receiver.
- **QR Browser Receiver:** Scan the QR code on the Receive tab and send from any browser — no app needed on the sending device.
- **Instant Android Share Sheet Integration:** Snap a screenshot on your phone, tap **Share** on the preview banner, choose **QuickDrop**, and beam it directly to your computer in under 150ms.
- **Zero-Touch Auto-Clipboard:** Received images are immediately copied to the desktop clipboard on Linux (`wl-copy` / `xclip` / `xsel`) and Windows, with a native desktop notification. Just press `Ctrl+V` to paste anywhere.
- **Zero-Config UDP Discovery:** Devices discover each other automatically over local Wi-Fi / Hotspot on port `53317`.
- **Offline Link Detection:** USB and Bluetooth tethering interfaces are detected and used automatically, so transfers still work with Wi-Fi off.
- **Pure Dart Embedded HTTP Engine:** High-speed streaming on port `53318` without heavy third-party native C-libraries or WebRTC dependencies.
- **ADB Reverse Tunnel Fallback:** When plugged into USB or wireless ADB, automatically routes via tunnel for instant sub-millisecond drops.
- **Web Browser Fallback:** Built-in web uploader (`http://<ip>:53318/web`) allows transferring photos from any browser without installing software.

---

## 🛠️ Desktop Setup & Firewall

Download the desktop build from the [latest release](https://github.com/AromalBiju1/Quickdrop/releases/latest).
Allow incoming connections once if your firewall blocks local discovery or transfers.

**Linux**
```bash
sudo ufw allow 53318/tcp && sudo ufw allow 53317/udp
```

**Windows:** allow QuickDrop on **Private networks** when Windows Defender Firewall
prompts, or add inbound rules for TCP `53318` and UDP `53317`.

### Run Linux Desktop Receiver
```bash
tar -xzf QuickDrop-1.1.0-linux-x64.tar.gz
cd QuickDrop-1.1.0-linux-x64
./quickdrop
# Optional application-menu install:
./install.sh
```

To build from source:
```bash
flutter run -d linux
# Or run the compiled release bundle:
./build/linux/x64/release/bundle/quickdrop
```

### Run Windows Desktop Receiver
```powershell
Expand-Archive QuickDrop-1.1.0-windows-x64.zip -DestinationPath .
.\QuickDrop-1.1.0-windows-x64\quickdrop.exe
```

Keep `quickdrop.exe`, the DLLs, and the `data` folder together. The ZIP is portable
and unsigned, so Windows may show a SmartScreen warning on first launch.

To build from source on Windows:
```powershell
flutter build windows --release
.\tool\package_windows.ps1
```

---

## 🔌 USB & Bluetooth Tethering

QuickDrop still uses the same local HTTP transfer engine when there is no
Wi-Fi network. The operating system carries the traffic; the app detects the
new interface and labels it.

**USB tethering**
1. Connect the phone to the computer with a USB cable.
2. On Android, open **Settings → Hotspot & tethering** and enable **USB
   tethering**.
3. Linux normally creates `usb0` or `rndis0`; Windows creates a **Remote NDIS**
   adapter. The device card shows a `USB` chip and the Settings dialog lists the
   link under **ACTIVE LINKS**.

**Bluetooth tethering**
1. Pair the phone and computer once in their Bluetooth settings.
2. On Android, enable **Bluetooth tethering**.
3. Connect the phone's network in Linux Bluetooth/NetworkManager or Windows
   Bluetooth settings. QuickDrop shows the link as `Bluetooth` (often `bnep0`
   on Linux or **Bluetooth Network Connection** on Windows).

Open **Receive → No Wi-Fi?** for the same steps and a live list of detected
interfaces. If a tether is unplugged or disabled mid-transfer, QuickDrop stops
with a link-specific message and leaves no partial file behind. No internet
connection is used in any of these modes.

---

## 📱 Android Build & Install

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

A ready-to-sideload build is placed in `release/QuickDrop-1.1.0.apk`.
A Linux x64 bundle is in `release/QuickDrop-1.1.0-linux-x64.tar.gz`; the
Windows x64 ZIP is built by GitHub Actions because Flutter cannot cross-build
Windows from Linux. The workflow at
[`.github/workflows/desktop-release.yml`](.github/workflows/desktop-release.yml)
builds both desktop artifacts for tags and manual runs.

See [release/RELEASE.md](release/RELEASE.md) for the full release notes,
installation steps, checksums and known limitations.
