import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalCupertinoLocalizations, GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import '../localization/localization_state.dart';
import '../localization/translate.dart';
import '../logging/configured_logging.dart';
import '../theme/configured_theme.dart';
import 'authentication_configuration.dart';
import 'authentication_delegate.dart';

/// Authentication information available below [AuthenticationStage].
final class AuthenticationRuntime {
  const AuthenticationRuntime._({
    required this.isAvailable,
    this.state,
    this.delegate,
  });

  const AuthenticationRuntime.unavailable() : this._(isAvailable: false);

  const AuthenticationRuntime.available({
    required AuthenticationState state,
    required AuthenticationDelegate delegate,
  }) : this._(isAvailable: true, state: state, delegate: delegate);

  final bool isAvailable;
  final AuthenticationState? state;
  final AuthenticationDelegate? delegate;
}

/// Runs a consumer-supplied authentication protocol behind Gicho's
/// configuration-driven provider experience before revealing [child].
final class AuthenticationStage extends StatefulWidget {
  const AuthenticationStage({
    super.key,
    required this.delegate,
    required this.configuration,
    required this.child,
  });

  final AuthenticationDelegate delegate;
  final AuthenticationConfiguration configuration;
  final Widget child;

  static AuthenticationRuntime of(BuildContext context) =>
      AuthenticationScope.of(context).runtime;

  static AuthenticationRuntime? maybeOf(BuildContext context) =>
      AuthenticationScope.maybeOf(context)?.runtime;

  @override
  State<AuthenticationStage> createState() => _AuthenticationStageState();
}

class _AuthenticationStageState extends State<AuthenticationStage> {
  Set<String> _serverProviders = const {};
  var _providersLoading = true;
  var _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(AuthenticationStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.delegate, widget.delegate)) {
      oldWidget.delegate.dispose();
      _serverProviders = const {};
      _providersLoading = true;
      unawaited(_initialize());
    } else if (!identical(oldWidget.configuration, widget.configuration)) {
      _serverProviders = const {};
      _providersLoading = true;
      unawaited(_loadProviders());
    }
  }

  Future<void> _initialize() async {
    await widget.delegate.initialize();
    await _loadProviders();
  }

  Future<void> _loadProviders() async {
    final generation = ++_loadGeneration;
    Set<String> providers;
    try {
      providers = await widget.delegate.getProviders();
    } catch (error, stackTrace) {
      providers = const {};
      unawaited(
        moztopiaLog.warn(
          '[Gicho authentication] Provider availability could not be loaded.',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
    for (final provider in widget.configuration.providers) {
      if (!providers.contains(provider.slug)) {
        unawaited(
          moztopiaLog.warn(
            '[Gicho authentication] Configured provider "${provider.slug}" '
            'is absent from the server provider list and has been disabled.',
          ),
        );
      }
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _serverProviders = Set.unmodifiable(providers);
      _providersLoading = false;
    });
  }

  @override
  void dispose() {
    widget.delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<AuthenticationState>(
        valueListenable: widget.delegate.state,
        builder: (context, state, _) => AuthenticationScope(
          runtime: AuthenticationRuntime.available(
            state: state,
            delegate: widget.delegate,
          ),
          child: Builder(
            builder: (context) => state == AuthenticationState.authenticated
                ? widget.child
                : ValueListenableBuilder<AuthenticationViewState>(
                    valueListenable: widget.delegate.viewState,
                    builder: (context, viewState, _) =>
                        _ConfiguredAuthenticationApp(
                          configuration: widget.configuration,
                          delegate: widget.delegate,
                          serverProviders: _serverProviders,
                          state: _providersLoading
                              ? AuthenticationState.checking
                              : state,
                          viewState: viewState,
                        ),
                  ),
          ),
        ),
      );
}

final class _ConfiguredAuthenticationApp extends StatelessWidget {
  const _ConfiguredAuthenticationApp({
    required this.configuration,
    required this.delegate,
    required this.serverProviders,
    required this.state,
    required this.viewState,
  });

  final AuthenticationConfiguration configuration;
  final AuthenticationDelegate delegate;
  final Set<String> serverProviders;
  final AuthenticationState state;
  final AuthenticationViewState viewState;

  @override
  Widget build(BuildContext context) {
    final localizationEnabled =
        GichoLocalization.maybeOf(context)?.isAvailable ?? true;
    return ListenableBuilder(
      listenable: moztopiaTheme,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) =>
            _translated(context, configuration.copy.headingKey),
        theme: moztopiaTheme.lightTheme,
        darkTheme: moztopiaTheme.darkTheme,
        themeMode: moztopiaTheme.mode,
        localizationsDelegates: [
          if (localizationEnabled) ...context.localizationDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: localizationEnabled
            ? context.supportedLocales
            : const <Locale>[Locale('en', 'US')],
        locale: localizationEnabled ? context.locale : null,
        home: _AuthenticationSurface(
          configuration: configuration,
          delegate: delegate,
          serverProviders: serverProviders,
          state: state,
          viewState: viewState,
        ),
      ),
    );
  }
}

final class _AuthenticationSurface extends StatelessWidget {
  const _AuthenticationSurface({
    required this.configuration,
    required this.delegate,
    required this.serverProviders,
    required this.state,
    required this.viewState,
  });

  final AuthenticationConfiguration configuration;
  final AuthenticationDelegate delegate;
  final Set<String> serverProviders;
  final AuthenticationState state;
  final AuthenticationViewState viewState;

  @override
  Widget build(BuildContext context) {
    final authenticating =
        state == AuthenticationState.authenticating ||
        state == AuthenticationState.checking;
    final primary = configuration
        .providersAt(AuthenticationProviderPlacement.primary)
        .toList(growable: false);
    final secondary = configuration
        .providersAt(AuthenticationProviderPlacement.secondary)
        .toList(growable: false);
    final copy = configuration.copy;
    final providerLabel = _activeProviderLabel(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: delegate.buildAuthenticationBrand(context),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _translated(context, copy.headingKey),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _translated(context, copy.introductionKey),
                          textAlign: TextAlign.center,
                        ),
                        if (authenticating) ...[
                          const SizedBox(height: 28),
                          const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 16),
                          Text(
                            _translated(
                              context,
                              copy.phaseKeys[viewState.phase]!,
                              provider: providerLabel,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (viewState.phase ==
                              AuthenticationPhase.browser) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: delegate.cancelAuthentication,
                              child: Text(_translated(context, copy.cancelKey)),
                            ),
                          ],
                        ] else ...[
                          if (viewState.failure case final failure?) ...[
                            const SizedBox(height: 24),
                            _FailureNotice(
                              message: _translated(
                                context,
                                copy.failureKeys[failure]!,
                                provider: providerLabel,
                              ),
                            ),
                            const SizedBox(height: 28),
                            FilledButton.icon(
                              onPressed: delegate.retry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(_translated(context, copy.retryKey)),
                            ),
                          ] else ...[
                            const SizedBox(height: 28),
                            for (final provider in primary) ...[
                              _ProviderButton(
                                provider: provider,
                                serverConfigured: serverProviders.contains(
                                  provider.slug,
                                ),
                                copy: copy,
                                onPressed: delegate.startProvider,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (secondary.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openSecondaryProviders(context, secondary),
                                icon: const Icon(Icons.more_horiz_rounded),
                                label: Text(
                                  _translated(context, copy.moreProvidersKey),
                                ),
                              ),
                          ],
                        ],
                        const SizedBox(height: 12),
                        Text(
                          _translated(context, copy.agreementKey),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _activeProviderLabel(BuildContext context) {
    final slug = viewState.provider ?? 'google';
    final configured = configuration.providers.where(
      (provider) => provider.slug == slug,
    );
    return configured.isEmpty
        ? slug
        : _translated(context, configured.first.labelKey);
  }

  Future<void> _openSecondaryProviders(
    BuildContext context,
    List<AuthenticationProviderConfiguration> providers,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => _SecondaryProvidersPage(
        providers: providers,
        serverProviders: serverProviders,
        copy: configuration.copy,
        onPressed: (provider) {
          Navigator.of(context).pop();
          unawaited(delegate.startProvider(provider));
        },
      ),
    ),
  );
}

final class _SecondaryProvidersPage extends StatelessWidget {
  const _SecondaryProvidersPage({
    required this.providers,
    required this.serverProviders,
    required this.copy,
    required this.onPressed,
  });

  final List<AuthenticationProviderConfiguration> providers;
  final Set<String> serverProviders;
  final AuthenticationCopyConfiguration copy;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Tooltip(
        message: _translated(context, copy.backKey),
        child: const BackButton(),
      ),
      title: Text(_translated(context, copy.moreProvidersTitleKey)),
    ),
    body: SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: providers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final provider = providers[index];
          return _ProviderButton(
            provider: provider,
            serverConfigured: serverProviders.contains(provider.slug),
            copy: copy,
            onPressed: onPressed,
          );
        },
      ),
    ),
  );
}

