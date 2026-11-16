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

/// Consumer-supplied implementation of an authentication process.
///
/// Gicho owns when this delegate runs, but the delegate owns how users are
/// authenticated and what authentication UI is displayed. Implementations
/// must report failures through [state] rather than throwing from [initialize].
abstract interface class AuthenticationDelegate {
  ValueListenable<AuthenticationState> get state;

  /// Restores or checks the current authentication state.
  Future<void> initialize();

  /// Builds the full authentication surface for every non-authenticated state.
  Widget buildAuthentication(BuildContext context);

  /// Ends the current session and emits [AuthenticationState.unauthenticated].
  Future<void> logout();

  /// Releases resources owned by this delegate.
  void dispose();
}
