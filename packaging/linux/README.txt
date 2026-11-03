QuickDrop - Linux x64
=====================

QuickDrop receives files from Android over your local network, hotspot,
USB tether, or Bluetooth tether. No account, cloud, or internet required.

Run without installing
----------------------
  ./quickdrop

Install for the current user
----------------------------
  ./install.sh

This copies QuickDrop to ~/.local/opt/quickdrop and adds an application-menu
launcher and icon. Your settings and transfer history live in
~/.local/share/com.elyssia.quickdrop.quickdrop.

Firewall
--------
Allow the receiver ports once if your firewall blocks local connections:

  sudo ufw allow 53318/tcp
  sudo ufw allow 53317/udp

Receiving from a phone
----------------------
Open QuickDrop on this computer, then use the URL or QR code shown on the
Receive tab. A phone can also upload from its browser without installing
the Android app.

Requirements
------------
  Linux x64 with GTK 3
  TCP 53318 and UDP 53317 reachable between devices

Security
--------
Transfers are not encrypted and have no authentication. Use QuickDrop only
on networks you trust and never expose these ports to the public internet.
