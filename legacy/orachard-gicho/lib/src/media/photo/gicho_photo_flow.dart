import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../logging/configured_logging.dart';
import 'gicho_camera.dart';
import 'gicho_camera_page.dart';
import 'gicho_photo_crop_page.dart';
import 'gicho_photo_models.dart';
import 'gicho_photo_normalizer.dart';
import 'gicho_photo_picker.dart';

/// Reusable orchestration for camera discovery, capture, selection, and crop.
class GichoPhotoFlow {
  GichoPhotoFlow({
    required GichoCameraGateway cameraGateway,
    required GichoPhotoPickerAdapter picker,
    required GichoPhotoNormalizer normalizer,
    GichoPhotoLogSink? logSink,
  }) : this._(cameraGateway, picker, normalizer, logSink);

  GichoPhotoFlow._(
    this._cameraGateway,
    this._picker,
    this._normalizer,
    this._logSink,
  );

  factory GichoPhotoFlow.standard({
    GichoPhotoLogSink? logSink,
    int? maximumDimension,
  }) => GichoPhotoFlow(
    cameraGateway: PlatformGichoCameraGateway(),
    picker: PlatformGichoPhotoPicker(),
    normalizer: GichoPhotoNormalizer(maximumDimension: maximumDimension),
    logSink: logSink,
  );

  final GichoCameraGateway _cameraGateway;
  final GichoPhotoPickerAdapter _picker;
  final GichoPhotoNormalizer _normalizer;
  final GichoPhotoLogSink? _logSink;

  Future<GichoCameraCapability> inspectCameraCapability() async {
    _log('camera capability inspection started');
    if (!_cameraGateway.isSupportedPlatform) {
      _log('camera capability inspection completed: unsupported');
      return const GichoCameraCapability(
        state: GichoCameraCapabilityState.unsupported,
        failure: GichoPhotoException(GichoPhotoFailureKind.unsupported),
      );
    }
    try {
      final devices = await _cameraGateway.discoverCameras();
      if (devices.isEmpty) {
        _log('camera capability inspection completed: unavailable');
        return const GichoCameraCapability(
          state: GichoCameraCapabilityState.unavailable,
          failure: GichoPhotoException(GichoPhotoFailureKind.unavailable),
        );
      }
      _log(
        'camera capability inspection completed: ${devices.length} device(s)',
      );
      return GichoCameraCapability(
        state: GichoCameraCapabilityState.available,
        devices: devices,
      );
    } on GichoPhotoException catch (error) {
      final state = _capabilityState(error.kind);
      _log('camera capability inspection failed: ${error.kind.name}');
      return GichoCameraCapability(state: state, failure: error);
    } catch (error, stackTrace) {
      final failure = GichoPhotoException(
        GichoPhotoFailureKind.pluginFailure,
        cause: error,
        stackTrace: stackTrace,
      );
      _log('camera capability inspection failed: pluginFailure');
      return GichoCameraCapability(
        state: GichoCameraCapabilityState.unavailable,
        failure: failure,
      );
    }
  }

  Future<GichoPhoto?> chooseFromDevice() async {
    _log('device photo selection started');
    try {
      final raw = await _picker.chooseFromDevice();
      if (raw == null) {
        _log('device photo selection cancelled');
        return null;
      }
      _log('selected photo normalization started');
      final photo = await _normalizer.normalize(raw);
      _log('device photo selection completed: ${photo.width}x${photo.height}');
      return photo;
    } catch (error) {
      _log('device photo selection failed: $error');
      rethrow;
    }
  }

  /// Recovers an Android selection interrupted by activity destruction.
  Future<GichoPhoto?> recoverLostPhoto() async {
    _log('lost photo recovery started');
    try {
      final raw = await _picker.recoverLostPhoto();
      if (raw == null) {
        _log('lost photo recovery completed: no photo');
        return null;
      }
      final photo = await _normalizer.normalize(raw);
      _log('lost photo recovery completed: ${photo.width}x${photo.height}');
      return photo;
    } catch (error) {
      _log('lost photo recovery failed: $error');
      rethrow;
    }
  }

  Future<GichoPhoto?> capturePhoto(
    BuildContext context, {
    required GichoCameraCopy copy,
    required double previewAspectRatio,
    GichoCameraCapability? capability,
  }) async {
    final resolvedCapability = capability ?? await inspectCameraCapability();
    if (!resolvedCapability.isAvailable) {
      throw resolvedCapability.failure ??
          const GichoPhotoException(GichoPhotoFailureKind.unavailable);
    }
    if (!context.mounted) return null;
    _log('camera page navigation started');
    final photo = await Navigator.of(context).push<GichoPhoto>(
      MaterialPageRoute<GichoPhoto>(
        fullscreenDialog: true,
        builder: (_) => GichoCameraPage(
          gateway: _cameraGateway,
          normalizer: _normalizer,
          copy: copy,
          aspectRatio: previewAspectRatio,
          initialDevices: resolvedCapability.devices,
          logSink: _emit,
        ),
      ),
    );
    _log(
      photo == null
          ? 'camera page navigation completed: cancelled'
          : 'camera page navigation completed: photo selected',
    );
    return photo;
  }

  Future<GichoPhoto?> cropPhoto(
    BuildContext context, {
    required GichoPhoto photo,
    required double aspectRatio,
    required GichoPhotoCropCopy copy,
  }) async {
    _log('crop page navigation started');
    final cropped = await Navigator.of(context).push<GichoPhoto>(
      MaterialPageRoute<GichoPhoto>(
        fullscreenDialog: true,
        builder: (_) => GichoPhotoCropPage(
          photo: photo,
          aspectRatio: aspectRatio,
          copy: copy,
          normalizer: _normalizer,
          logSink: _emit,
        ),
      ),
    );
    _log(
      cropped == null
          ? 'crop page navigation completed: cancelled'
          : 'crop page navigation completed: crop selected',
    );
    return cropped;
  }

  void _log(String message) => _emit('[Gicho photo] $message');

  void _emit(String message) {
    final sink = _logSink;
    if (sink != null) {
      sink(message);
    } else {
      unawaited(moztopiaLog.debug(message));
    }
  }
}

GichoCameraCapabilityState _capabilityState(GichoPhotoFailureKind kind) =>
    switch (kind) {
      GichoPhotoFailureKind.unsupported =>
        GichoCameraCapabilityState.unsupported,
      GichoPhotoFailureKind.unavailable =>
        GichoCameraCapabilityState.unavailable,
      GichoPhotoFailureKind.permissionDenied =>
        GichoCameraCapabilityState.permissionDenied,
      GichoPhotoFailureKind.permissionPermanentlyDenied =>
        GichoCameraCapabilityState.permissionPermanentlyDenied,
      GichoPhotoFailureKind.restricted =>
        GichoCameraCapabilityState.restricted,
      _ => GichoCameraCapabilityState.unavailable,
    };
