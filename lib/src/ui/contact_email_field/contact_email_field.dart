import 'package:flutter/material.dart';

/// Reusable email entry; the consumer supplies format checks and verification.
class ContactEmailField extends StatelessWidget {
  const ContactEmailField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.verified = false,
    this.verifiedLabel = 'Verified',
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final bool verified;
  final String verifiedLabel;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.emailAddress,
    autofillHints: const [AutofillHints.email],
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: verified
          ? Tooltip(message: verifiedLabel, child: const Icon(Icons.verified))
          : null,
    ),
    validator: validator,
  );
}
