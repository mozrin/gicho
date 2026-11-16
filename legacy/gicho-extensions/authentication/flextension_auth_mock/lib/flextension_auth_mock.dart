import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moztopia/gicho.dart';

/// Development-only authentication delegate with no external identity system.
final class FlextensionAuthMock implements AuthenticationDelegate {
  final ValueNotifier<AuthenticationState> _state = ValueNotifier(
    AuthenticationState.checking,
  );

  @override
  ValueListenable<AuthenticationState> get state => _state;

  @override
  Future<void> initialize() async {
    _state.value = AuthenticationState.unauthenticated;
  }

  /// Immediately authenticates the mock user.
  Future<void> login() async {
    _state.value = AuthenticationState.authenticating;
    _state.value = AuthenticationState.authenticated;
  }

  @override
  Future<void> logout() async {
    _state.value = AuthenticationState.unauthenticated;
  }

  @override
  Widget buildAuthentication(BuildContext context) => ListenableBuilder(
    listenable: moztopiaTheme,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: moztopiaTheme.lightTheme,
      darkTheme: moztopiaTheme.darkTheme,
      themeMode: moztopiaTheme.mode,
      home: PopScope(
        canPop: false,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(onPressed: login, child: const Text('LOGIN')),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: SystemNavigator.pop,
                  child: const Text('EXIT'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() => _state.dispose();
}
