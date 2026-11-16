import '../config/configuration_document.dart';
import '../config/configuration_registry.dart';
import 'authentication_delegate.dart';

enum AuthenticationProviderPlacement { primary, secondary }

final class AuthenticationProviderConfiguration {
  const AuthenticationProviderConfiguration({
    required this.slug,
    required this.labelKey,
    required this.placement,
    required this.enabled,
  });

  final String slug;
  final String labelKey;
  final AuthenticationProviderPlacement placement;
  final bool enabled;
}

final class AuthenticationCopyConfiguration {
  const AuthenticationCopyConfiguration({
    required this.headingKey,
    required this.introductionKey,
    required this.agreementKey,
    required this.moreProvidersKey,
    required this.moreProvidersTitleKey,
    required this.backKey,
    required this.cancelKey,
    required this.retryKey,
    required this.configuredDisabledKey,
    required this.serverUnavailableKey,
    required this.phaseKeys,
    required this.failureKeys,
  });

  final String headingKey;
  final String introductionKey;
  final String agreementKey;
  final String moreProvidersKey;
  final String moreProvidersTitleKey;
  final String backKey;
  final String cancelKey;
  final String retryKey;
  final String configuredDisabledKey;
  final String serverUnavailableKey;
  final Map<AuthenticationPhase, String> phaseKeys;
  final Map<AuthenticationFailure, String> failureKeys;
}

final class AuthenticationConfiguration {
  const AuthenticationConfiguration({
    required this.copy,
    required this.providers,
  });

  final AuthenticationCopyConfiguration copy;
  final List<AuthenticationProviderConfiguration> providers;

  Iterable<AuthenticationProviderConfiguration> providersAt(
    AuthenticationProviderPlacement placement,
  ) => providers.where((provider) => provider.placement == placement);

  factory AuthenticationConfiguration.fromDocument(
    ConfigurationDocument document,
  ) {
    final rawProviders = document.require<List<dynamic>>('providers');
    final providers = <AuthenticationProviderConfiguration>[];
    final slugs = <String>{};
    for (final rawProvider in rawProviders) {
      final values = (rawProvider as Map).cast<String, dynamic>();
      final slug = values['slug']! as String;
      if (!slugs.add(slug)) {
        throw StateError('Authentication provider "$slug" is duplicated.');
      }
      providers.add(
        AuthenticationProviderConfiguration(
          slug: slug,
          labelKey: values['label']! as String,
          placement: AuthenticationProviderPlacement.values.byName(
            values['placement']! as String,
          ),
          enabled: values['enabled']! as bool,
        ),
      );
    }
    if (!slugs.contains('google')) {
      throw StateError(
        'Authentication configuration must include the Google provider.',
      );
    }

    return AuthenticationConfiguration(
      providers: List.unmodifiable(providers),
      copy: AuthenticationCopyConfiguration(
        headingKey: document.require<String>('copy.heading'),
        introductionKey: document.require<String>('copy.introduction'),
        agreementKey: document.require<String>('copy.agreement'),
        moreProvidersKey: document.require<String>('copy.moreProviders'),
        moreProvidersTitleKey: document.require<String>(
          'copy.moreProvidersTitle',
        ),
        backKey: document.require<String>('copy.back'),
        cancelKey: document.require<String>('copy.cancel'),
        retryKey: document.require<String>('copy.retry'),
        configuredDisabledKey: document.require<String>(
          'copy.configuredDisabled',
        ),
        serverUnavailableKey: document.require<String>(
          'copy.serverUnavailable',
        ),
        phaseKeys: Map.unmodifiable({
          for (final phase in AuthenticationPhase.values)
            phase: document.require<String>('copy.phases.${phase.name}'),
        }),
        failureKeys: Map.unmodifiable({
          for (final failure in AuthenticationFailure.values)
            failure: document.require<String>('copy.failures.${failure.name}'),
        }),
      ),
    );
  }
}

final class MoztopiaAuthentication {
  MoztopiaAuthentication({ConfigurationRegistry? configurationRegistry})
    : _configurationRegistry = configurationRegistry ?? moztopiaConfig;

  final ConfigurationRegistry _configurationRegistry;
  Future<AuthenticationConfiguration>? _initialization;

  Future<AuthenticationConfiguration> initialize() =>
      _initialization ??= _load();

  Future<AuthenticationConfiguration> _load() async =>
      AuthenticationConfiguration.fromDocument(
        await _configurationRegistry.loadFeature('authentication'),
      );
}

final moztopiaAuthentication = MoztopiaAuthentication();
