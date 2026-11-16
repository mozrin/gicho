import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

class DistanceSelection extends StatefulWidget {
  const DistanceSelection({super.key});

  @override
  State<DistanceSelection> createState() => _DistanceSelectionState();
}

class _DistanceSelectionState extends State<DistanceSelection> {
  var _value = DistanceSelectorValue.finite(10);
  var _draftMaximum = 100.0;
  var _draftIncrement = 5.0;
  var _draftThreshold = 20.0;
  var _draftNoLimit = true;
  var _draftEnabled = true;
  var _maximum = 100.0;
  var _increment = 5.0;
  var _threshold = 20.0;
  var _allowNoLimit = true;
  var _enabled = true;
  var _revision = 0;

  void _apply() {
    setState(() {
      _maximum = _draftMaximum;
      _increment = _draftIncrement;
      _threshold = _draftThreshold;
      _allowNoLimit = _draftNoLimit;
      _enabled = _draftEnabled;
      final finite = _value.maximumDistanceKm;
      if (finite != null) {
        _value = DistanceSelectorValue.finite(
          finite.clamp(1, _maximum.round()),
        );
      } else if (!_allowNoLimit) {
        _value = DistanceSelectorValue.finite(10);
      }
      _revision++;
    });
  }

  void _reset() {
    setState(() {
      _draftMaximum = _maximum = 100;
      _draftIncrement = _increment = 5;
      _draftThreshold = _threshold = 20;
      _draftNoLimit = _allowNoLimit = true;
      _draftEnabled = _enabled = true;
      _value = DistanceSelectorValue.finite(10);
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DistanceSlider(
                key: ValueKey(_revision),
                value: _value,
                maximumDistance: _maximum.round(),
                increment: _increment.round(),
                incrementThreshold: _threshold.round(),
                allowNoLimit: _allowNoLimit,
                enabled: _enabled,
                onChanged: (value) => setState(() => _value = value),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Development parameters',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      _optionSlider(
                        'Maximum distance (km)',
                        _draftMaximum,
                        50,
                        500,
                        45,
                        (value) => setState(() {
                          _draftMaximum = value;
                          _draftThreshold = _draftThreshold.clamp(0, value);
                        }),
                      ),
                      _optionSlider(
                        'Step size (km)',
                        _draftIncrement,
                        1,
                        25,
                        24,
                        (value) => setState(() => _draftIncrement = value),
                      ),
                      _optionSlider(
                        'Fine steps through (km)',
                        _draftThreshold,
                        0,
                        _draftMaximum,
                        _draftMaximum.round(),
                        (value) => setState(() => _draftThreshold = value),
                      ),
                      SwitchListTile(
                        title: const Text('Allow no limit'),
                        value: _draftNoLimit,
                        onChanged: (value) =>
                            setState(() => _draftNoLimit = value),
                      ),
                      SwitchListTile(
                        title: const Text('Enabled'),
                        value: _draftEnabled,
                        onChanged: (value) =>
                            setState(() => _draftEnabled = value),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton(
                            onPressed: _apply,
                            child: const Text('Apply'),
                          ),
                          OutlinedButton(
                            onPressed: _reset,
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$name: ${value.round()}'),
        const SizedBox(height: 4),
        Slider(
          value: value,
          min: minimum,
          max: maximum,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
