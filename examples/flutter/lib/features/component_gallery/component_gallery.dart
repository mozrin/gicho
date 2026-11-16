import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

import '../startup_demo/index.dart';

class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key, required this.locales});

  final GichoLocaleController locales;

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  var _increment = 5;
  var _incrementThreshold = 20;
  var _minimumDistance = 1;
  var _maximumDistance = 300;
  var _defaultDistance = 1;
  var _allowNoLimit = true;
  DistanceUnit? _unit = DistanceUnit.kilometres;
  var _enabled = true;
  String? _label = 'Maximum distance';
  var _value = DistanceSelectorValue.finite(1);

  void _reset() =>
      setState(() => _value = DistanceSelectorValue.finite(_defaultDistance));

  void _setAllowNoLimit(bool value) => setState(() {
    _allowNoLimit = value;
    if (!value && _value.noLimit) {
      _value = DistanceSelectorValue.finite(_defaultDistance);
    }
  });

  void _setRange({int? minimumDistance, int? maximumDistance}) => setState(() {
    _minimumDistance = minimumDistance ?? _minimumDistance;
    _maximumDistance = maximumDistance ?? _maximumDistance;
    _defaultDistance = _defaultDistance.clamp(
      _minimumDistance,
      _maximumDistance,
    );
    if (!_value.noLimit) {
      _value = DistanceSelectorValue.finite(
        _value.maximumDistanceKm!.clamp(_minimumDistance, _maximumDistance),
      );
    }
  });

  @override
  Widget build(BuildContext context) => GichoAppShell(
    title: 'Gicho gallery',
    locales: widget.locales,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.tune_outlined),
        label: 'Distance slider',
      ),
      NavigationDestination(
        icon: Icon(Icons.rocket_launch_outlined),
        label: 'Startup demo',
      ),
    ],
    selectedIndex: 0,
    onDestinationSelected: (index) {
      if (index == 1) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StartupDemo(locales: widget.locales),
          ),
        );
      }
    },
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const GichoModalPage(
              title: 'About this gallery',
              body: Center(child: Text('Gicho component examples')),
            ),
          ),
        ),
        child: const Text('About'),
      ),
      TextButton.icon(
        onPressed: _reset,
        icon: const Icon(Icons.restart_alt),
        label: const Text('Reset'),
      ),
    ],
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              'Distance slider',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('A resettable playground for component API settings.'),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DistanceSlider(
                  key: ValueKey<Object>((
                    increment: _increment,
                    threshold: _incrementThreshold,
                    minimum: _minimumDistance,
                    maximum: _maximumDistance,
                    defaultDistance: _defaultDistance,
                    allowNoLimit: _allowNoLimit,
                    unit: _unit,
                    label: _label,
                  )),
                  value: _value,
                  onChanged: (value) => setState(() => _value = value),
                  minimumDistance: _minimumDistance,
                  maximumDistance: _maximumDistance,
                  enabled: _enabled,
                  label: _label,
                  increment: _increment,
                  incrementThreshold: _incrementThreshold,
                  defaultDistance: _defaultDistance,
                  allowNoLimit: _allowNoLimit,
                  unit: _unit,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _label,
                      decoration: const InputDecoration(labelText: 'Label'),
                      items: const <DropdownMenuItem<String?>>[
                        DropdownMenuItem(
                          value: 'Maximum distance',
                          child: Text('Maximum distance'),
                        ),
                        DropdownMenuItem(
                          value: 'Search radius',
                          child: Text('Search radius'),
                        ),
                        DropdownMenuItem(value: null, child: Text('No label')),
                      ],
                      onChanged: (value) => setState(() => _label = value),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _increment,
                      decoration: const InputDecoration(
                        labelText: 'Slider increment',
                      ),
                      items: <int>[1, 5, 10, 25]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value km'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _increment = value!),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _minimumDistance,
                      decoration: const InputDecoration(
                        labelText: 'Minimum distance',
                      ),
                      items: <int>[0, 1, 25]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => _setRange(minimumDistance: value!),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _maximumDistance,
                      decoration: const InputDecoration(
                        labelText: 'Maximum distance',
                      ),
                      items: <int>[100, 300, 500]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => _setRange(maximumDistance: value!),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _incrementThreshold,
                      decoration: const InputDecoration(
                        labelText: 'One-kilometre steps through',
                      ),
                      items: <int>[0, 20, 50]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value == 0 ? 'Start at increment' : '$value km',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _incrementThreshold = value!),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _defaultDistance,
                      decoration: const InputDecoration(
                        labelText: 'Default distance',
                      ),
                      items: <int>[1, 25, 52, 100]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value km'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _defaultDistance = value!;
                        _value = DistanceSelectorValue.finite(_defaultDistance);
                      }),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow no limit'),
                      value: _allowNoLimit,
                      onChanged: _setAllowNoLimit,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable component'),
                      value: _enabled,
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                    DropdownButtonFormField<DistanceUnit?>(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit label',
                      ),
                      items: const <DropdownMenuItem<DistanceUnit?>>[
                        DropdownMenuItem(value: null, child: Text('No label')),
                        DropdownMenuItem(
                          value: DistanceUnit.kilometres,
                          child: Text('km'),
                        ),
                        DropdownMenuItem(
                          value: DistanceUnit.miles,
                          child: Text('m'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _unit = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _value.noLimit
                  ? 'Saved value: no maximum distance'
                  : 'Saved value: ${_formatDistance(_value.maximumDistanceKm!)}',
            ),
          ],
        ),
      ),
    ),
  );

  String _formatDistance(int value) => _unit == null
      ? '$value'
      : '${_unit!.formatDisplayValue(value)} ${_unit!.symbol}';
}
