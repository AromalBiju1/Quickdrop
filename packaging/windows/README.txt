QuickDrop - Windows x64
=======================

QuickDrop receives files from Android over your local network, hotspot,
USB tether, or Bluetooth tether. No account, cloud, or internet required.

Run QuickDrop
-------------
Keep the whole extracted folder together and run:

  quickdrop.exe

The data folder, DLLs, and quickdrop.exe must stay in the same directory.
Windows may show a SmartScreen warning because this build is not code-signed.
Choose More info, then Run anyway if you trust the download.

Windows Defender Firewall
-------------------------
When Windows asks, allow QuickDrop on Private networks. If you dismissed the
prompt, allow TCP 53318 and UDP 53317 for the app in Windows Defender
Firewall > Allow an app through firewall.

Receiving from a phone
----------------------
Open QuickDrop on this computer, then use the URL or QR code shown on the
Receive tab. A phone can also upload from its browser without installing
the Android app.

Received files are saved to:

  %USERPROFILE%\Downloads\QuickDrop

Requirements
------------
  Windows 10 or Windows 11, 64-bit
  Microsoft Visual C++ 2015-2022 Redistributable (x64), if not already present
  TCP 53318 and UDP 53317 reachable between devices

Security
--------
Transfers are not encrypted and have no authentication. Use QuickDrop only
on networks you trust and never expose these ports to the public internet.
