import 'package:flutter/material.dart';

import 'distance_options.dart';

class DistanceSliderContent extends StatelessWidget {
  const DistanceSliderContent({
    super.key,
    required this.label,
    required this.noLimitLabel,
    required this.finiteValue,
    required this.minimumDistance,
    required this.maximumDistance,
    required this.noLimit,
    required this.enabled,
    required this.allowNoLimit,
    required this.unit,
    required this.options,
    required this.editFocusNode,
    required this.onFiniteValueChanged,
    required this.onNoLimitChanged,
    required this.onEdit,
  });

  final String? label;
  final String noLimitLabel;
  final int finiteValue;
  final int minimumDistance;
  final int maximumDistance;
  final bool noLimit;
  final bool enabled;
  final bool allowNoLimit;
  final DistanceUnit? unit;
  final List<int> options;
  final FocusNode editFocusNode;
  final ValueChanged<int> onFiniteValueChanged;
  final ValueChanged<bool> onNoLimitChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final finiteControlsEnabled = enabled && !noLimit;
    final index = _nearestDistanceOptionIndex(finiteValue, options);
    final displayValue = _formatDistance(finiteValue);
    final semanticLabel = label ?? 'Distance selector';
    final currentControlWidth = _currentControlWidth(context);

    return Semantics(
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label != null || allowNoLimit) ...<Widget>[
            LayoutBuilder(
              builder: (context, constraints) => Row(
                children: <Widget>[
                  Expanded(
                    child: label == null
                        ? const SizedBox.shrink()
                        : Text(
                            label!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                  ),
                  if (allowNoLimit) ...<Widget>[
                    if (label != null) const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: label == null
                            ? constraints.maxWidth
                            : constraints.maxWidth * 0.55,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Semantics(
                            label: noLimitLabel,
                            child: Switch(
                              value: noLimit,
                              onChanged: enabled ? onNoLimitChanged : null,
                            ),
                          ),
                          Flexible(child: Text(noLimitLabel)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final editControlWidth = currentControlWidth
                  .clamp(0.0, constraints.maxWidth * 0.45)
                  .toDouble();

              return Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Semantics(
                          label: semanticLabel,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              tickMarkShape: SliderTickMarkShape.noTickMark,
                            ),
                            child: Slider(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              value: index.toDouble(),
                              min: 0,
                              max: (options.length - 1).toDouble(),
                              divisions: options.length > 1
                                  ? options.length - 1
                                  : null,
                              label: displayValue,
                              semanticFormatterCallback: (position) =>
                                  _formatDistance(options[position.round()]),
                              onChanged:
                                  finiteControlsEnabled && options.length > 1
                                  ? (index) => onFiniteValueChanged(
                                      _nextDistance(options[index.round()]),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _formatDistance(minimumDistance),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatDistance(maximumDistance),
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: noLimit
                        ? '$semanticLabel, $noLimitLabel.'
                        : '$semanticLabel, $displayValue. Edit.',
                    button: true,
                    enabled: finiteControlsEnabled,
                    child: SizedBox(
                      key: const ValueKey<String>(
                        'distance-slider-current-value',
                      ),
                      width: editControlWidth,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(48, 48),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        focusNode: editFocusNode,
                        onPressed: finiteControlsEnabled ? onEdit : null,
                        icon: noLimit
                            ? null
                            : const Icon(Icons.edit_outlined, size: 18),
                        label: Text(noLimit ? '∞' : displayValue),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDistance(int value) => unit == null
      ? '$value'
      : '${unit!.formatDisplayValue(value)} ${unit!.symbol}';

  int _nextDistance(int selected) {
    // A manual value or changed increment can leave the current value between
    // stops. The first movement must reach the adjacent stop, even when the
    // thumb is drawn at the nearest stop's position already.
    if (options.contains(finiteValue)) return selected;
    if (selected > finiteValue) {
      return options.firstWhere((value) => value > finiteValue);
    }
    return options.lastWhere((value) => value < finiteValue);
  }

  double _currentControlWidth(BuildContext context) {
    final textStyle =
        Theme.of(context).textTheme.labelLarge ??
        DefaultTextStyle.of(context).style;
    // Reserve the widest digit at every position so dragging never resizes
    // the value control or changes the slider's available track length.
    var width = 0.0;
    for (var digit = 0; digit <= 9; digit++) {
      final longestLabel =
          '${'$digit' * maximumDistance.toString().length}${unit == null ? '' : ' ${unit!.symbol}'}';
      final painter = TextPainter(
        text: TextSpan(text: longestLabel, style: textStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();

      if (painter.width > width) width = painter.width;
      painter.dispose();
    }
    return width + 18 + 8 + 16;
  }
}

int _nearestDistanceOptionIndex(int value, List<int> options) {
  for (var index = 1; index < options.length; index++) {
    final lower = options[index - 1];
    final upper = options[index];
    if (value <= upper) {
      return value - lower <= upper - value ? index - 1 : index;
    }
  }
  return options.length - 1;
}
