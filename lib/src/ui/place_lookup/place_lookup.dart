import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'google_place_lookup_provider/index.dart';
import 'place_lookup_provider/index.dart';
import 'place_lookup_selection/index.dart';
import 'place_lookup_suggestion/index.dart';

/// Selects a real place from a provider and shows it on a Google map.
class PlaceLookup extends StatefulWidget {
  const PlaceLookup({
    required this.provider,
    required this.onSelected,
    this.showMap = true,
    this.mapGesturesEnabled = true,
    this.showZoomControls = true,
    this.showSelectedCoordinates = false,
    this.coordinatePrecisionKm = 3,
    this.searchLabel = 'Search for a city, address, or place',
    this.initialLatitude = -36.8485,
    this.initialLongitude = 174.7633,
    this.initialZoom = 10,
    this.mapHeight = 260,
    super.key,
  }) : _ownsProvider = false;

  PlaceLookup.fromConfiguration({
    required Map<String, dynamic> configuration,
    required this.onSelected,
    this.showMap = true,
    this.mapGesturesEnabled = true,
    this.showZoomControls = true,
    this.showSelectedCoordinates = false,
    this.coordinatePrecisionKm = 3,
    this.searchLabel = 'Search for a city, address, or place',
    this.initialLatitude = -36.8485,
    this.initialLongitude = 174.7633,
    this.initialZoom = 10,
    this.mapHeight = 260,
    super.key,
  }) : provider = GooglePlaceLookupProvider(
         apiKey:
             (configuration['placeLookup']
                     as Map<String, dynamic>?)?['googleApiKey']
                 as String? ??
             '',
       ),
       _ownsProvider = true;

  final PlaceLookupProvider provider;
  final ValueChanged<PlaceLookupSelection> onSelected;
  final bool showMap;
  final bool mapGesturesEnabled;
  final bool showZoomControls;
  final bool showSelectedCoordinates;
  final double coordinatePrecisionKm;
  final String searchLabel;
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final double mapHeight;
  final bool _ownsProvider;

  @override
  State<PlaceLookup> createState() => _PlaceLookupState();
}

class _PlaceLookupState extends State<PlaceLookup> {
  final _controller = TextEditingController();
  GoogleMapController? _mapController;
  Timer? _debounce;
  List<PlaceLookupSuggestion> _suggestions = [];
  PlaceLookupSelection? _selected;
  String? _error;
  bool _searching = false;
  bool _searched = false;
  int _requestId = 0;

  @override
  void didUpdateWidget(covariant PlaceLookup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.provider, widget.provider)) {
      _requestId++;
      _debounce?.cancel();
      if (oldWidget._ownsProvider &&
          oldWidget.provider is GooglePlaceLookupProvider) {
        (oldWidget.provider as GooglePlaceLookupProvider).close();
      }
    }
    if (oldWidget.showMap && !widget.showMap) {
      _mapController = null;
    }
  }

  void _queryChanged(String value) {
    _debounce?.cancel();
    final requestId = ++_requestId;
    setState(() {
      _suggestions = [];
      _selected = null;
      _error = null;
      _searching = value.trim().isNotEmpty;
      _searched = false;
    });
    if (value.trim().isEmpty) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(value.trim(), requestId);
    });
  }

  Future<void> _search(String value, int requestId) async {
    try {
      final suggestions = await widget.provider.suggest(value);
      if (mounted && requestId == _requestId) {
        setState(() {
          _suggestions = suggestions;
          _searching = false;
          _searched = true;
        });
      }
    } catch (_) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _error = 'Place search failed. Check your connection and API setup.';
          _searching = false;
        });
      }
    }
  }

  Future<void> _select(PlaceLookupSuggestion suggestion) async {
    final requestId = ++_requestId;
    _debounce?.cancel();
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final place = await widget.provider.resolve(suggestion);
      if (mounted && requestId == _requestId) {
        final selection = PlaceLookupSelection.fromPlace(
          place,
          precisionKm: widget.coordinatePrecisionKm,
        );
        _controller.text = place.label;
        setState(() {
          _selected = selection;
          _suggestions = [];
          _searching = false;
          _searched = false;
        });
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(selection.latitude, selection.longitude),
            selection.accuracyRadiusKm == 0 ? 14 : 11,
          ),
        );
        widget.onSelected(selection);
      }
    } catch (_) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _error = 'Could not load that place.';
          _searching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _requestId++;
    _debounce?.cancel();
    _controller.dispose();
    if (widget._ownsProvider && widget.provider is GooglePlaceLookupProvider) {
      (widget.provider as GooglePlaceLookupProvider).close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.showMap)
        SizedBox(
          height: widget.mapHeight,
          child:
              !kIsWeb &&
                  defaultTargetPlatform != TargetPlatform.android &&
                  defaultTargetPlatform != TargetPlatform.iOS
              ? const Center(
                  child: Text(
                    'Google map preview is unavailable on this platform.',
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.initialLatitude,
                      widget.initialLongitude,
                    ),
                    zoom: widget.initialZoom,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  scrollGesturesEnabled: widget.mapGesturesEnabled,
                  zoomGesturesEnabled: widget.mapGesturesEnabled,
                  rotateGesturesEnabled: widget.mapGesturesEnabled,
                  tiltGesturesEnabled: widget.mapGesturesEnabled,
                  markers: _selected == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('selected-area'),
                            position: LatLng(
                              _selected!.latitude,
                              _selected!.longitude,
                            ),
                            infoWindow: InfoWindow(
                              title: _selected!.accuracyRadiusKm == 0
                                  ? _selected!.label
                                  : 'Approximate area',
                            ),
                          ),
                        },
                  circles: _selected == null || _selected!.accuracyRadiusKm == 0
                      ? {}
                      : {
                          Circle(
                            circleId: const CircleId('selected-area'),
                            center: LatLng(
                              _selected!.latitude,
                              _selected!.longitude,
                            ),
                            radius: _selected!.accuracyRadiusKm * 1000,
                            fillColor: Colors.blue.withValues(alpha: 0.15),
                            strokeColor: Colors.blue,
                          ),
                        },
                  zoomControlsEnabled: widget.showZoomControls,
                  myLocationButtonEnabled: false,
                ),
        ),
      if (widget.showMap) const SizedBox(height: 12),
      TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.searchLabel,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
        onChanged: _queryChanged,
      ),
      if (_searching) const LinearProgressIndicator(),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (_searched && _suggestions.isEmpty)
        const Text('No places found. Try another search.'),
      for (final suggestion in _suggestions)
        ListTile(
          title: Text(suggestion.title),
          subtitle: Text(suggestion.subtitle),
          onTap: () => _select(suggestion),
        ),
      if (_suggestions.isNotEmpty) const Text('Google Maps'),
      if (_selected != null && widget.showSelectedCoordinates)
        Text(
          'Selected area: ${_selected!.latitude}, ${_selected!.longitude} '
          '(within ${_selected!.accuracyRadiusKm} km)',
        ),
    ],
  );
}
