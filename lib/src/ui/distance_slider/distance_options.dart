const minimumDistanceKm = 1;
const maximumDistanceKm = 500;

/// The optional suffix displayed by [DistanceSlider].
enum DistanceUnit { kilometres, miles }

extension DistanceUnitFormatting on DistanceUnit {
  String get symbol => this == DistanceUnit.kilometres ? 'km' : 'm';

  String formatDisplayValue(int value) => '$value';
}

/// The default slider stops: 1 km steps through 20, then 5 km steps.
final List<int> distanceOptions = distanceOptionsForIncrement(5);

/// Produces finite slider stops for a positive [increment].
///
/// Values advance by one through [incrementThreshold], then use multiples of
/// [increment]. The minimum and maximum remain selectable boundaries. Set
/// [incrementThreshold] to zero or null to start at the increment stops.
List<int> distanceOptionsForIncrement(
  int increment, {
  int? incrementThreshold = 20,
  int minimum = minimumDistanceKm,
  int maximum = maximumDistanceKm,
}) {
  if (increment <= 0) {
    throw ArgumentError.value(
      increment,
      'increment',
      'Must be greater than zero.',
    );
  }

  if (minimum < 0 || maximum < minimum) {
    throw ArgumentError('Maximum must be greater than or equal to minimum.');
  }
  if (incrementThreshold != null &&
      (incrementThreshold < 0 || incrementThreshold > maximum)) {
    throw ArgumentError.value(
      incrementThreshold,
      'incrementThreshold',
      'Must be null or between zero and $maximum.',
    );
  }

  final threshold = incrementThreshold ?? 0;
  final options = <int>[minimum];
  for (
    var value = minimum + 1;
    value <= threshold && value < maximum;
    value++
  ) {
    options.add(value);
  }
  for (
    var value =
        ((threshold > minimum ? threshold : minimum) ~/ increment + 1) *
        increment;
    value < maximum;
    value += increment
  ) {
    if (value > minimum) options.add(value);
  }
  if (options.last != maximum) options.add(maximum);
  return List<int>.unmodifiable(options);
}

/// Constrains an arbitrary distance to the supported manual-entry range.
int clampDistanceKm(
  int value, {
  int minimum = minimumDistanceKm,
  int maximum = maximumDistanceKm,
}) => value.clamp(minimum, maximum);

/// Converts arbitrary numeric input to the nearest supported slider value.
int normalizeDistanceKm(
  int value, {
  int increment = 5,
  int? incrementThreshold = 20,
}) {
  final constrained = clampDistanceKm(value);
  return distanceOptionsForIncrement(
    increment,
    incrementThreshold: incrementThreshold,
  ).reduce(
    (closest, candidate) =>
        constrained - closest <= candidate - constrained ? closest : candidate,
  );
}
