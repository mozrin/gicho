# Flutter scanner example

This independent Android app tests Gicho's configurable scanner with
three consumer meanings. **Employee** accepts `EMP:` values; **Menu**
accepts links under `https://example.org/menu/`; **Product** accepts a
barcode and displays its detected format and value. Those meanings exist only
in this demonstration. Gicho captures QR and barcode values and returns an
accepted result.

## Try it

From this directory:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <your-android-target>
```

The app asks for camera permission. Tap **Scan employee QR**, **Scan menu QR**,
or **Scan product barcode**, then aim at a code displayed on another screen.
Expand **Sample QRs for a second device** on that other screen for the two QR
samples, or use a product barcode for the third route. Scanning
the wrong type keeps the camera open and explains the mismatch; scanning the
right type returns to the home screen and displays the exact accepted content.
Back cancels without changing the previous result. The app-bar flashlight
button appears when the device reports a torch.

The owner performs installed-device checks; host tests cannot prove camera
permission, focus or QR detection on their device. Linux and Windows are not
camera targets for the current `mobile_scanner` backend.

## Read the app

1. [lib/main.dart](lib/main.dart) only starts `buildApp()`.
2. [lib/app.dart](lib/app.dart) composes `GichoMaterialApp` and
   `GichoAppShell` directly.
3. [lib/features/scan_demo/](lib/features/scan_demo/README.md) chooses each
   scanner configuration, validates app-specific payloads, owns navigation and
   shows sample QRs. It does not implement camera mechanics.
4. [lib/i18n/](lib/i18n/README.md) owns the example's English strings.
5. [test/app_test.dart](test/app_test.dart) checks the entry choices, Back and
   phone/tablet/large layout constraints.

The public package API is described in the
[Scanner feature guide](../../lib/src/features/scanner/README.md).
The example uses a local path dependency so package edits are testable without
changing a published tag. Its Android manifest declares camera permission.
