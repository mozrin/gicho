import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

import 'parts/PlaceLookupMapScreenDemoProvider.dart';

class PlaceLookupMapScreen extends StatefulWidget {
  const PlaceLookupMapScreen({required this.configuration, super.key});

  final Map<String, dynamic> configuration;

  @override
  State<PlaceLookupMapScreen> createState() => _PlaceLookupMapScreenState();
}

class _PlaceLookupMapScreenState extends State<PlaceLookupMapScreen> {
  final _demoProvider = PlaceLookupMapScreenDemoProvider();
  PlaceLookupSelection? _selection;

  bool get _offline =>
      ((widget.configuration['placeLookup']
                      as Map<String, dynamic>?)?['googleApiKey']
                  as String? ??
              '')
          .trim()
          .isEmpty;
  var _draftShowMap = true;
  var _draftGestures = true;
  var _draftZoomControls = true;
  var _draftCoordinates = true;
  var _draftPrecision = 3.0;
  var _draftZoom = 10.0;
  var _draftHeight = 260.0;
  var _showMap = true;
  var _gestures = true;
  var _zoomControls = true;
  var _coordinates = true;
  var _precision = 3.0;
  var _zoom = 10.0;
  var _height = 260.0;
  var _revision = 0;

  void _apply() {
    setState(() {
      _showMap = _draftShowMap;
      _gestures = _draftGestures;
      _zoomControls = _draftZoomControls;
      _coordinates = _draftCoordinates;
      _precision = _draftPrecision;
      _zoom = _draftZoom;
      _height = _draftHeight;
      _selection = null;
      _revision++;
    });
  }

  void _reset() {
    setState(() {
      _draftShowMap = _showMap = true;
      _draftGestures = _gestures = true;
      _draftZoomControls = _zoomControls = true;
      _draftCoordinates = _coordinates = true;
      _draftPrecision = _precision = 3;
      _draftZoom = _zoom = 10;
      _draftHeight = _height = 260;
      _selection = null;
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_offline)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Offline demo: search Bangkok, Auckland or Cairo. '
                    'Google search and maps need your own development key.',
                  ),
                ),
              if (_offline)
                PlaceLookup(
                  key: ValueKey(_revision),
                  provider: _demoProvider,
                  showMap: false,
                  showSelectedCoordinates: _coordinates,
                  coordinatePrecisionKm: _precision,
                  onSelected: (selection) =>
                      setState(() => _selection = selection),
                )
              else
                PlaceLookup.fromConfiguration(
                  key: ValueKey(_revision),
                  configuration: widget.configuration,
                  showMap: _showMap,
                  mapGesturesEnabled: _gestures,
                  showZoomControls: _zoomControls,
                  showSelectedCoordinates: _coordinates,
                  coordinatePrecisionKm: _precision,
                  initialZoom: _zoom,
                  mapHeight: _height,
                  onSelected: (selection) =>
                      setState(() => _selection = selection),
                ),
              if (_selection != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Returned area: ${_selection!.latitude}, ${_selection!.longitude} '
                  '(within ${_selection!.accuracyRadiusKm} km)',
                ),
                Text('Exact place ID returned: ${_selection!.placeId != null}'),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Development parameters',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Apply these options to restart the lookup control. Reset restores this example’s defaults.',
              ),
              SwitchListTile(
                title: const Text('Show map'),
                value: _draftShowMap,
                onChanged: _offline
                    ? null
                    : (value) => setState(() => _draftShowMap = value),
              ),
              SwitchListTile(
                title: const Text('Map gestures'),
                value: _draftGestures,
                onChanged: _draftShowMap
                    ? (value) => setState(() => _draftGestures = value)
                    : null,
              ),
              SwitchListTile(
                title: const Text('Zoom controls'),
                value: _draftZoomControls,
                onChanged: _draftShowMap
                    ? (value) => setState(() => _draftZoomControls = value)
                    : null,
              ),
              SwitchListTile(
                title: const Text('Show selected coordinates'),
                value: _draftCoordinates,
                onChanged: (value) => setState(() => _draftCoordinates = value),
              ),
              _optionSlider(
                'Coordinate privacy radius (km)',
                _draftPrecision,
                0,
                10,
                10,
                (value) => setState(() => _draftPrecision = value),
              ),
              _optionSlider(
                'Initial map zoom',
                _draftZoom,
                3,
                18,
                15,
                (value) => setState(() => _draftZoom = value),
              ),
              _optionSlider(
                'Map height (px)',
                _draftHeight,
                180,
                480,
                15,
                (value) => setState(() => _draftHeight = value),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(onPressed: _apply, child: const Text('Apply')),
                  OutlinedButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _optionSlider(
    String name,
    double value,
    double minimum,
    double maximum,
    int divisions,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$name: ${value.round()}'),
      Slider(
        value: value,
        min: minimum,
        max: maximum,
        divisions: divisions,
        label: value.round().toString(),
        onChanged: onChanged,
      ),
    ],
  );
}
