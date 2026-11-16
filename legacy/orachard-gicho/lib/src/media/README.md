> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Media

Gicho exposes one app-neutral photo workflow through the public package:

```dart
import 'package:moztopia/gicho.dart';

final photos = GichoPhotoFlow.standard(maximumDimension: 4096);
final capability = await photos.inspectCameraCapability();
final selected = await photos.chooseFromDevice();
```

Consuming applications do not import or version `camera`, `image_picker`,
`crop_your_image`, or `image`. Gicho owns those integrations and returns
`GichoPhoto` values containing normalized bytes, MIME type, dimensions,
source, and crop state.

## Camera and crop pages

Callers provide localized copy and the desired aspect ratio. Gicho owns the
full-screen pages, camera lifecycle, capture/retake/confirm behavior, and actual
crop output:

```dart
final captured = await photos.capturePhoto(
  context,
  previewAspectRatio: 4 / 5,
  capability: capability,
  copy: cameraCopyForTheSelectedLocale,
);

final cropped = captured == null
    ? null
    : await photos.cropPhoto(
        context,
        photo: captured,
        aspectRatio: 4 / 5,
        copy: cropCopyForTheSelectedLocale,
      );
```

`chooseFromDevice` opens the native photo/file selector. Both picker and camera
bytes are decoded, have EXIF orientation baked into their pixels, and are
normalized to metadata-free JPEG before cropping. When `maximumDimension` is
configured, oversized sources are proportionally reduced during that hidden
normalization step. A confirmed crop returns new bytes and dimensions; it never
aliases the untouched input.

## Platform behavior

| Platform | Camera | Device selection | Crop |
| --- | --- | --- | --- |
| Android | Official Flutter camera | Native photo picker | Supported |
| iOS | Official Flutter camera | Native photo picker | Supported |
| Web/Chrome | Browser camera | Browser file picker | Supported |
| Linux | Injectable desktop adapter | Native file picker | Supported |
| macOS/Windows | Injectable desktop adapter | Native file picker | Supported |

The default camera gateway deliberately reports desktop camera capture as
`unsupported`. A desktop application may inject a `GichoCameraGateway`
implementation without changing any consumer-facing flow. This avoids forcing
native camera build dependencies on applications that do not need them.

Linux/macOS/Windows camera support has a viable federated backend, but it
requires native platform toolchains. Orchard records those optional Linux
GStreamer prerequisites in its owner-controlled devcontainer rebuild checklist
instead of disrupting a working container during product implementation.

## Ownership boundary

Gicho owns reusable mechanics:

- camera capability discovery and typed failure states;
- lifecycle-safe preview, switching, capture, retake, and confirmation;
- native image/file selection and Android lost-data recovery;
- EXIF normalization and fixed-aspect drag/pinch cropping;
- debug event logging and injectable adapters for tests.

The consuming application owns product semantics and policy:

- labels, instructions, permission recovery text, and translations;
- the selected aspect ratio and MIME/dimension/byte-size limits;
- navigation into the flow, state persistence, uploads, moderation, and API
  calls.

The production adapters never use fixtures. Tests should inject fake picker and
camera adapters rather than requiring physical hardware in CI.
