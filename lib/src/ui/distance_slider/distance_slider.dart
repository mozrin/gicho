import 'package:flutter/material.dart';

import 'distance_editor.dart';
import 'distance_options.dart';
import 'distance_selector_value.dart';
import 'distance_slider_content.dart';

/// A controlled distance selector.
///
/// The parent owns [value] and must replace it in response to [onChanged].
class DistanceSlider extends StatefulWidget {
  DistanceSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required int maximumDistance,
    int minimumDistance = minimumDistanceKm,
    this.enabled = true,
    this.label = 'Maximum distance',
    this.noLimitLabel = 'No limit',
    this.setLabel = 'Set',
    this.cancelLabel = 'Cancel',
    int increment = 5,
    int? incrementThreshold = 20,
    int defaultDistance = minimumDistanceKm,
    this.allowNoLimit = true,
    this.unit = DistanceUnit.kilometres,
  }) : increment = _validateIncrement(increment),
       minimumDistance = _validateMinimumDistance(minimumDistance),
       maximumDistance = _validateMaximumDistance(
         minimumDistance,
         maximumDistance,
       ),
       incrementThreshold = _validateIncrementThreshold(
         incrementThreshold,
         maximumDistance,
       ),
       defaultDistance = _validateDefaultDistance(
         defaultDistance,
         minimumDistance,
         maximumDistance,
       );

  final DistanceSelectorValue value;
  final ValueChanged<DistanceSelectorValue> onChanged;
  final int minimumDistance;
  final int maximumDistance;
  final bool enabled;
  final String? label;
  final String noLimitLabel;
  final String setLabel;
  final String cancelLabel;
  final int increment;
  final int? incrementThreshold;
  final int defaultDistance;
  final bool allowNoLimit;
  final DistanceUnit? unit;

  static int _validateIncrement(int value) {
    if (value <= 0) {
      throw ArgumentError.value(
        value,
        'increment',
        'Must be greater than zero.',
      );
    }
    return value;
  }

  static int _validateMinimumDistance(int value) {
    if (value < 0) {
      throw ArgumentError.value(
        value,
        'minimumDistance',
        'Must not be negative.',
      );
    }
    return value;
  }

  static int _validateMaximumDistance(int minimum, int maximum) {
    if (maximum < minimum) {
      throw ArgumentError.value(
        maximum,
        'maximumDistance',
        'Must be greater than or equal to minimumDistance.',
      );
    }
    return maximum;
  }

  static int? _validateIncrementThreshold(int? value, int maximum) {
    if (value != null && (value < 0 || value > maximum)) {
      throw ArgumentError.value(
        value,
        'incrementThreshold',
        'Must be null or between zero and $maximum.',
      );
    }
    return value;
  }

  static int _validateDefaultDistance(int value, int minimum, int maximum) {
    if (value < minimum || value > maximum) {
      throw ArgumentError.value(
        value,
        'defaultDistance',
        'Must be between $minimum and $maximum.',
      );
    }
    return value;
  }

  @override
  State<DistanceSlider> createState() => _DistanceSliderState();
}

class _DistanceSliderState extends State<DistanceSlider> {
  final FocusNode _editFocusNode = FocusNode();
  late int _rememberedFiniteValue;

  @override
  void initState() {
    super.initState();
    _rememberedFiniteValue = widget.value.maximumDistanceKm == null
        ? widget.defaultDistance
        : _clampDistance(widget.value.maximumDistanceKm!);
  }

  @override
  void didUpdateWidget(covariant DistanceSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.value.noLimit && widget.value.maximumDistanceKm != null) {
      _rememberedFiniteValue = _clampDistance(widget.value.maximumDistanceKm!);
    } else if (oldWidget.defaultDistance != widget.defaultDistance) {
      _rememberedFiniteValue = widget.defaultDistance;
    }
  }

  @override
  void dispose() {
    _editFocusNode.dispose();
    super.dispose();
  }

  int get _finiteValue =>
      _clampDistance(widget.value.maximumDistanceKm ?? _rememberedFiniteValue);

  void _setFiniteValue(int value) {
    final constrained = _clampDistance(value);
    if (!widget.value.noLimit && constrained == _finiteValue) return;
    _rememberedFiniteValue = constrained;
    widget.onChanged(DistanceSelectorValue.finite(constrained));
  }

  void _setNoLimit(bool noLimit) {
    if (noLimit) {
      _rememberedFiniteValue = _finiteValue;
      widget.onChanged(const DistanceSelectorValue.noLimit());
      return;
    }
    _setFiniteValue(_rememberedFiniteValue);
  }

  Future<void> _editDistance() async {
    final result = await editDistance(
      context: context,
      initialValue: _finiteValue,
      title: 'Edit ${widget.label?.toLowerCase() ?? 'distance'}',
      setLabel: widget.setLabel,
      cancelLabel: widget.cancelLabel,
      unit: widget.unit,
      minimumDistance: widget.minimumDistance,
      maximumDistance: widget.maximumDistance,
    );
    if (!mounted) return;
    _editFocusNode.requestFocus();
    if (result != null) _setFiniteValue(result);
  }

  @override
  Widget build(BuildContext context) => DistanceSliderContent(
    label: widget.label,
    noLimitLabel: widget.noLimitLabel,
    finiteValue: _finiteValue,
    minimumDistance: widget.minimumDistance,
    maximumDistance: widget.maximumDistance,
    noLimit: widget.allowNoLimit && widget.value.noLimit,
    enabled: widget.enabled,
    allowNoLimit: widget.allowNoLimit,
    unit: widget.unit,
    options: distanceOptionsForIncrement(
      widget.increment,
      incrementThreshold: widget.incrementThreshold,
      minimum: widget.minimumDistance,
      maximum: widget.maximumDistance,
    ),
    editFocusNode: _editFocusNode,
    onFiniteValueChanged: _setFiniteValue,
    onNoLimitChanged: _setNoLimit,
    onEdit: _editDistance,
  );

  int _clampDistance(int value) => clampDistanceKm(
    value,
    minimum: widget.minimumDistance,
    maximum: widget.maximumDistance,
  );
}
