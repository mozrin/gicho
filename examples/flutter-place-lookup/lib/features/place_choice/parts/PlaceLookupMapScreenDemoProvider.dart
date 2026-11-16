// TODO: Recheck file_names against required parent-prefixed parts; review 2027-05-16
// ignore_for_file: file_names

import 'package:gicho/gicho.dart';

final class PlaceLookupMapScreenDemoProvider implements PlaceLookupProvider {
  static const _places = <PlaceLookupPlace>[
    PlaceLookupPlace(
      providerId: 'demo',
      placeId: 'bangkok',
      label: 'Bangkok',
      latitude: 13.7563,
      longitude: 100.5018,
    ),
    PlaceLookupPlace(
      providerId: 'demo',
      placeId: 'auckland',
      label: 'Auckland',
      latitude: -36.8485,
      longitude: 174.7633,
    ),
    PlaceLookupPlace(
      providerId: 'demo',
      placeId: 'cairo',
      label: 'Cairo',
      latitude: 30.0444,
      longitude: 31.2357,
    ),
  ];

  @override
  Future<List<PlaceLookupSuggestion>> suggest(String query) async => [
    for (final place in _places)
      if (place.label.toLowerCase().contains(query.trim().toLowerCase()))
        PlaceLookupSuggestion(
          providerId: place.providerId,
          placeId: place.placeId,
          title: place.label,
          subtitle: 'Offline sample city',
          sessionId: 'demo',
        ),
  ];

  @override
  Future<PlaceLookupPlace> resolve(PlaceLookupSuggestion suggestion) async =>
      _places.firstWhere((place) => place.placeId == suggestion.placeId);
}
