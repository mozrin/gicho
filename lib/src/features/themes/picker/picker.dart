import 'package:flutter/material.dart';

import '../../localization/locale_controller/index.dart';
import '../controller/index.dart';

/// Selects an app-enabled theme and a device, light or dark appearance.
class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key, required this.themes, required this.locales});

  final ThemeController themes;
  final GichoLocaleController locales;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([themes, locales]),
    builder: (context, _) => Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locales.text('gicho.theme.label')),
            DropdownButton<String>(
              value: themes.name,
              items: [
                for (final name in themes.available)
                  DropdownMenuItem(
                    value: name,
                    child: Text(themes.catalog.displayName(name)),
                  ),
              ],
              onChanged: (name) async {
                if (name != null) {
                  await themes.select(name);
                }
              },
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locales.text('gicho.theme.mode')),
            DropdownButton<ThemeMode>(
              value: themes.mode,
              items: [
                for (final mode in ThemeMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(locales.text('gicho.theme.${mode.name}')),
                  ),
              ],
              onChanged: (mode) async {
                if (mode != null) {
                  await themes.setMode(mode);
                }
              },
            ),
          ],
        ),
      ],
    ),
  );
}
