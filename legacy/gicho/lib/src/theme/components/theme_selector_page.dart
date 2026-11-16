import 'package:flutter/material.dart';

import '../configured_theme.dart';

/// Selects the active brightness mode and configured color scheme.
final class ThemeSelectorPage extends StatelessWidget {
  const ThemeSelectorPage({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: moztopiaTheme,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Theme'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Mode', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {moztopiaTheme.mode},
            onSelectionChanged: (selection) {
              moztopiaTheme.selectMode(selection.first);
            },
          ),
          const SizedBox(height: 32),
          Text('Color scheme', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: moztopiaTheme.selectedThemeId,
            onChanged: (value) {
              if (value != null) moztopiaTheme.selectTheme(value);
            },
            child: Column(
              children: [
                for (final theme in moztopiaTheme.themes)
                  RadioListTile<String>(
                    value: theme.id,
                    title: Text(theme.name),
                    secondary: _ThemeSwatch(theme: theme),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.theme});

  final MoztopiaThemeDefinition theme;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: theme.primary,
    child: Icon(Icons.palette_outlined, color: theme.secondary ?? Colors.white),
  );
}
