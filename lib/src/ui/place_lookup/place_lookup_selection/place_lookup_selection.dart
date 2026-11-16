import 'dart:math' as math;

import '../place_lookup_place/index.dart';

/// Coordinates deliberately reduced to the precision selected by the app.
final class PlaceLookupSelection {
  const PlaceLookupSelection._({
    required this.latitude,
    required this.longitude,
    required this.accuracyRadiusKm,
    this.placeId,
    this.label,
  });

  factory PlaceLookupSelection.fromPlace(
    PlaceLookupPlace place, {
    double precisionKm = 3,
  }) {
    if (!precisionKm.isFinite || precisionKm < 0) {
      throw ArgumentError.value(precisionKm, 'precisionKm');
    }
    if (precisionKm == 0) {
      return PlaceLookupSelection._(
        latitude: place.latitude,
        longitude: place.longitude,
        accuracyRadiusKm: 0,
        placeId: place.placeId,
        label: place.label,
      );
    }

    // A square of this side length has a half-diagonal of precisionKm.
    final sideKm = precisionKm * math.sqrt2;
    final latitudeStep = sideKm / 111.32;
    final latitude =
        ((place.latitude / latitudeStep).floor() + 0.5) * latitudeStep;
    final boundedLatitude = latitude.clamp(-90.0, 90.0);
    final longitudeKmPerDegree =
        111.32 * math.cos(boundedLatitude * math.pi / 180).abs();
    final longitudeStep = sideKm / math.max(longitudeKmPerDegree, 0.01);
    final longitude =
        ((place.longitude / longitudeStep).floor() + 0.5) * longitudeStep;

    return PlaceLookupSelection._(
      latitude: boundedLatitude,
      longitude: longitude.clamp(-180.0, 180.0),
      accuracyRadiusKm: precisionKm,
    );
  }

  final double latitude;
  final double longitude;
  final double accuracyRadiusKm;

  /// Available only when `accuracyRadiusKm` is zero.
  final String? placeId;

  /// Available only when `accuracyRadiusKm` is zero.
  final String? label;
}
