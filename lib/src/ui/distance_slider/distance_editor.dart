import 'package:flutter/material.dart';

import 'distance_options.dart';

Future<int?> editDistance({
  required BuildContext context,
  required int initialValue,
  required String title,
  required String setLabel,
  required String cancelLabel,
  required DistanceUnit? unit,
  required int minimumDistance,
  required int maximumDistance,
}) async {
  return showDialog<int>(
    context: context,
    builder: (_) => _DistanceEditorDialog(
      initialValue: initialValue,
      title: title,
      setLabel: setLabel,
      cancelLabel: cancelLabel,
      unit: unit,
      minimumDistance: minimumDistance,
      maximumDistance: maximumDistance,
    ),
  );
}

class _DistanceEditorDialog extends StatefulWidget {
  const _DistanceEditorDialog({
    required this.initialValue,
    required this.title,
    required this.setLabel,
    required this.cancelLabel,
    required this.unit,
    required this.minimumDistance,
    required this.maximumDistance,
  });

  final int initialValue;
  final String title;
  final String setLabel;
  final String cancelLabel;
  final DistanceUnit? unit;
  final int minimumDistance;
  final int maximumDistance;

  @override
  State<_DistanceEditorDialog> createState() => _DistanceEditorDialogState();
}

class _DistanceEditorDialogState extends State<_DistanceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialValue}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(int.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: widget.unit == null
              ? 'Distance'
              : 'Distance (${widget.unit!.symbol})',
          hintText: '${widget.minimumDistance}–${widget.maximumDistance}',
        ),
        validator: _validateDistance,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(widget.cancelLabel),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.setLabel)),
    ],
  );

  String? _validateDistance(String? text) {
    final value = text == null ? null : int.tryParse(text.trim());
    if (value == null) return 'Enter a whole-number distance.';
    if (value < widget.minimumDistance || value > widget.maximumDistance) {
      final suffix = widget.unit == null ? '' : ' ${widget.unit!.symbol}';
      return 'Enter a distance from ${widget.minimumDistance} to ${widget.maximumDistance}$suffix.';
    }
    return null;
  }
}
