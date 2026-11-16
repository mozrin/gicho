import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Protocol-neutral states understood by the Gicho authentication stage.
enum AuthenticationState {
  checking,
  unauthenticated,
  authenticating,
  authenticated,
  failed,
}

enum AuthenticationPhase { checking, starting, browser, exchanging, refreshing }

enum AuthenticationFailure {
  cancelled,
  offline,
  browserUnavailable,
  providerUnavailable,
  resultExpired,
  sessionEnded,
  storageUnavailable,
  generic,
}

final class AuthenticationViewState {
  const AuthenticationViewState({
    this.phase = AuthenticationPhase.checking,
    this.failure,
    this.provider,
  });

  final AuthenticationPhase phase;
  final AuthenticationFailure? failure;
  final String? provider;
}

/// Consumer-supplied implementation of an authentication process.
///
/// Gicho owns provider presentation and when this delegate runs. The
/// delegate owns protocol/session behavior and supplies compact application
/// branding. Implementations must report failures through [state] rather than
/// throwing from [initialize].
abstract interface class AuthenticationDelegate {
  ValueListenable<AuthenticationState> get state;

  ValueListenable<AuthenticationViewState> get viewState;

  /// Restores or checks the current authentication state.
  Future<void> initialize();

  /// Returns provider slugs configured by the consumer's authentication server.
  Future<Set<String>> getProviders();

  /// Starts the selected provider through the consumer-owned protocol adapter.
  Future<void> startProvider(String provider);

  /// Repeats the failed authentication operation.
  Future<void> retry();

  /// Cancels the active browser authentication attempt.
  Future<void> cancelAuthentication();

  /// Builds application branding inside Gicho's authentication surface.
  Widget buildAuthenticationBrand(BuildContext context);

  /// Ends the current session and emits [AuthenticationState.unauthenticated].
  Future<void> logout();

  /// Releases resources owned by this delegate.
  void dispose();
}
