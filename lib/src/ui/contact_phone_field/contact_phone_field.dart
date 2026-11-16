import 'package:flutter/material.dart';

/// A dialling-country choice supplied by the contact rules provider.
class ContactPhoneCountry {
  const ContactPhoneCountry({required this.code, required this.label});

  final String code;
  final String label;
}

/// Country-aware phone entry with owner-declared capabilities.
class ContactPhoneField extends StatelessWidget {
  const ContactPhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.countries,
    required this.onCountryChanged,
    required this.label,
    required this.countryLabel,
    required this.capabilityLabel,
    required this.capabilityOptions,
    required this.capabilities,
    required this.onCapabilitiesChanged,
    required this.format,
    this.validator,
    this.verified = false,
    this.verifiedLabel = 'Verified',
  });

  final TextEditingController controller;
  final String countryCode;
  final List<ContactPhoneCountry> countries;
  final ValueChanged<String> onCountryChanged;
  final String label;
  final String countryLabel;
  final String capabilityLabel;
  final Map<String, String> capabilityOptions;
  final Set<String> capabilities;
  final ValueChanged<Set<String>> onCapabilitiesChanged;
  final String? Function(String value, String countryCode) format;
  final FormFieldValidator<String>? validator;
  final bool verified;
  final String verifiedLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: countryCode,
        decoration: InputDecoration(labelText: countryLabel),
        items: [
          for (final country in countries)
            DropdownMenuItem(value: country.code, child: Text(country.label)),
        ],
        onChanged: (value) {
          if (value != null) {
            onCountryChanged(value);
          }
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: verified
              ? Tooltip(
                  message: verifiedLabel,
                  child: const Icon(Icons.verified),
                )
              : null,
        ),
        validator: validator,
        onEditingComplete: () {
          final formatted = format(controller.text, countryCode);
          if (formatted != null) {
            controller.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
          FocusScope.of(context).unfocus();
        },
      ),
      const SizedBox(height: 12),
      Text(capabilityLabel, style: Theme.of(context).textTheme.labelLarge),
      for (final option in capabilityOptions.entries)
        CheckboxListTile(
          value: capabilities.contains(option.key),
          title: Text(option.value),
          contentPadding: EdgeInsets.zero,
          onChanged: (enabled) {
            final next = Set<String>.of(capabilities);
            if (enabled ?? false) {
              next.add(option.key);
            } else {
              next.remove(option.key);
            }
            onCapabilitiesChanged(next);
          },
        ),
    ],
  );
}
