import 'package:flutter/foundation.dart';

/// The atomic value emitted by [DistanceSlider].
@immutable
class DistanceSelectorValue {
  const DistanceSelectorValue._({
    required this.noLimit,
    required this.maximumDistanceKm,
  });

  factory DistanceSelectorValue.finite(int maximumDistanceKm) =>
      DistanceSelectorValue._(
        noLimit: false,
        maximumDistanceKm: maximumDistanceKm,
      );

  const DistanceSelectorValue.noLimit()
    : noLimit = true,
      maximumDistanceKm = null;

  final bool noLimit;
  final int? maximumDistanceKm;

  @override
  bool operator ==(Object other) =>
      other is DistanceSelectorValue &&
      noLimit == other.noLimit &&
      maximumDistanceKm == other.maximumDistanceKm;

  @override
  int get hashCode => Object.hash(noLimit, maximumDistanceKm);
}
