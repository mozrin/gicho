import 'package:flutter/material.dart';

import '../locale_controller/index.dart';

class GichoLanguagePicker extends StatelessWidget {
  const GichoLanguagePicker({super.key, required this.controller});

  final GichoLocaleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => DropdownButtonFormField<Locale>(
        key: ValueKey(controller.locale),
        initialValue: controller.locale,
        decoration: InputDecoration(
          labelText: controller.text('gicho.language.label'),
        ),
        items: [
          for (final locale in controller.enabledLocales)
            DropdownMenuItem(
              value: locale,
              child: Text(
                controller.text('gicho.locale.${locale.toLanguageTag()}'),
              ),
            ),
        ],
        onChanged: (locale) {
          if (locale != null) {
            controller.setLocale(locale);
          }
        },
      ),
    );
  }
}
