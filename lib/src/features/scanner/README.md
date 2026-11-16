# Scanner

`GichoScanner` is an embeddable square camera viewport. It detects codes,
shows the configured scan look and torch control, handles camera errors, and
reports each decoded `ScanCode` to `onDetected`. It owns no page, navigation,
application validation, or tenant decision. The caller chooses where the square
viewport goes and what happens after a result.

## Configure and place

```dart
GichoScanner(
  configuration: ScannerConfiguration(
    codeTypes: const ScannerCodeTypes.qr(),
    look: ScannerLook.cylonSquare,
    cameraErrorMessage: 'The camera could not start.',
    permissionDeniedMessage: 'Allow camera access and try again.',
    torchOnLabel: 'Turn on flashlight',
    torchOffLabel: 'Turn off flashlight',
    onDetected: (code) {
      final raw = code.rawValue;
      if (raw != null) {
        handleCandidate(raw, code.format);
      }
    },
  ),
)
```

`ScannerCodeTypes.only({ScanCodeFormat.code128})` selects one exact format;
`only({ScanCodeFormat.qrCode, ScanCodeFormat.code128})` selects several.
`ScannerCodeTypes.qr()` and `.barcodes()` select families;
`ScannerCodeTypes.all()` detects all supported codes. The selection is fixed
for a scanner widget's lifetime; give it a new key when changing selections.
An empty exact selection is invalid.

`ScanCode` reports the unmodified `rawValue`, optional decoded `rawBytes`,
optional human-readable `displayValue`, and package-owned `format`. Bytes or
string may be absent depending on camera backend and code. The scanner skips
results with neither value nor bytes. It throttles duplicate callbacks for a
short interval; the app may reject a candidate and keep the viewport open.
If an app navigates on acceptance, its route owns that navigation. The server
must still authorize consequential work.

`ScannerLook.cylonSquare` is the current look: borderless square preview with a
thin red line moving vertically. Reduced-motion settings leave the line still;
the line appears only while the camera preview runs. The viewport has no title,
page frame, instruction, or outer margin. Wrap it in a `GichoModalPage` or
another app-owned layout when the task needs a full-page route.

## Platforms and setup

Gicho currently uses [`mobile_scanner` 7.x](https://pub.dev/packages/mobile_scanner)
behind this result contract. Its camera backends support Android, iOS, macOS
and web. Linux and Windows do not have a scanner backend. Consumers must
provide Android camera permission, `NSCameraUsageDescription` on iOS and the
Camera entitlement on macOS. Web camera access requires a secure context.
The [Android example](../../../../examples/flutter-scanner/README.md) places
this viewport inside its own modal page. Host tests check configuration and
layout; the owner performs installed-device camera acceptance.

## Files

- [index.dart](index.dart) exports the supported API.
- [scanner.dart](scanner.dart) owns camera capture and the square viewport.
- [scanner_configuration.dart](scanner_configuration.dart) defines selection, look, callback, errors, and torch labels.
- [scanner_code_types.dart](scanner_code_types.dart) selects one, several, a family, or all code types.
- [scanner_look.dart](scanner_look.dart) names the available visual treatment.
- [scan_code.dart](scan_code.dart) defines the decoder-independent result.
