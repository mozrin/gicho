// ignore_for_file: file_names

import 'package:flutter/material.dart';

/// Private retry screen used when bootstrap preparation fails.
class GichoBootstrapFailureView extends StatelessWidget {
  const GichoBootstrapFailureView({
    super.key,
    required this.theme,
    required this.message,
    required this.retryLabel,
    required this.retry,
  });

  final ThemeData theme;
  final String message;
  final String retryLabel;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(liveRegion: true, child: Text(message)),
            TextButton(onPressed: retry, child: Text(retryLabel)),
          ],
        ),
      ),
    ),
  );
}
