final class PlaceLookupSuggestion {
  const PlaceLookupSuggestion({
    required this.providerId,
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.sessionId,
  });

  final String providerId;
  final String placeId;
  final String title;
  final String subtitle;
  final String sessionId;
}
