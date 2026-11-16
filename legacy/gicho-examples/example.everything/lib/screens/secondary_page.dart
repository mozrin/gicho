import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

import '../navigation/secondary_destination.dart';

class SecondaryPage extends StatelessWidget {
  const SecondaryPage({super.key, required this.destination});

  final SecondaryDestination destination;

  @override
  Widget build(BuildContext context) {
    return GichoPageShell(
      appBar: GichoAppBar(
        leading: BackButton(onPressed: context.pop),
        title: Text(destination.label),
        showStandardActions: false,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(destination.icon, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    destination.label,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(destination.message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
