import 'package:flutter/material.dart';

/// One country-specific address field supplied by the contact rules package.
class StructuredPostalAddressField {
  const StructuredPostalAddressField({
    required this.keyName,
    required this.label,
    required this.required,
    this.maxLines = 1,
  });

  final String keyName;
  final String label;
  final bool required;
  final int maxLines;
}

/// Renders the fields and labels selected for the current postal country.
class StructuredPostalAddressFields extends StatelessWidget {
  const StructuredPostalAddressFields({
    super.key,
    required this.fields,
    required this.controllers,
    required this.requiredMessage,
  });

  final List<StructuredPostalAddressField> fields;
  final Map<String, TextEditingController> controllers;
  final String requiredMessage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final field in fields) ...[
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('postal.${field.keyName}'),
          controller: controllers[field.keyName],
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          maxLines: field.maxLines,
          validator: (value) {
            if (field.required && (value?.trim().isEmpty ?? true)) {
              return requiredMessage;
            }
            return null;
          },
        ),
      ],
    ],
  );
}
