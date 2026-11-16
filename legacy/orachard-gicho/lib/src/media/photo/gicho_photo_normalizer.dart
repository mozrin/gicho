import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

import 'gicho_photo_models.dart';

/// Decodes photos, bakes EXIF orientation, and emits metadata-safe JPEG bytes.
class GichoPhotoNormalizer {
  const GichoPhotoNormalizer({this.jpegQuality = 92, this.maximumDimension})
    : assert(jpegQuality >= 1 && jpegQuality <= 100),
      assert(maximumDimension == null || maximumDimension > 0);

  final int jpegQuality;
  final int? maximumDimension;

  Future<GichoPhoto> normalize(GichoRawPhoto raw) async {
    try {
      final result = await compute(_normalizePhoto, <String, Object?>{
        'bytes': raw.bytes,
        'quality': jpegQuality,
        'maximumDimension': maximumDimension,
      });
      return GichoPhoto(
        bytes: result.bytes,
        name: _jpegName(raw.name),
        mimeType: 'image/jpeg',
        width: result.width,
        height: result.height,
        source: raw.source,
      );
    } on GichoPhotoException {
      rethrow;
    } catch (error, stackTrace) {
      throw GichoPhotoException(
        GichoPhotoFailureKind.decodeFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Describes bytes returned by a crop backend without re-encoding them.
  Future<GichoPhoto> describeCrop({
    required Uint8List bytes,
    required GichoPhoto original,
  }) async {
    try {
      final dimensions = await compute(_inspectPhoto, bytes);
      final mimeType = _detectMimeType(bytes);
      return GichoPhoto(
        bytes: bytes,
        name: _croppedName(original.name, mimeType),
        mimeType: mimeType,
        width: dimensions.width,
        height: dimensions.height,
        source: original.source,
        isCropped: true,
      );
    } catch (error, stackTrace) {
      throw GichoPhotoException(
        GichoPhotoFailureKind.decodeFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

typedef _DecodedPhoto = ({Uint8List bytes, int width, int height});
typedef _PhotoDimensions = ({int width, int height});

_DecodedPhoto _normalizePhoto(Map<String, Object?> input) {
  final decoded = image.decodeImage(input['bytes']! as Uint8List);
  if (decoded == null) {
    throw const GichoPhotoException(GichoPhotoFailureKind.decodeFailed);
  }
  final oriented = image.bakeOrientation(decoded);
  final maximumDimension = input['maximumDimension'] as int?;
  final normalized = maximumDimension == null
      ? oriented
      : _boundImage(oriented, maximumDimension);
  final bytes = Uint8List.fromList(
    image.encodeJpg(normalized, quality: input['quality']! as int),
  );
  return (bytes: bytes, width: normalized.width, height: normalized.height);
}

image.Image _boundImage(image.Image source, int maximumDimension) {
  if (source.width <= maximumDimension && source.height <= maximumDimension) {
    return source;
  }
  return source.width >= source.height
      ? image.copyResize(
          source,
          width: maximumDimension,
          interpolation: image.Interpolation.cubic,
        )
      : image.copyResize(
          source,
          height: maximumDimension,
          interpolation: image.Interpolation.cubic,
        );
}

_PhotoDimensions _inspectPhoto(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) {
    throw const GichoPhotoException(GichoPhotoFailureKind.decodeFailed);
  }
  return (width: decoded.width, height: decoded.height);
}

String _jpegName(String sourceName) {
  final basename = sourceName.split(RegExp(r'[/\\]')).last;
  final withoutExtension = basename.replaceFirst(RegExp(r'\.[^.]+$'), '');
  final safeName = withoutExtension.trim().isEmpty ? 'photo' : withoutExtension;
  return '$safeName.jpeg';
}

String _croppedName(String sourceName, String mimeType) {
  final withoutExtension = sourceName.replaceFirst(RegExp(r'\.[^.]+$'), '');
  final extension = mimeType == 'image/png' ? 'png' : 'jpg';
  return '${withoutExtension}_cropped.$extension';
}

String _detectMimeType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  return 'application/octet-stream';
}
