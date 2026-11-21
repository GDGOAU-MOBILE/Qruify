# Scanner feature: brief for the AI agent

Read this whole file first. It is short on purpose. Do only what it says.

## Goal

Add a QR scanner to Qruify. A small round button (FAB) on the home screen
opens the camera, reads one QR code, and shows what is inside. The Generate
button must stay exactly as it is.

## Rules

- Qruify is offline and private. Do not add a backend, login, analytics or any
  network call.
- Change as little as possible. Do not refactor existing files.
- Follow the style of the code already in `lib/`: small files, doc comments
  that say why, no clever tricks.
- Do not add a package without telling the user its name and why. Run
  `flutter pub add <name>`, never edit versions by hand.
- Work in the steps below. After each step run `flutter analyze` and stop if it
  reports anything.

## Steps

1. **Package.** Add one scanner package from pub.dev (for example
   `mobile_scanner`). Read its README first and follow its setup for Android
   and iOS. Do not guess its API from memory.
2. **Permission.** Android: declare `android.permission.CAMERA` in
   `android/app/src/main/AndroidManifest.xml`. iOS: add
   `NSCameraUsageDescription` to `ios/Runner/Info.plist` with a short, honest
   reason. Ask for access only when the user taps the scan button, not when
   the app opens.
3. **Screen.** Create `lib/features/scanner/scanner_screen.dart`. It shows the
   camera, reads the first QR code, and returns the text to the caller. If the
   user says no to the camera, show a short message and a way back. No blank
   camera view.
4. **Button.** In `lib/features/generator/generator_screen.dart`, add a small
   FAB with a scan icon. Place it above the Generate button, on the right side.
   It must never sit on the same line as Generate or cover any part of it, and
   Generate must keep its current size and position. Read the screen's layout
   first and find a spot that does not push or overlap anything. The same
   screen turns into the result view after Generate (the button becomes Share),
   so hide the FAB there. Tapping the FAB opens the scanner screen.
5. **Result.** Show the scanned text in a simple sheet. Reuse
   `QrDetector.detect` (`lib/core/qr_detector.dart`) to label it as a link,
   email, phone or text. Do not open links automatically.

## Done when

- `flutter analyze` is clean and `flutter test` still passes.
- On a device or emulator, tapping the FAB asks for the camera once, opens the
  camera, and a QR code shows its content.
- Saying no to the camera shows the message, and the app does not crash.
- The FAB sits above Generate on the right. Generate looks and works exactly as
  before, and the FAB is hidden in the result view.

## Out of scope (do not build unless asked)

- Importing a CSV guest list and checking people in. That is a later idea.
- Saving scanned codes to history.
- Any change to how codes are generated.

## Unverified

The package name above is only a suggestion. Check the package's current docs
and platform requirements before using it. Nothing in this brief has been run
with a real agent yet.
