import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'oauth_flow.dart';

final class SystemGichoOAuthLoopbackReceiver
    implements GichoOAuthLoopbackReceiver {
  SystemGichoOAuthLoopbackReceiver({
    required this.applicationName,
    String? successTitle,
    String? successMessage,
    String? failureTitle,
    String? failureMessage,
  }) : successTitle = successTitle ?? 'You have successfully signed in!',
       successMessage =
           successMessage ??
           'Please return to $applicationName. You can close this window.',
       failureTitle = failureTitle ?? 'Sign-in could not be completed',
       failureMessage =
           failureMessage ?? 'Please return to $applicationName and try again.';

  final String applicationName;
  final String successTitle;
  final String successMessage;
  final String failureTitle;
  final String failureMessage;

  @override
  Future<GichoOAuthCallbackSession> prepare() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _IoGichoOAuthCallbackSession(
      server: server,
      applicationName: applicationName,
      successTitle: successTitle,
      successMessage: successMessage,
      failureTitle: failureTitle,
      failureMessage: failureMessage,
    );
  }
}

final class _IoGichoOAuthCallbackSession
    implements GichoOAuthCallbackSession {
  _IoGichoOAuthCallbackSession({
    required this._server,
    required this.applicationName,
    required this.successTitle,
    required this.successMessage,
    required this.failureTitle,
    required this.failureMessage,
  }) {
    _subscription = _server.listen(_handleRequest);
  }

  static const _path = '/auth/complete';
  final HttpServer _server;
  final String applicationName;
  final String successTitle;
  final String successMessage;
  final String failureTitle;
  final String failureMessage;
  final Completer<Uri> _callback = Completer<Uri>();
  late final StreamSubscription<HttpRequest> _subscription;
  HttpRequest? _acceptedRequest;
  bool _closed = false;

  @override
  Uri get returnUri =>
      Uri(scheme: 'http', host: '127.0.0.1', port: _server.port, path: _path);

  @override
  Future<Uri> get callback => _callback.future;

  Future<void> _handleRequest(HttpRequest request) async {
    final uri = request.uri;
    final code = uri.queryParameters['result'];
    final valid =
        request.method == 'GET' &&
        uri.path == _path &&
        uri.queryParameters.length == 1 &&
        code != null &&
        code.length >= 43 &&
        code.length <= 512 &&
        _acceptedRequest == null;
    if (!valid) {
      request.response.statusCode = HttpStatus.badRequest;
      _securityHeaders(request.response);
      request.response.write('Invalid authentication callback.');
      await request.response.close();
      return;
    }
    _acceptedRequest = request;
    _callback.complete(uri);
  }

  @override
  Future<void> respond({required bool success}) async {
    final request = _acceptedRequest;
    if (request == null) return;
    final response = request.response;
    response.statusCode = success ? HttpStatus.ok : HttpStatus.badRequest;
    response.headers.contentType = ContentType.html;
    _securityHeaders(response);
    final title = success ? successTitle : failureTitle;
    final message = success ? successMessage : failureMessage;
    response.write(_page(title, message));
    await response.close();
    _acceptedRequest = null;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_callback.isCompleted) {
      _callback.completeError(
        StateError('OAuth loopback callback listener closed.'),
      );
    }
    await _subscription.cancel();
    final request = _acceptedRequest;
    if (request != null) {
      request.response.statusCode = HttpStatus.gone;
      _securityHeaders(request.response);
      await request.response.close();
      _acceptedRequest = null;
    }
    await _server.close(force: true);
  }

  void _securityHeaders(HttpResponse response) {
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.headers.set('Pragma', 'no-cache');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('Referrer-Policy', 'no-referrer');
    response.headers.set(
      'Content-Security-Policy',
      "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; "
          "form-action 'none'; frame-ancestors 'none'",
    );
  }

  String _page(String title, String message) {
    final safeApp = const HtmlEscape().convert(applicationName);
    final safeTitle = const HtmlEscape().convert(title);
    final safeMessage = const HtmlEscape().convert(message);
    return '''<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$safeApp</title><style>
body{margin:0;min-height:100vh;display:grid;place-items:center;background:#160d13;color:#fff;font-family:system-ui,sans-serif}
main{max-width:42rem;margin:2rem;padding:3rem;border:1px solid #7a435d;border-radius:1.5rem;background:#2a1822;text-align:center}
h1{font-size:clamp(2rem,5vw,3.4rem);line-height:1.08;margin:.5rem 0 1rem}p{font-size:1.1rem;line-height:1.6;color:#f2dfe8}
</style></head><body><main><div>$safeApp</div><h1>$safeTitle</h1><p>$safeMessage</p></main></body></html>''';
  }
}
