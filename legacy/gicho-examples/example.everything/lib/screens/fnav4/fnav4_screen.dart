import 'package:flutter/material.dart';

class FNav4Screen extends StatelessWidget {
  const FNav4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'FNav4 status',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          const LinearProgressIndicator(value: 0.68),
          const SizedBox(height: 12),
          const Text('Example progress-oriented destination'),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Example status'),
              subtitle: Text('Ready'),
            ),
          ),
        ],
      ),
    );
  }
}
