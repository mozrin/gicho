import 'package:flutter/material.dart';

/// Minimal presentation used when a startup process does not supply one.
final class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 96),
            SizedBox(
              width: 128,
              height: 128,
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    ),
  );
}
