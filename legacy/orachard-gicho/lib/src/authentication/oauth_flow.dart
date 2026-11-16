// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logging/configured_logging.dart';
import 'authentication_delegate.dart';

final class GichoOAuthAuthorization {
  const GichoOAuthAuthorization({
    required this.provider,
    required this.authorizationUrl,
    required this.expiresAt,
  });

  final String provider;
  final Uri authorizationUrl;
  final DateTime expiresAt;
}

/// Application adapter for the generated backend SDK.
///
/// Gicho owns the reusable OAuth lifecycle. The application maps its
/// generated contract types at this boundary and remains the only owner of
/// application endpoints and token models.
abstract interface class GichoOAuthAdapter<TSession> {
  Future<GichoOAuthAuthorization> beginOAuth({
    required String provider,
    required String clientPlatform,
    required String returnTarget,
    required String codeChallenge,
    required String deviceName,
    Uri? returnUri,
  });

  Future<TSession> exchangeOAuthResult({
    required String resultCode,
    required String codeVerifier,
  });
}

final class GichoOAuthPendingAttempt {
  const GichoOAuthPendingAttempt({
    required this.codeVerifier,
    required this.startedAt,
    required this.provider,
  });

  final String codeVerifier;
  final DateTime startedAt;
  final String provider;
}

abstract interface class GichoOAuthAttemptStore {
  Future<GichoOAuthPendingAttempt?> read();

  Future<void> write(GichoOAuthPendingAttempt attempt);

  Future<void> clear();
}

