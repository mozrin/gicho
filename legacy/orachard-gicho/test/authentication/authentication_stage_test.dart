import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await moztopiaLog.initialize();
    await moztopiaTheme.initialize();
  });

  testWidgets('shows enabled primary providers and starts the selected slug', (
    tester,
  ) async {
    final delegate = _AuthenticationDelegate({'google'});

    await _pumpStage(tester, delegate, _configuration());

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('provider.google'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);
    await tester.tap(find.text('provider.google'));
    expect(delegate.startedProviders, ['google']);
  });

  testWidgets('keeps disabled providers visible and omitted providers absent', (
    tester,
  ) async {
    final delegate = _AuthenticationDelegate({'google', 'github'});

    await _pumpStage(tester, delegate, _configuration(googleEnabled: false));

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('provider.google'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text('provider.github'), findsNothing);
    expect(find.text('copy.more'), findsNothing);
  });

  testWidgets('disables a configured provider missing from the server', (
    tester,
  ) async {
    final delegate = _AuthenticationDelegate({});

    await _pumpStage(tester, delegate, _configuration());

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('provider.google'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(
      tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .any((tooltip) => tooltip.message == 'copy.server'),
      isTrue,
    );
  });

  testWidgets('opens secondary providers on a full modal page with back', (
    tester,
  ) async {
    final delegate = _AuthenticationDelegate({'google', 'github'});

    await _pumpStage(tester, delegate, _configuration(includeSecondary: true));

    expect(find.text('provider.github'), findsNothing);
    expect(find.text('copy.more'), findsOneWidget);
    await tester.tap(find.text('copy.more'));
    await tester.pumpAndSettle();

    expect(find.text('copy.moreTitle'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('provider.github'), findsOneWidget);

    await tester.tap(find.text('provider.github'));
    await tester.pumpAndSettle();
    expect(delegate.startedProviders, ['github']);
    expect(find.text('copy.moreTitle'), findsNothing);
  });
}

Future<void> _pumpStage(
  WidgetTester tester,
  _AuthenticationDelegate delegate,
  AuthenticationConfiguration configuration,
) async {
  await tester.pumpWidget(
    GichoLocalizationScope(
      state: const GichoLocalizationState.unavailable(),
      child: AuthenticationStage(
        delegate: delegate,
        configuration: configuration,
        child: const Text('AUTHENTICATED'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AuthenticationConfiguration _configuration({
  bool googleEnabled = true,
  bool includeSecondary = false,
}) => AuthenticationConfiguration(
  copy: const AuthenticationCopyConfiguration(
    headingKey: 'copy.heading',
    introductionKey: 'copy.introduction',
    agreementKey: 'copy.agreement',
    moreProvidersKey: 'copy.more',
    moreProvidersTitleKey: 'copy.moreTitle',
    backKey: 'copy.back',
    cancelKey: 'copy.cancel',
    retryKey: 'copy.retry',
    configuredDisabledKey: 'copy.disabled',
    serverUnavailableKey: 'copy.server',
    phaseKeys: {
      AuthenticationPhase.checking: 'phase.checking',
      AuthenticationPhase.starting: 'phase.starting',
      AuthenticationPhase.browser: 'phase.browser',
      AuthenticationPhase.exchanging: 'phase.exchanging',
      AuthenticationPhase.refreshing: 'phase.refreshing',
    },
    failureKeys: {
      AuthenticationFailure.cancelled: 'failure.cancelled',
      AuthenticationFailure.offline: 'failure.offline',
      AuthenticationFailure.browserUnavailable: 'failure.browser',
      AuthenticationFailure.providerUnavailable: 'failure.provider',
      AuthenticationFailure.resultExpired: 'failure.result',
      AuthenticationFailure.sessionEnded: 'failure.session',
      AuthenticationFailure.storageUnavailable: 'failure.storage',
      AuthenticationFailure.generic: 'failure.generic',
    },
  ),
  providers: [
    AuthenticationProviderConfiguration(
      slug: 'google',
      labelKey: 'provider.google',
      placement: AuthenticationProviderPlacement.primary,
      enabled: googleEnabled,
    ),
    if (includeSecondary)
      const AuthenticationProviderConfiguration(
        slug: 'github',
        labelKey: 'provider.github',
        placement: AuthenticationProviderPlacement.secondary,
        enabled: true,
      ),
  ],
);

final class _AuthenticationDelegate implements AuthenticationDelegate {
  _AuthenticationDelegate(this.providers);

  final Set<String> providers;
  final List<String> startedProviders = [];
  final ValueNotifier<AuthenticationState> _state = ValueNotifier(
    AuthenticationState.unauthenticated,
  );
  final ValueNotifier<AuthenticationViewState> _viewState = ValueNotifier(
    const AuthenticationViewState(),
  );

  @override
  ValueListenable<AuthenticationState> get state => _state;

  @override
  ValueListenable<AuthenticationViewState> get viewState => _viewState;

  @override
  Future<void> initialize() async {}

  @override
  Future<Set<String>> getProviders() async => providers;

  @override
  Future<void> startProvider(String provider) async {
    startedProviders.add(provider);
  }

  @override
  Future<void> retry() async {}

  @override
  Future<void> cancelAuthentication() async {}

  @override
  Widget buildAuthenticationBrand(BuildContext context) => const Text('BRAND');

  @override
  Future<void> logout() async {}

  @override
  void dispose() {
    _state.dispose();
    _viewState.dispose();
  }
}
