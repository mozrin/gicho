import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Feature configuration',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Inspect package defaults, app overrides, and the resolved result.',
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Configuration inspector'),
            subtitle: const Text(
              'Compare package, app, and merged feature configuration',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/config/inspect'),
          ),
        ),
      ],
    );
  }
}
