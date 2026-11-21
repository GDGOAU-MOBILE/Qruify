<div align="center">
  <img src="design/previews/actool-default-120.png" width="96" height="96" alt="Qruify Logo" />
  <h1>Qruify</h1>
  <p><strong>A private, offline-first QR code generator, scanner, and guest list approver for mobile.</strong></p>

  <p>
    <a href="https://github.com/GDGOAU-MOBILE/Qruify/releases/latest/download/qruify-arm64-v8a-release.apk">
      <img src="https://img.shields.io/badge/Download%20for%20Android-APK%20(ARM64)-34C759?style=for-the-badge&logo=android&logoColor=white" alt="Download for Android" />
    </a>
    <a href="https://github.com/GDGOAU-MOBILE/Qruify/releases/latest/download/qruify-universal-release.apk">
      <img src="https://img.shields.io/badge/Universal%20APK-All%20Devices-black?style=for-the-badge&logo=android&logoColor=white" alt="Universal APK" />
    </a>
  </p>

  <p>
    <a href="https://github.com/GDGOAU-MOBILE/Qruify/releases"><img src="https://img.shields.io/github/v/release/GDGOAU-MOBILE/Qruify?color=black&style=flat-square" alt="Latest Release" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" alt="License" /></a>
    <a href="https://ferousco-dev.github.io/qruify-privacy-policy/"><img src="https://img.shields.io/badge/Privacy-100%25%20Offline-success?style=flat-square" alt="Privacy" /></a>
    <img src="https://img.shields.io/badge/Flutter-3.38-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  </p>
</div>

---

## Overview

**Qruify** is an open-source, production-ready utility designed for creating, styling, scanning, and verifying QR codes entirely on your device. It requires no network connection, no user accounts, and zero third-party tracking.

---

## Key Features

- **Smart Payload Detection:** Type or paste anything. Qruify automatically identifies links, email addresses, phone numbers, and plain text without needing manual dropdown switches. Dedicated forms handle Wi-Fi networks and passwords.
- **In-Place Transformation:** Pressing *Generate* transforms the active screen directly into a shareable result state without disrupting navigation.
- **Offline Camera Scanner:** Integrated camera scanner decodes barcodes locally in RAM in real time. Camera frames are never stored, saved, or uploaded.
- **Guest List CSV Approver:** Import attendee rosters via `.csv` file picker or direct clipboard paste. Instantly verify tickets and badges with real-time approval status badges (**Approved**, **Already Checked In**, or **Not Found**).
- **Logo & Scannability Engine:** Custom brand colors with automated contrast warnings. Center-embedded logos are constrained to strictly preserve QR error correction boundaries (Level H).
- **On-Device History:** SQLite-backed local history lets you search, re-share, export PNGs, or clear all history at any time.
- **Private by Design:** Zero analytics SDKs, zero telemetry, zero advertising, and zero external backend calls.

---

## Downloads

| Package | Recommended For | Size | Download |
| :--- | :--- | :---: | :---: |
| **ARM64 APK** | Modern Android devices (most smartphones) | ~26 MB | [Download APK](https://github.com/GDGOAU-MOBILE/Qruify/releases/latest/download/qruify-arm64-v8a-release.apk) |
| **Universal APK** | Any Android device (32-bit & 64-bit) | ~70 MB | [Download APK](https://github.com/GDGOAU-MOBILE/Qruify/releases/latest/download/qruify-universal-release.apk) |
| **ARMv7 APK** | Older 32-bit Android phones | ~22 MB | [Download APK](https://github.com/GDGOAU-MOBILE/Qruify/releases/latest/download/qruify-armeabi-v7a-release.apk) |
| **Play Store Bundle** | Google Play Console distribution | ~55 MB | [Download AAB](https://github.com/GDGOAU-MOBILE/Qruify/releases/latest/download/qruify-release.aab) |

---

## Architecture & Tech Stack

```
lib/
├── core/         # Matrix generation, payloads, styling, drawing & logo math
├── data/         # Drift SQLite database, guest repository, history & settings
├── services/     # PNG rendering, share intents, file pickers & DI scope
└── features/     # Generator, Scanner, Guest List, Customization, History, Settings
```

- **Framework:** [Flutter](https://flutter.dev) (Dart 3)
- **Local Storage:** [Drift](https://drift.simonbinder.eu/) (SQLite)
- **Camera Scanner:** [mobile_scanner](https://pub.dev/packages/mobile_scanner)
- **Data Parsing:** [csv](https://pub.dev/packages/csv) & [file_picker](https://pub.dev/packages/file_picker)
- **Design System:** Custom native iOS/Android styling, Geist typography, and HugeIcons

---

## Building from Source

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.38.0`)
- Android Studio / Xcode for platform builds

### Setup & Run
```bash
# Clone the repository
git clone https://github.com/GDGOAU-MOBILE/Qruify.git
cd Qruify

# Install packages & run code generation
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Run verification suite
flutter analyze
flutter test

# Launch the app
flutter run
```

### Build Release Artifacts
```bash
# Build Google Play App Bundle
flutter build appbundle --release

# Build architecture-split APKs
flutter build apk --release --split-per-abi
```

---

## Privacy Policy

Qruify does not collect, store, or transmit any personal data. View our full hosted privacy policy at:
👉 **[https://ferousco-dev.github.io/qruify-privacy-policy/](https://ferousco-dev.github.io/qruify-privacy-policy/)**

---

## License

Copyright &copy; 2026 GDG Mobile OAU (Oresajo Oluwaferanmi).  
Released under the [MIT License](LICENSE).
