// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../../startup_splash/index.dart';

/// Private Material host for the consumer's initial loading screen.
class GichoBootstrapLoadingView extends StatelessWidget {
  const GichoBootstrapLoadingView({
    super.key,
    required this.theme,
    required this.title,
    this.message,
    this.screen,
  });

  final ThemeData theme;
  final String title;
  final String? message;
  final Widget? screen;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: screen ?? StartupSplash(title: title, message: message),
  );
}
