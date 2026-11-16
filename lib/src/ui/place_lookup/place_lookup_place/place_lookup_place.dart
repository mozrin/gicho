final class PlaceLookupPlace {
  const PlaceLookupPlace({
    required this.providerId,
    required this.placeId,
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String providerId;
  final String placeId;
  final String label;
  final double latitude;
  final double longitude;
}
