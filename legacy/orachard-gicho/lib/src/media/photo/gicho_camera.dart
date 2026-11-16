import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'gicho_photo_models.dart';

/// Injectable camera boundary used by the reusable Gicho camera page.
abstract interface class GichoCameraGateway {
  bool get isSupportedPlatform;

  Future<List<GichoCameraDevice>> discoverCameras();

  Future<GichoCameraSession> openCamera(GichoCameraDevice device);
}

abstract interface class GichoCameraSession {
  double get previewAspectRatio;

  Widget buildPreview();

  Future<GichoRawPhoto> capturePhoto();

  Future<void> dispose();
}

/// Official Flutter camera implementation for Android, iOS, and web.
///
/// Desktop applications can inject another [GichoCameraGateway] without
/// changing the public photo flow.
class PlatformGichoCameraGateway implements GichoCameraGateway {
  final Map<String, CameraDescription> _descriptions = {};

  @override
  bool get isSupportedPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<List<GichoCameraDevice>> discoverCameras() async {
    if (!isSupportedPlatform) {
      throw const GichoPhotoException(GichoPhotoFailureKind.unsupported);
    }
    try {
      final cameras = await availableCameras();
      _descriptions
        ..clear()
        ..addEntries(cameras.map((camera) => MapEntry(camera.name, camera)));
      return [
        for (final camera in cameras)
          GichoCameraDevice(
            id: camera.name,
            label: camera.name,
            lens: _cameraLens(camera.lensDirection),
          ),
      ];
    } on CameraException catch (error, stackTrace) {
      throw _cameraFailure(error, stackTrace);
    } catch (error, stackTrace) {
      throw GichoPhotoException(
        GichoPhotoFailureKind.pluginFailure,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<GichoCameraSession> openCamera(GichoCameraDevice device) async {
    try {
      var description = _descriptions[device.id];
      if (description == null) {
        await discoverCameras();
        description = _descriptions[device.id];
      }
      if (description == null) {
        throw const GichoPhotoException(
          GichoPhotoFailureKind.unavailable,
        );
      }
      final controller = CameraController(
        description,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      try {
        await controller.initialize();
        return _PluginCameraSession(controller);
      } catch (_) {
        await controller.dispose();
        rethrow;
      }
    } on GichoPhotoException {
      rethrow;
    } on CameraException catch (error, stackTrace) {
      throw _cameraFailure(error, stackTrace);
    } catch (error, stackTrace) {
      throw GichoPhotoException(
        GichoPhotoFailureKind.pluginFailure,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class _PluginCameraSession implements GichoCameraSession {
  _PluginCameraSession(this._controller);

  final CameraController _controller;
  var _disposed = false;

  @override
  double get previewAspectRatio => _controller.value.aspectRatio;

  @override
  Widget buildPreview() => CameraPreview(_controller);

  @override
  Future<GichoRawPhoto> capturePhoto() async {
    if (_disposed || !_controller.value.isInitialized) {
      throw const GichoPhotoException(GichoPhotoFailureKind.unavailable);
    }
    try {
      final file = await _controller.takePicture();
      return GichoRawPhoto(
        bytes: Uint8List.fromList(await file.readAsBytes()),
        name: file.name,
        mimeType: file.mimeType,
        source: GichoPhotoSource.camera,
      );
    } on CameraException catch (error, stackTrace) {
      throw _cameraFailure(error, stackTrace);
    } catch (error, stackTrace) {
      throw GichoPhotoException(
        GichoPhotoFailureKind.pluginFailure,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _controller.dispose();
  }
}

GichoCameraLens _cameraLens(CameraLensDirection direction) =>
    switch (direction) {
      CameraLensDirection.front => GichoCameraLens.front,
      CameraLensDirection.back => GichoCameraLens.back,
      CameraLensDirection.external => GichoCameraLens.external,
    };

GichoPhotoException _cameraFailure(
  CameraException error,
  StackTrace stackTrace,
) => GichoPhotoException(
  switch (error.code) {
    'CameraAccessDenied' => GichoPhotoFailureKind.permissionDenied,
    'CameraAccessDeniedWithoutPrompt' =>
      GichoPhotoFailureKind.permissionPermanentlyDenied,
    'CameraAccessRestricted' => GichoPhotoFailureKind.restricted,
    _ => GichoPhotoFailureKind.pluginFailure,
  },
  cause: error,
  stackTrace: stackTrace,
);
