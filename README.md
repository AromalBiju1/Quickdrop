# QuickDrop ⚡📸

<p align="center">
  <img src="assets/images/quickdrop_logo.png" alt="QuickDrop logo" width="240">
</p>

> **Zero-Friction Phone-to-Laptop Screenshot & Photo Transfer**  
> Direct peer-to-peer Wi-Fi streaming with zero cloud, zero social media, and zero USB/Bluetooth pairing hassle.

**Latest release:** [v1.1.0 — release notes](release/RELEASE.md)

---

## ✨ Highlights

- **Three-Tab Workflow:** Send, Receive and Transfers, with a nearby-device picker, drag-and-drop, live progress/ETA, and a persistent transfer history.
- **QR Browser Receiver:** Scan the QR code on the Receive tab and send from any browser — no app needed on the other device.
- **Instant Android Share Sheet Integration:** Snap a screenshot on your phone, tap **Share** on the preview banner, choose **QuickDrop**, and beam it directly to your laptop in under 150ms.
- **Zero-Touch Auto-Clipboard on Linux:** Received screenshots automatically save to `~/Pictures/Screenshots/` and are immediately copied to your system clipboard (`wl-copy` / `xclip`) with a native desktop notification. Just press `Ctrl+V` to paste anywhere.
- **Zero-Config UDP Discovery:** Devices discover each other automatically over local Wi-Fi / Hotspot on port `53317`.
- **Offline Link Detection:** USB and Bluetooth tethering interfaces are detected and used automatically, so transfers still work with Wi-Fi off.
- **Pure Dart Embedded HTTP Engine:** High-speed streaming on port `53318` without heavy third-party native C-libraries or WebRTC dependencies.
- **ADB Reverse Tunnel Fallback:** When plugged into USB or wireless ADB, automatically routes via tunnel for instant sub-millisecond drops.
- **Web Browser Fallback:** Built-in web uploader (`http://<ip>:53318/web`) allows transferring photos from any browser without installing software.

---

## 🛠️ Linux Setup & Wi-Fi Firewall

Because Linux distributions like CachyOS/Ubuntu have `ufw` (firewall) active by default, allow incoming connections once for untethered wireless drops:

```bash
sudo ufw allow 53318/tcp && sudo ufw allow 53317/udp
```

### Run Linux Desktop Receiver
```bash
flutter run -d linux
# Or run the compiled release bundle:
./build/linux/x64/release/bundle/quickdrop
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
3. Linux usually creates `usb0` or `rndis0` automatically within a few seconds.
   The device card shows a `USB` chip and the Settings dialog lists the link
   under **ACTIVE LINKS**.

**Bluetooth tethering**
1. Pair the phone and computer once in their Bluetooth settings.
2. On Android, enable **Bluetooth tethering**.
3. Connect the phone's network in Linux Bluetooth or NetworkManager. QuickDrop
   shows the link as `Bluetooth` (often `bnep0`).

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
See [release/RELEASE.md](release/RELEASE.md) for the full release notes,
installation steps and known limitations.
