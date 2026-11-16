import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../../authentication/authentication_stage.dart';
import '../../authentication/authentication_delegate.dart';
import '../../authentication/authentication_configuration.dart';
import '../../entitlements/entitlement_adapter.dart';
import '../../entitlements/entitlement_configuration.dart';
import '../../entitlements/gicho_entitlements.dart';
import '../../localization/configured_localization.dart';
import '../../localization/localization_state.dart';
import '../../logging/configured_logging.dart';
import '../../notifications/gicho_notifications.dart';
import '../../notifications/notification_state.dart';
import '../../startup/startup_delegate.dart';
import '../../startup/startup_configuration.dart';
import '../../startup/startup_stage.dart';
import '../../startup/startup_state.dart';
import '../../theme/configured_theme.dart';
import '../moztopia_core.dart';

Future<void>? _serviceInitialization;
Future<void>? _easyLocalizationInitialization;
bool _servicesInitialized = false;
bool _easyLocalizationInitialized = false;

/// The standard simple-mode foundation for a Gicho application.
///
/// It initializes package services, optionally enables localization, and
/// optionally installs the package notification layer. It does not provide any
/// page layout, navigation, app bar, drawer, or footer.
final class GichoBootstrap extends StatefulWidget {
  const GichoBootstrap({
    super.key,
    required this.child,
    this.startupEnabled = false,
    this.startupDelegate,
    this.authenticationEnabled = false,
    this.authenticationDelegate,
    this.entitlementsEnabled = false,
    this.entitlementAdapter,
    this.localizationsEnabled = false,
    this.notificationsEnabled = false,
    this.notificationDelegate,
    this.useOnlyLanguageCode = true,
    this.ignorePluralRules = true,
    this.saveLocale = true,
    this.onReady,
  });

  final Widget child;
  final bool startupEnabled;
  final StartupDelegate? startupDelegate;
  final bool authenticationEnabled;
  final AuthenticationDelegate? authenticationDelegate;
  final bool entitlementsEnabled;
  final GichoEntitlementAdapter? entitlementAdapter;
  final bool localizationsEnabled;
  final bool notificationsEnabled;
  final GichoNotificationDelegate? notificationDelegate;
  final bool useOnlyLanguageCode;
  final bool ignorePluralRules;
  final bool saveLocale;
  final VoidCallback? onReady;

  @override
  State<GichoBootstrap> createState() => _GichoBootstrapState();
}

class _GichoBootstrapState extends State<GichoBootstrap> {
  StartupDelegate? _startupDelegate;
  Future<void>? _startupQueue;
  Timer? _launchIconTimer;
  Stopwatch? _startupClock;
  var _firstFrameDeferred = false;
  var _startupPresentationReady = false;
  late final Future<Widget> _application;

  @override
  void initState() {
    super.initState();
    if (widget.startupEnabled) {
      _startupDelegate = widget.startupDelegate ?? const StartupProcess();
      WidgetsBinding.instance.deferFirstFrame();
      _firstFrameDeferred = true;
      _startupClock = Stopwatch()..start();
      _startupQueue = runStartupQueue(_startupDelegate!.startupQueue);
      unawaited(_scheduleFirstFrame());
    }
    _application = _initialize();
  }

  void _showStartupPresentation() {
    if (!_firstFrameDeferred) return;
    if (!mounted) {
      _allowFirstFrame();
      return;
    }
    setState(() => _startupPresentationReady = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _allowFirstFrame());
  }

  void _allowFirstFrame() {
    if (!_firstFrameDeferred) return;
    WidgetsBinding.instance.allowFirstFrame();
    _firstFrameDeferred = false;
  }

  Future<void> _scheduleFirstFrame() async {
    try {
      final configured = await moztopiaStartup.initialize();
      final duration =
          _startupDelegate!.startupPreDelayDuration ??
          configured.startupPreDelayDuration;
      final remaining = duration - _startupClock!.elapsed;
      _launchIconTimer = Timer(
        remaining.isNegative ? Duration.zero : remaining,
        _showStartupPresentation,
      );
    } catch (_) {
      _showStartupPresentation();
    }
  }