/// Secure persistence for only the in-flight PKCE verifier.
final class SecureGichoOAuthAttemptStore
    implements GichoOAuthAttemptStore {
  SecureGichoOAuthAttemptStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'gicho.authentication.oauth.pending.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<GichoOAuthPendingAttempt?> read() async {
    final encoded = await _storage.read(key: _key);
    if (encoded == null) return null;
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, dynamic>) return null;
      final verifier = value['codeVerifier'];
      final startedAt = value['startedAt'];
      final provider = value['provider'];
      if (verifier is! String ||
          startedAt is! String ||
          provider is! String ||
          provider.isEmpty) {
        await clear();
        return null;
      }
      return GichoOAuthPendingAttempt(
        codeVerifier: verifier,
        startedAt: DateTime.parse(startedAt).toUtc(),
        provider: provider,
      );
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(GichoOAuthPendingAttempt attempt) => _storage.write(
    key: _key,
    value: jsonEncode({
      'codeVerifier': attempt.codeVerifier,
      'startedAt': attempt.startedAt.toUtc().toIso8601String(),
      'provider': attempt.provider,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

abstract interface class GichoOAuthBrowser {
  Future<bool> open(Uri authorizationUrl);
}

final class SystemGichoOAuthBrowser implements GichoOAuthBrowser {
  @override
  Future<bool> open(Uri authorizationUrl) => launchUrl(
    authorizationUrl,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_self',
  );
}

abstract interface class GichoOAuthCallbackSource {
  Future<Uri?> initialLink();

  Stream<Uri> get links;
}

final class PlatformGichoOAuthCallbackSource
    implements GichoOAuthCallbackSource {
  PlatformGichoOAuthCallbackSource({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> initialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}

/// One ephemeral callback listener prepared before the browser is opened.
abstract interface class GichoOAuthCallbackSession {
  Uri get returnUri;

  Future<Uri> get callback;

  Future<void> respond({required bool success});

  Future<void> close();
}

abstract interface class GichoOAuthLoopbackReceiver {
  Future<GichoOAuthCallbackSession> prepare();
}

typedef GichoOAuthPhaseHandler =
    void Function(AuthenticationPhase phase, String provider);
typedef GichoOAuthFailureHandler =
    void Function(AuthenticationFailure failure, String provider);
typedef GichoOAuthRandomBytes = List<int> Function(int length);
typedef GichoOAuthAuthenticatedHandler<TSession> =
    Future<void> Function(TSession session);

/// Reusable browser OAuth/PKCE coordinator for every Gicho platform.
///
/// Desktop receives exactly one provider completion through an ephemeral
/// loopback listener. Native and web receive exactly one registered callback.
/// The callback contains only a short-lived PKCE-bound result code; session
/// credentials are returned solely by [exchangeOAuthResult].
final class GichoOAuthCoordinator<TSession> {
  GichoOAuthCoordinator({
    required GichoOAuthAdapter<TSession> adapter,
    required GichoOAuthAttemptStore store,
    required GichoOAuthBrowser browser,
    required String clientPlatform,
    required String returnTarget,
    required String deviceName,
    required GichoOAuthPhaseHandler onPhase,
    required GichoOAuthFailureHandler onFailure,
    required GichoOAuthAuthenticatedHandler<TSession> onAuthenticated,
    GichoOAuthCallbackSource? callbackSource,
    GichoOAuthLoopbackReceiver? loopbackReceiver,
    bool useLoopback = false,
    bool Function(Uri uri)? acceptsCallback,
    DateTime Function()? now,
    GichoOAuthRandomBytes? randomBytes,
  }) : _adapter = adapter,
       _store = store,
       _browser = browser,
       _callbackSource = callbackSource,
       _loopbackReceiver = loopbackReceiver,
       _useLoopback = useLoopback,
       _acceptsCallback = acceptsCallback,
       _clientPlatform = clientPlatform,
       _returnTarget = returnTarget,
       _deviceName = deviceName,
       _onPhase = onPhase,
       _onFailure = onFailure,
       _onAuthenticated = onAuthenticated,
       _now = now ?? DateTime.now,
       _randomBytes = randomBytes ?? _secureRandomBytes {
    if (_useLoopback && _loopbackReceiver == null) {
      throw ArgumentError('Desktop OAuth requires a loopback receiver.');
    }
  }

  static const _maximumPendingLifetime = Duration(minutes: 7);
  final GichoOAuthAdapter<TSession> _adapter;
  final GichoOAuthAttemptStore _store;
  final GichoOAuthBrowser _browser;
  final GichoOAuthCallbackSource? _callbackSource;
  final GichoOAuthLoopbackReceiver? _loopbackReceiver;
  final bool _useLoopback;
  final bool Function(Uri uri)? _acceptsCallback;
  final String _clientPlatform;
  final String _returnTarget;
  final String _deviceName;
  final GichoOAuthPhaseHandler _onPhase;
  final GichoOAuthFailureHandler _onFailure;
  final GichoOAuthAuthenticatedHandler<TSession> _onAuthenticated;
  final DateTime Function() _now;
  final GichoOAuthRandomBytes _randomBytes;

  StreamSubscription<Uri>? _linkSubscription;
  GichoOAuthCallbackSession? _loopbackSession;
  Future<bool>? _exchangeInFlight;
  int _epoch = 0;
  bool _disposed = false;

  Future<bool> initialize() async {
    _detail('OAuth coordinator initialization started');
    final source = _callbackSource;
    if (!_useLoopback && source != null && _linkSubscription == null) {
      _linkSubscription = source.links.listen(
        (uri) => unawaited(handleCallback(uri)),
        onError: (Object error, StackTrace stackTrace) {
          _failure('OAuth callback listener failed', error, stackTrace);
        },
      );
      final initial = await source.initialLink();
      if (initial != null && _accepts(initial)) {
        await handleCallback(initial);
        return true;
      }
    }

    final pending = await _store.read();
    if (_useLoopback) {
      // A loopback listener cannot survive an application restart. The old
      // browser callback is intentionally allowed to expire server-side.
      if (pending != null) await _store.clear();
      _detail('OAuth coordinator initialization completed: desktop idle');
      return false;
    }
    if (!_isCurrent(pending)) {
      if (pending != null) await _store.clear();
      _detail('OAuth coordinator initialization completed: no active attempt');
      return false;
    }

    _onPhase(AuthenticationPhase.browser, pending!.provider);
    _event('OAuth coordinator awaiting the registered callback');
    return true;
  }

  Future<void> start(String provider) async {
    final operationEpoch = ++_epoch;
    await _closeLoopback();
    _onPhase(AuthenticationPhase.starting, provider);
    _event('OAuth authorization requested: provider=$provider');
    GichoOAuthCallbackSession? loopback;
    try {
      if (_useLoopback) {
        _detail('OAuth desktop loopback listener preparation started');
        loopback = await _loopbackReceiver!.prepare();
        _loopbackSession = loopback;
        _detail(
          'OAuth desktop loopback listener ready: '
          'host=${loopback.returnUri.host}; port=ephemeral; '
          'path=${loopback.returnUri.path}',
        );
      }

      final verifier = _base64Url(_randomBytes(32));
      final challenge = _base64Url(sha256.convert(utf8.encode(verifier)).bytes);
      final pending = GichoOAuthPendingAttempt(
        codeVerifier: verifier,
        startedAt: _now().toUtc(),
        provider: provider,
      );
      await _store.write(pending);
      _detail('OAuth PKCE attempt persisted; values=redacted');

      final authorization = await _adapter.beginOAuth(
        provider: provider,
        clientPlatform: _clientPlatform,
        returnTarget: _useLoopback ? 'orchardLoopback' : _returnTarget,
        returnUri: loopback?.returnUri,
        codeChallenge: challenge,
        deviceName: _deviceName,
      );
      if (!_active(operationEpoch)) return;
      if (authorization.provider != provider ||
          authorization.authorizationUrl.scheme != 'https' ||
          authorization.authorizationUrl.host.isEmpty) {
        throw const FormatException('Invalid OAuth authorization response');
      }

      final launched = await _browser.open(authorization.authorizationUrl);
      if (!_active(operationEpoch)) return;
      if (!launched) {
        await _store.clear();
        await _closeLoopback();
        _onFailure(AuthenticationFailure.browserUnavailable, provider);
        return;
      }
      _onPhase(AuthenticationPhase.browser, provider);
      _event(
        'OAuth authorization handed to system browser: provider=$provider',
      );
      if (loopback != null) {
        unawaited(_receiveLoopback(loopback, operationEpoch));
      }
    } catch (error, stackTrace) {
      await _clearBestEffort();
      await _closeLoopback();
      final classified = _classify(error, starting: true);
      _failure('OAuth authorization could not start', error, stackTrace);
      if (_active(operationEpoch)) _onFailure(classified, provider);
    }
  }

  Future<void> _receiveLoopback(
    GichoOAuthCallbackSession session,
    int operationEpoch,
  ) async {
    var success = false;
    try {
      _detail('OAuth desktop callback listener awaiting one completion');
      final uri = await session.callback.timeout(_maximumPendingLifetime);
      if (!_active(operationEpoch)) return;
      _event('OAuth desktop callback received');
      success = await _exchangeCallback(uri, operationEpoch);
    } on TimeoutException catch (error, stackTrace) {
      await _clearBestEffort();
      _failure('OAuth desktop callback expired', error, stackTrace);
      if (_active(operationEpoch)) {
        final pending = await _store.read();
        _onFailure(
          AuthenticationFailure.resultExpired,
          pending?.provider ?? 'google',
        );
      }
    } catch (error, stackTrace) {
      await _clearBestEffort();
      _failure('OAuth desktop callback failed', error, stackTrace);
      if (_active(operationEpoch)) {
        final pending = await _store.read();
        _onFailure(
          AuthenticationFailure.generic,
          pending?.provider ?? 'google',
        );
      }
    } finally {
      try {
        await session.respond(success: success);
      } catch (error, stackTrace) {
        _failure('OAuth desktop browser response failed', error, stackTrace);
      }
      if (identical(_loopbackSession, session)) _loopbackSession = null;
      await session.close();
    }
  }

  Future<void> handleCallback(Uri uri) async {
    if (!_accepts(uri)) return;
    await _exchangeCallback(uri, _epoch);
  }

  Future<bool> _exchangeCallback(Uri uri, int operationEpoch) {
    final active = _exchangeInFlight;
    if (active != null) return active;
    final operation = _exchange(uri, operationEpoch);
    _exchangeInFlight = operation;
    return operation.whenComplete(() {
      if (identical(_exchangeInFlight, operation)) _exchangeInFlight = null;
    });
  }

  Future<bool> _exchange(Uri uri, int operationEpoch) async {
    final resultCode = uri.queryParameters['result'];
    if (resultCode == null ||
        resultCode.length < 43 ||
        resultCode.length > 512 ||
        uri.queryParameters.length != 1) {
      final pending = await _store.read();
      await _clearBestEffort();
      if (_active(operationEpoch)) {
        _onFailure(
          AuthenticationFailure.resultExpired,
          pending?.provider ?? 'google',
        );
      }
      return false;
    }

    final pending = await _store.read();
    if (!_isCurrent(pending)) {
      await _clearBestEffort();
      if (_active(operationEpoch)) {
        _onFailure(
          AuthenticationFailure.resultExpired,
          pending?.provider ?? 'google',
        );
      }
      return false;
    }
    final attempt = pending!;
    try {
      _onPhase(AuthenticationPhase.exchanging, attempt.provider);
      _detail('OAuth result exchange started; credentials=redacted');
      final session = await _adapter.exchangeOAuthResult(
        resultCode: resultCode,
        codeVerifier: attempt.codeVerifier,
      );
      await _store.clear();
      if (!_active(operationEpoch)) return false;
      _epoch++;
      await _onAuthenticated(session);
      _event('OAuth result exchange completed');
      return true;
    } catch (error, stackTrace) {
      await _clearBestEffort();
      _failure('OAuth result exchange failed', error, stackTrace);
      if (_active(operationEpoch)) {
        _onFailure(_classify(error), attempt.provider);
      }
      return false;
    }
  }

  Future<void> cancel() async {
    _epoch++;
    await _clearBestEffort();
    await _closeLoopback();
    _event('OAuth authorization cancelled');
  }

  bool _isCurrent(GichoOAuthPendingAttempt? pending) {
    if (pending == null) return false;
    final now = _now().toUtc();
    final deadline = pending.startedAt.add(_maximumPendingLifetime);
    return !now.isBefore(pending.startedAt) && now.isBefore(deadline);
  }

  bool _accepts(Uri uri) =>
      _useLoopback || (_acceptsCallback?.call(uri) ?? false);
  bool _active(int operationEpoch) => !_disposed && operationEpoch == _epoch;

  AuthenticationFailure _classify(Object error, {bool starting = false}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 404) {
        return AuthenticationFailure.resultExpired;
      }
      if (status == 503) return AuthenticationFailure.providerUnavailable;
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return AuthenticationFailure.offline;
      }
    }
    if (starting && error is FormatException) {
      return AuthenticationFailure.browserUnavailable;
    }
    return AuthenticationFailure.generic;
  }

  Future<void> _clearBestEffort() async {
    try {
      await _store.clear();
    } catch (error, stackTrace) {
      _failure('OAuth pending-attempt cleanup failed', error, stackTrace);
    }
  }

  Future<void> _closeLoopback() async {
    final session = _loopbackSession;
    _loopbackSession = null;
    if (session != null) await session.close();
  }

  void _detail(String message) {
    if (kDebugMode) {
      unawaited(moztopiaLog.debug('[Gicho authentication] $message'));
    }
  }

  void _event(String message) {
    if (kDebugMode) {
      unawaited(moztopiaLog.info('[Gicho authentication] $message'));
    }
  }

  void _failure(String message, Object error, StackTrace stackTrace) {
    unawaited(
      moztopiaLog.error(
        '[Gicho authentication] $message; error=${error.runtimeType}',
        stackTrace: kDebugMode ? stackTrace : null,
      ),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _epoch++;
    unawaited(_linkSubscription?.cancel());
    unawaited(_closeLoopback());
    _detail('OAuth coordinator disposed');
  }

  static List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static String _base64Url(List<int> bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');
}
