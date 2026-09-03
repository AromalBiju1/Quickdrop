# QuickDrop ⚡📸

> **Zero-Friction Phone-to-Laptop Screenshot & Photo Transfer**  
> Direct peer-to-peer Wi-Fi streaming with zero cloud, zero social media, and zero USB/Bluetooth pairing hassle.

---

## ✨ Highlights

- **Instant Android Share Sheet Integration:** Snap a screenshot on your phone, tap **Share** on the preview banner, choose **QuickDrop**, and beam it directly to your laptop in under 150ms.
- **Zero-Touch Auto-Clipboard on Linux:** Received screenshots automatically save to `~/Pictures/Screenshots/` and are immediately copied to your system clipboard (`wl-copy` / `xclip`) with a native desktop notification. Just press `Ctrl+V` to paste anywhere.
- **Zero-Config UDP Discovery:** Devices discover each other automatically over local Wi-Fi / Hotspot on port `53317`.
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
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