  @override
  void dispose() {
    _launchIconTimer?.cancel();
    _allowFirstFrame();
    super.dispose();
  }

  Future<Widget> _initialize() async {
    if (widget.localizationsEnabled && !_easyLocalizationInitialized) {
      await (_easyLocalizationInitialization ??=
          EasyLocalization.ensureInitialized());
      _easyLocalizationInitialized = true;
    }

    if (!_servicesInitialized) {
      await (_serviceInitialization ??= Future.wait([
        moztopiaLog.initialize(),
        moztopiaCore.initialize(),
        moztopiaTheme.initialize(),
        if (widget.startupEnabled) moztopiaStartup.initialize(),
      ]));
      _servicesInitialized = true;
    }

    final startupConfiguration = widget.startupEnabled
        ? await moztopiaStartup.initialize()
        : null;
    final authenticationConfiguration = widget.authenticationEnabled
        ? await moztopiaAuthentication.initialize()
        : null;
    final entitlementConfiguration = widget.entitlementsEnabled
        ? await moztopiaEntitlements.initialize()
        : null;
    final notificationsConfiguration = widget.notificationsEnabled
        ? await moztopiaNotifications.initialize()
        : null;

    // Build the launch gates from the app outward. Authentication is closest
    // to the app and startup is outside authentication, preserving:
    // platform launch icon -> startup -> authentication -> app.
    Widget application = widget.child;
    application = GichoEntitlements(
      configuration: entitlementConfiguration,
      adapter: widget.entitlementAdapter,
      child: application,
    );
    if (widget.authenticationEnabled) {
      final delegate = widget.authenticationDelegate;
      if (delegate == null) {
        throw StateError(
          'authenticationEnabled is true, but no authenticationDelegate was '
          'provided. Supply an AuthenticationDelegate from a Flextension or '
          'the consumer application.',
        );
      }
      application = AuthenticationStage(
        delegate: delegate,
        configuration: authenticationConfiguration!,
        child: application,
      );
    } else {
      application = AuthenticationScope(
        runtime: const AuthenticationRuntime.unavailable(),
        child: application,
      );
    }
    if (widget.startupEnabled) {
      application = StartupStage(
        delegate: _startupDelegate!,
        queue: _startupQueue!,
        postDelayDuration:
            _startupDelegate!.startupPostDelayDuration ??
            startupConfiguration!.startupPostDelayDuration,
        child: application,
      );
    } else {
      application = StartupScope(
        state: const StartupState.unavailable(),
        child: application,
      );
    }
    if (widget.notificationsEnabled) {
      application = GichoNotifications(
        configuration: notificationsConfiguration!,
        delegate: widget.notificationDelegate,
        child: application,
      );
    } else {
      application = GichoNotificationsScope(
        state: const GichoNotificationsState.unavailable(),
        child: application,
      );
    }
    application = GichoLocalizationScope(
      state: widget.localizationsEnabled
          ? const GichoLocalizationState.available()
          : const GichoLocalizationState.unavailable(),
      child: application,
    );
    if (widget.localizationsEnabled) {
      application = await moztopiaLocalization.create(
        useOnlyLangCode: widget.useOnlyLanguageCode,
        ignorePluralRules: widget.ignorePluralRules,
        saveLocale: widget.saveLocale,
        child: application,
      );
    }
    widget.onReady?.call();
    return application;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startupEnabled && !_startupPresentationReady) {
      return const _StartupFrame(child: SizedBox.shrink());
    }
    return FutureBuilder<Widget>(
      future: _application,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupFrame(
            child: SelectableText(
              'Gicho could not start.\n\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }
        return snapshot.data ??
            const _StartupFrame(child: CircularProgressIndicator());
      },
    );
  }
}

class _StartupFrame extends StatelessWidget {
  const _StartupFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: child)),
  );
}
