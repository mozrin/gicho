import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../place_lookup_place/index.dart';
import '../place_lookup_provider/index.dart';
import '../place_lookup_suggestion/index.dart';

/// Development Google Places adapter for the shared place lookup control.
final class GooglePlaceLookupProvider implements PlaceLookupProvider {
  GooglePlaceLookupProvider({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client() {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'A Google key is required');
    }
    if (kReleaseMode) {
      throw StateError(
        'Bundled Google Places keys are blocked in release mode. '
        'Configure a secure provider before deployment.',
      );
    }
  }

  final String apiKey;
  final http.Client _client;
  String? _sessionId;

  @override
  Future<List<PlaceLookupSuggestion>> suggest(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    final session = _sessionId ??= _newSession();
    final response = await _client.post(
      Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
      },
      body: jsonEncode({'input': query, 'sessionToken': session}),
    );
    if (response.statusCode != 200) {
      throw StateError('Google Places search failed (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final predictions = data['suggestions'] as List<dynamic>? ?? [];
    return [
      for (final item in predictions)
        if (item is Map<String, dynamic> &&
            item['placePrediction'] is Map<String, dynamic>)
          _suggestion(item['placePrediction'] as Map<String, dynamic>, session),
    ];
  }

  PlaceLookupSuggestion _suggestion(
    Map<String, dynamic> prediction,
    String session,
  ) {
    final formatted = prediction['structuredFormat'] as Map<String, dynamic>?;
    final main = formatted?['mainText'] as Map<String, dynamic>?;
    final secondary = formatted?['secondaryText'] as Map<String, dynamic>?;
    final text = prediction['text'] as Map<String, dynamic>?;
    return PlaceLookupSuggestion(
      providerId: 'google',
      placeId: prediction['placeId'] as String,
      title: (main?['text'] ?? text?['text']) as String,
      subtitle: secondary?['text'] as String? ?? '',
      sessionId: session,
    );
  }

  @override
  Future<PlaceLookupPlace> resolve(PlaceLookupSuggestion suggestion) async {
    final response = await _client.get(
      Uri.https('places.googleapis.com', '/v1/places/${suggestion.placeId}', {
        'sessionToken': suggestion.sessionId,
      }),
      headers: {
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'id,displayName,location',
      },
    );
    if (response.statusCode != 200) {
      throw StateError('Google place lookup failed (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>;
    final displayName = data['displayName'] as Map<String, dynamic>;
    _sessionId = null;
    return PlaceLookupPlace(
      providerId: 'google',
      placeId: data['id'] as String,
      label: displayName['text'] as String,
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
    );
  }

  void close() => _client.close();

  String _newSession() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
