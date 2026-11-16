import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

class FNav1Screen extends StatelessWidget {
  const FNav1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.looks_one, size: 72),
          const SizedBox(height: 16),
          Text(
            'FNav1 overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(translate('welcome', context: context)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              moztopiaLog.info('Opening the FNav1 modal stack');
              context.push('/modal/fnav1');
            },
            icon: const Icon(Icons.layers),
            label: const Text('Open modal page'),
          ),
        ],
      ),
    );
  }
}