final class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.serverConfigured,
    required this.copy,
    required this.onPressed,
  });

  final AuthenticationProviderConfiguration provider;
  final bool serverConfigured;
  final AuthenticationCopyConfiguration copy;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) {
    final label = _translated(context, provider.labelKey);
    final enabled = provider.enabled && serverConfigured;
    final disabledKey = serverConfigured
        ? copy.configuredDisabledKey
        : copy.serverUnavailableKey;
    final reason = _translated(context, disabledKey, provider: label);
    final button = FilledButton.icon(
      onPressed: enabled ? () => onPressed(provider.slug) : null,
      icon: const Icon(Icons.login_rounded),
      label: Text(label),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: enabled ? null : reason,
      child: enabled ? button : Tooltip(message: reason, child: button),
    );
  }
}

final class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _translated(BuildContext context, String key, {String? provider}) {
  final localization = GichoLocalization.maybeOf(context);
  if (localization != null && !localization.isAvailable) return key;
  return translate(
    key,
    context: context,
    namedArgs: provider == null ? null : {'provider': provider},
  );
}

/// Provides authentication orchestration state to descendant widgets.
final class AuthenticationScope extends InheritedWidget {
  const AuthenticationScope({
    super.key,
    required this.runtime,
    required super.child,
  });

  final AuthenticationRuntime runtime;

  static AuthenticationScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw StateError(
        'Gicho authentication state is unavailable. '
        'Wrap this subtree in GichoBootstrap.',
      );
    }
    return scope;
  }

  static AuthenticationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthenticationScope>();

  @override
  bool updateShouldNotify(AuthenticationScope oldWidget) =>
      runtime.isAvailable != oldWidget.runtime.isAvailable ||
      runtime.state != oldWidget.runtime.state ||
      !identical(runtime.delegate, oldWidget.runtime.delegate);
}
