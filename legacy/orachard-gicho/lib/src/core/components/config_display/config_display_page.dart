import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../../../config/configuration_registry.dart';

/// Displays the complete resolved Gicho configuration currently in memory.
final class ConfigurationDisplayPage extends StatelessWidget {
  const ConfigurationDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(moztopiaConfig.values);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('In-memory configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              json,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
