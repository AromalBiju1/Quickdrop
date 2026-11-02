# QuickDrop ⚡📸

> **Zero-Friction Phone-to-Laptop Screenshot & Photo Transfer**  
> Direct peer-to-peer Wi-Fi streaming with zero cloud, zero social media, and zero USB/Bluetooth pairing hassle.

**Latest release:** [v1.0.0 — release notes](RELEASE.md)

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

## 📱 Android Build & Install

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

A ready-to-sideload build is placed at the repository root as
`QuickDrop-1.0.0.apk`. See [RELEASE.md](RELEASE.md) for the full release notes,
installation steps and known limitations.
