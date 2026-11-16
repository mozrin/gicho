import '../config/configuration_registry.dart';
import 'core_configuration.dart';

/// Loads and retains package-wide composition policy.
final class MoztopiaCore {
  MoztopiaCore({ConfigurationRegistry? configurationRegistry})
    : _configurationRegistry = configurationRegistry ?? moztopiaConfig;

  final ConfigurationRegistry _configurationRegistry;
  Future<GichoCoreConfiguration>? _initialization;
  GichoCoreConfiguration? _configuration;

  Future<GichoCoreConfiguration> initialize() => _initialization ??= _load();

  GichoCoreConfiguration get configuration =>
      _configuration ??
      (throw StateError('Moztopia core has not been initialized.'));

  Future<GichoCoreConfiguration> _load() async {
    final document = await _configurationRegistry.loadFeature('core');
    return _configuration = GichoCoreConfiguration.fromDocument(document);
  }
}

final moztopiaCore = MoztopiaCore();
