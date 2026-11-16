import 'oauth_flow.dart';

final class SystemGichoOAuthLoopbackReceiver
    implements GichoOAuthLoopbackReceiver {
  SystemGichoOAuthLoopbackReceiver({
    required String applicationName,
    String? successTitle,
    String? successMessage,
    String? failureTitle,
    String? failureMessage,
  });

  @override
  Future<GichoOAuthCallbackSession> prepare() =>
      throw UnsupportedError('OAuth loopback callbacks require dart:io.');
}
