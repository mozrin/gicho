import 'dart:typed_data';

/// The platform source that supplied a photo.
enum GichoPhotoSource { camera, device }

/// Stable failure categories consumers can translate into their own copy.
enum GichoPhotoFailureKind {
  unsupported,
  unavailable,
  permissionDenied,
  permissionPermanentlyDenied,
  restricted,
  decodeFailed,
  pluginFailure,
}

/// A typed photo failure that does not require parsing platform error text.
class GichoPhotoException implements Exception {
  const GichoPhotoException(this.kind, {this.cause, this.stackTrace});

  final GichoPhotoFailureKind kind;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'GichoPhotoException($kind, cause: $cause)';
}

/// Unprocessed bytes returned by a camera or device picker adapter.
class GichoRawPhoto {
  GichoRawPhoto({
    required Uint8List bytes,
    required this.name,
    required this.source,
    this.mimeType,
  }) : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;
  final String name;
  final String? mimeType;
  final GichoPhotoSource source;
}

/// Normalized photo bytes and metadata, still owned by the calling app.
class GichoPhoto {
  GichoPhoto({
    required Uint8List bytes,
    required this.name,
    required this.mimeType,
    required this.width,
    required this.height,
    required this.source,
    this.isCropped = false,
  }) : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;
  final String name;
  final String mimeType;
  final int width;
  final int height;
  final GichoPhotoSource source;
  final bool isCropped;

  double get aspectRatio => width / height;

  GichoPhoto copyWith({
    Uint8List? bytes,
    String? name,
    String? mimeType,
    int? width,
    int? height,
    GichoPhotoSource? source,
    bool? isCropped,
  }) => GichoPhoto(
    bytes: bytes ?? this.bytes,
    name: name ?? this.name,
    mimeType: mimeType ?? this.mimeType,
    width: width ?? this.width,
    height: height ?? this.height,
    source: source ?? this.source,
    isCropped: isCropped ?? this.isCropped,
  );
}

enum GichoCameraLens { front, back, external, unknown }

/// App-neutral camera identity exposed by a camera adapter.
class GichoCameraDevice {
  const GichoCameraDevice({
    required this.id,
    required this.label,
    required this.lens,
  });

  final String id;
  final String label;
  final GichoCameraLens lens;
}

enum GichoCameraCapabilityState {
  available,
  unsupported,
  unavailable,
  permissionDenied,
  permissionPermanentlyDenied,
  restricted,
}

/// Result of camera discovery before a consuming app enables capture.
class GichoCameraCapability {
  const GichoCameraCapability({
    required this.state,
    this.devices = const [],
    this.failure,
  });

  final GichoCameraCapabilityState state;
  final List<GichoCameraDevice> devices;
  final GichoPhotoException? failure;

  bool get isAvailable =>
      state == GichoCameraCapabilityState.available && devices.isNotEmpty;
}

/// Caller-supplied, localized camera page text.
class GichoCameraCopy {
  const GichoCameraCopy({
    required this.title,
    required this.initializing,
    required this.capture,
    required this.capturing,
    required this.retake,
    required this.usePhoto,
    required this.switchCamera,
    required this.retry,
    required this.unavailable,
    required this.unsupported,
    required this.permissionDenied,
    required this.permissionPermanentlyDenied,
    required this.restricted,
    required this.failure,
  });

  final String title;
  final String initializing;
  final String capture;
  final String capturing;
  final String retake;
  final String usePhoto;
  final String switchCamera;
  final String retry;
  final String unavailable;
  final String unsupported;
  final String permissionDenied;
  final String permissionPermanentlyDenied;
  final String restricted;
  final String failure;
}

/// Caller-supplied, localized crop page text.
class GichoPhotoCropCopy {
  const GichoPhotoCropCopy({
    required this.title,
    required this.instructions,
    required this.usePhoto,
    required this.cropping,
    required this.retry,
    required this.failure,
  });

  final String title;
  final String instructions;
  final String usePhoto;
  final String cropping;
  final String retry;
  final String failure;
}

typedef GichoPhotoLogSink = void Function(String message);
