import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'gicho_photo_models.dart';

/// Injectable boundary around the operating-system image selection UI.
abstract interface class GichoPhotoPickerAdapter {
  Future<GichoRawPhoto?> chooseFromDevice();

  Future<GichoRawPhoto?> recoverLostPhoto();
}

/// Production picker backed by the official Flutter image picker plugin.
class PlatformGichoPhotoPicker implements GichoPhotoPickerAdapter {
  PlatformGichoPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<GichoRawPhoto?> chooseFromDevice() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      return file == null ? null : await _rawPhoto(file);
    } catch (error, stackTrace) {
      throw GichoPhotoException(
        GichoPhotoFailureKind.pluginFailure,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<GichoRawPhoto?> recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        return await _rawPhoto(files.first);
      }
      throw GichoPhotoException(
        GichoPhotoFailureKind.pluginFailure,
        cause: response.exception,
      );
    } on GichoPhotoException {
      rethrow;
    } catch (error, stackTrace) {
      throw GichoPhotoException(
        GichoPhotoFailureKind.pluginFailure,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<GichoRawPhoto> _rawPhoto(XFile file) async => GichoRawPhoto(
    bytes: await file.readAsBytes(),
    name: file.name,
    mimeType: file.mimeType,
    source: GichoPhotoSource.device,
  );
}
