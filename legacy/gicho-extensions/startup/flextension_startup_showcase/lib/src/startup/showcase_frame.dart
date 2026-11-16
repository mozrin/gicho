import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

import 'showcase_progress.dart';
import 'showcase_progress_panel.dart';

/// Keeps queue progress visible while the large overlay artwork changes.
final class ShowcaseFrame extends StatelessWidget {
  const ShowcaseFrame({
    super.key,
    required this.visual,
    required this.progress,
  });

  final Widget visual;
  final ShowcaseStartupProgress progress;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: moztopiaTheme,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: moztopiaTheme.lightTheme,
      darkTheme: moztopiaTheme.darkTheme,
      themeMode: moztopiaTheme.mode,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(child: Center(child: visual)),
                ShowcaseProgressPanel(progress: progress),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
