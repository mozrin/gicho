import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

class AboutFlow extends StatelessWidget {
  const AboutFlow({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const GichoModalPage(
            title: 'About',
            body: Center(
              child: Text('A focused page without shell navigation'),
            ),
          ),
        ),
      ),
      child: const Text('Open About'),
    ),
  );
}
