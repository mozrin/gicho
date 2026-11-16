import '../place_lookup_place/index.dart';
import '../place_lookup_suggestion/index.dart';

abstract interface class PlaceLookupProvider {
  Future<List<PlaceLookupSuggestion>> suggest(String query);

  Future<PlaceLookupPlace> resolve(PlaceLookupSuggestion suggestion);
}
