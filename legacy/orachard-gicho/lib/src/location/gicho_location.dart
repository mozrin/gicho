import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum GichoLocationFailureKind {
  unsupported,
  servicesDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timedOut,
  unavailable,
  pluginFailure,
}

enum GichoLocationAccuracy { low, balanced, high }

final class GichoCoordinates {
  const GichoCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

final class GichoLocationRequest {
  const GichoLocationRequest({
    this.accuracy = GichoLocationAccuracy.balanced,
    this.timeout = const Duration(seconds: 15),
  });

  final GichoLocationAccuracy accuracy;
  final Duration timeout;
}

final class GichoLocationException implements Exception {
  const GichoLocationException(this.kind, {this.cause, this.stackTrace});

  final GichoLocationFailureKind kind;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'GichoLocationException($kind, cause: $cause)';
}

abstract interface class GichoLocationGateway {
  bool get isSupportedPlatform;

  Future<GichoCoordinates> current(GichoLocationRequest request);

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

typedef GichoLocationLogSink = void Function(String message);

/// App-neutral location workflow with typed permission and platform failures.
final class GichoLocationService {
  const GichoLocationService({required this.gateway, this.logSink});

  factory GichoLocationService.standard({
    GichoLocationLogSink? logSink,
  }) => GichoLocationService(
    gateway: PlatformGichoLocationGateway(),
    logSink: logSink,
  );

  final GichoLocationGateway gateway;
  final GichoLocationLogSink? logSink;

  bool get isSupportedPlatform => gateway.isSupportedPlatform;

  Future<GichoCoordinates> current({
    GichoLocationRequest request = const GichoLocationRequest(),
  }) async {
    logSink?.call('Location acquisition requested');
    try {
      final result = await gateway.current(request);
      logSink?.call('Location acquisition completed');
      return result;
    } on GichoLocationException catch (error) {
      logSink?.call('Location acquisition failed: ${error.kind.name}');
      rethrow;
    } catch (error, stackTrace) {
      logSink?.call('Location acquisition failed: pluginFailure');
      throw GichoLocationException(
        GichoLocationFailureKind.pluginFailure,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> openAppSettings() => gateway.openAppSettings();

  Future<bool> openLocationSettings() => gateway.openLocationSettings();
}

final class PlatformGichoLocationGateway implements GichoLocationGateway {
  @override
  bool get isSupportedPlatform =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.fuchsia;

  @override
  Future<GichoCoordinates> current(GichoLocationRequest request) async {
    if (!isSupportedPlatform) {
      throw const GichoLocationException(
        GichoLocationFailureKind.unsupported,
      );
    }
    try {
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        throw const GichoLocationException(
          GichoLocationFailureKind.servicesDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const GichoLocationException(
          GichoLocationFailureKind.permissionPermanentlyDenied,
        );
      }
      if (permission == LocationPermission.denied) {
        throw const GichoLocationException(
          GichoLocationFailureKind.permissionDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: switch (request.accuracy) {
            GichoLocationAccuracy.low => LocationAccuracy.low,
            GichoLocationAccuracy.balanced => LocationAccuracy.medium,
            GichoLocationAccuracy.high => LocationAccuracy.high,
          },
          timeLimit: request.timeout,
        ),
      );
      return GichoCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on GichoLocationException {
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      throw GichoLocationException(
        GichoLocationFailureKind.timedOut,
        cause: error,
        stackTrace: stackTrace,
      );
    } on LocationServiceDisabledException catch (error, stackTrace) {
      throw GichoLocationException(
        GichoLocationFailureKind.servicesDisabled,
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw GichoLocationException(
        GichoLocationFailureKind.unavailable,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (!isSupportedPlatform) return false;
    return Geolocator.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() async {
    if (!isSupportedPlatform || kIsWeb) return false;
    return Geolocator.openLocationSettings();
  }
}
