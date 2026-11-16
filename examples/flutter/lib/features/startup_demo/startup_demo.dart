import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

class StartupDemo extends StatefulWidget {
  const StartupDemo({super.key, required this.locales});

  final GichoLocaleController locales;

  @override
  State<StartupDemo> createState() => _StartupDemoState();
}

class _StartupDemoState extends State<StartupDemo> {
  bool _signedIn = false;
  bool _failNext = false;
  int _generation = 0;

  Future<bool> _load() async {
    if (_failNext) {
      _failNext = false;
      throw StateError('demo startup failure');
    }
    return _signedIn;
  }

  void _restart({bool? signedIn, bool fail = false}) {
    setState(() {
      _signedIn = signedIn ?? _signedIn;
      _failNext = fail;
      ++_generation;
    });
  }

  @override
  Widget build(BuildContext context) {
    String copy(String name) => widget.locales.text('example.startup.$name');

    return ListenableBuilder(
      listenable: widget.locales,
      builder: (context, _) => StartupGate<bool>(
        key: ValueKey(_generation),
        load: _load,
        loadingBuilder: (_) =>
            StartupSplash(title: copy('title'), message: copy('loading')),
        errorBuilder: (_, _, retry) => Scaffold(
          appBar: AppBar(title: Text(copy('title'))),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(copy('failed')),
                TextButton(onPressed: retry, child: Text(copy('retry'))),
              ],
            ),
          ),
        ),
        readyBuilder: (_, signedIn) => Scaffold(
          appBar: AppBar(title: Text(copy('title'))),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(signedIn ? copy('signed_in') : copy('signed_out')),
                FilledButton(
                  onPressed: () => _restart(signedIn: !signedIn),
                  child: Text(signedIn ? copy('sign_out') : copy('sign_in')),
                ),
                TextButton(
                  onPressed: () => _restart(fail: true),
                  child: Text(copy('fail_next')),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240,
                  child: GichoLanguagePicker(controller: widget.locales),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
