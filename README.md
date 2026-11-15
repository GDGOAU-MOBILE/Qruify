# Qruify

[![License: MIT](https://img.shields.io/badge/license-MIT-black.svg)](LICENSE)

Qruify is an open source QR code generator for iOS and Android. It works offline, needs no account, and keeps everything you create on your device.

Type or paste a link, an email address, a phone number, some text or Wi-Fi details. Qruify works out what it is, turns it into a QR code, and lets you share it, copy it, or find it again later.

## What it does

- **One smart input.** Paste or type anything. Qruify detects whether it is a link, an email, a phone number or plain text. Wi-Fi has its own form, because it needs a password and a security type.
- **Live preview** that updates as you type.
- **Generate in place.** Pressing Generate does not open a new page. The same screen turns into the result: Generate becomes Share, Copy appears beneath it, and the header gets a Back button.
- **Customize the look.** Pick the code and background colors, with a warning when a combination will be hard to scan.
- **Logo in the middle.** Add your own picture. See [How the logo stays scannable](#how-the-logo-stays-scannable).
- **History.** Every code is saved on the device. Search it, open one to share or copy it again, delete one, or clear all.
- **Settings.** Clear history, reset the saved style, replay the welcome screen.
- **Private by design.** No backend, no login, no API key, no analytics. Nothing leaves the device unless you share it.

## Why it exists

Most QR generators are websites. They need a connection, sometimes ask you to sign up, and send your content to a server. Qruify generates codes on the phone itself.

## How the logo stays scannable

A QR code can lose part of itself and still scan, because it carries repair data. A logo hides part of the code on purpose, so Qruify keeps the loss well inside what the code can repair:

- Adding a logo forces the strongest error correction (level H, which repairs about 30% damage). Your own choice comes back when you remove the logo.
- The logo and its clear padding cover at most 11% of the code, and the logo is at most 20% of its width.
- The cleared area sits exactly on the module grid, dead center, with an odd number of modules on each side.
- It stays at least 9 modules from every edge, so it never touches the three corner squares or the format information.
- The smallest code size (version 1) has no room, so it gets no logo and the screen says so.

Tests check this for every QR version from 2 to 40, and decode real rendered codes with a logo using an independent reader. Please also scan your own codes with a real phone before printing them.

## Tech stack

Qruify is built with Flutter and Dart.

| Package | Used for |
| --- | --- |
| `qr_flutter` | Building the QR matrix (its `qr` engine). Drawing is done by Qruify itself, so the preview and the exported image are identical |
| `drift` | Local SQLite database for history |
| `shared_preferences` | Small settings, such as the last style used |
| `share_plus` | Sharing codes with other apps |
| `image_picker` | Choosing a logo |
| `hugeicons` | Icons |

The Geist typeface is bundled in `assets/fonts`.

## Project layout

```
lib/
  core/        QR payloads, type detection, style, logo, drawing
  data/        drift database, history repository, settings
  services/    export and share, logo picker, app services
  features/    splash, onboarding, generator, customization, history, settings
test/          unit, widget and decoding tests
```

## Getting started

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
dart run build_runner build
flutter run
```

The `build_runner` step generates the drift database code. Run it again after you change the database schema.

Run the checks:

```bash
flutter analyze
flutter test
```

Some dependency versions are pinned on purpose (`drift`, `sqlite3`, `path_provider_*`). Check `pubspec.yaml` before upgrading them.

## Contributing

Issues and pull requests are welcome. Please run `flutter analyze` and `flutter test` before opening a pull request, and add a test for what you change.

## License

Copyright (c) 2026 GDG Mobile OAU (Oresajo Oluwaferanmi).

Qruify is released under the [MIT License](LICENSE). You can use, copy, modify and distribute it, including commercially, as long as the license notice stays with it.
