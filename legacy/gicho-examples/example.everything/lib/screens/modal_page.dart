import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

class ModalPage extends StatelessWidget {
  const ModalPage({super.key, required this.source, required this.depth});

  final String source;
  final int depth;

  String get sourceLabel => source.startsWith('fnav')
      ? source.replaceFirst('fnav', 'FNav')
      : '${source[0].toUpperCase()}${source.substring(1)}';

  @override
  Widget build(BuildContext context) {
    return GichoPageShell(
      appBar: GichoAppBar(
        leading: BackButton(onPressed: context.pop),
        title: Text(depth == 1 ? '$sourceLabel modal' : 'Stacked modal'),
        showStandardActions: false,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers, size: 72),
            const SizedBox(height: 16),
            Text('Modal stack depth: $depth'),
            if (depth == 1) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  moztopiaLog.debug('Pushing modal stack depth 2 from $source');
                  context.push('/modal/$source/next');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Open another modal'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
