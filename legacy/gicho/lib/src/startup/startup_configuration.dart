import '../config/configuration_registry.dart';

/// Validated startup settings resolved from `startup.config.yaml`.
final class StartupConfiguration {
  const StartupConfiguration({
    required this.startupPreDelayDuration,
    required this.startupPostDelayDuration,
  });

  final Duration startupPreDelayDuration;
  final Duration startupPostDelayDuration;
}

/// Loads startup defaults and optional consumer overrides.
final class MoztopiaStartup {
  MoztopiaStartup({ConfigurationRegistry? configurationRegistry})
    : _configurationRegistry = configurationRegistry ?? moztopiaConfig;

  final ConfigurationRegistry _configurationRegistry;
  Future<StartupConfiguration>? _initialization;

  Future<StartupConfiguration> initialize() =>
      _initialization ??= _loadConfiguration();

  Future<StartupConfiguration> _loadConfiguration() async {
    final document = await _configurationRegistry.loadFeature('startup');
    return StartupConfiguration(
      startupPreDelayDuration: Duration(
        seconds: document.require<int>('startupPreDelayDurationSeconds'),
      ),
      startupPostDelayDuration: Duration(
        seconds: document.require<int>('startupPostDelayDurationSeconds'),
      ),
    );
  }
}

final moztopiaStartup = MoztopiaStartup();
