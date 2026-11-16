import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../config/configuration_document.dart';
import '../config/configuration_registry.dart';

/// A named simple color palette resolved from theme configuration.
final class MoztopiaThemeDefinition {
  const MoztopiaThemeDefinition({
    required this.id,
    required this.name,
    required this.primary,
    this.secondary,
    this.tertiary,
  });

  final String id;
  final String name;
  final Color primary;
  final Color? secondary;
  final Color? tertiary;

  FlexSchemeColor colors(Brightness brightness) => FlexSchemeColor.from(
    primary: primary,
    secondary: secondary,
    tertiary: tertiary,
    brightness: brightness,
  );
}

/// App-wide theme state backed by package defaults and app YAML overrides.
final class MoztopiaThemeController extends ChangeNotifier {
  MoztopiaThemeController({ConfigurationRegistry? configurationRegistry})
    : _configurationRegistry = configurationRegistry ?? moztopiaConfig;

  final ConfigurationRegistry _configurationRegistry;
  Future<void>? _initialization;
  List<MoztopiaThemeDefinition> _themes = const [];
  String? _selectedThemeId;
  ThemeMode _mode = ThemeMode.system;

  List<MoztopiaThemeDefinition> get themes => List.unmodifiable(_themes);
  ThemeMode get mode => _mode;
  String get selectedThemeId => _selectedThemeId ?? _notInitialized();
  MoztopiaThemeDefinition get selectedTheme =>
      _themes.firstWhere((theme) => theme.id == selectedThemeId);
  ThemeData get lightTheme =>
      FlexThemeData.light(colors: selectedTheme.colors(Brightness.light));
  ThemeData get darkTheme =>
      FlexThemeData.dark(colors: selectedTheme.colors(Brightness.dark));

  Future<void> initialize() => _initialization ??= _load();

  void selectTheme(String id) {
    if (!_themes.any((theme) => theme.id == id)) {
      throw ArgumentError.value(id, 'id', 'Unknown configured theme');
    }
    if (_selectedThemeId == id) return;
    _selectedThemeId = id;
    notifyListeners();
  }

  void selectMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggleMode(Brightness brightness) => selectMode(
    brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  );

  Future<void> _load() async {
    final document = await _configurationRegistry.loadFeature('theme');
    _themes = _parseThemes(document);
    final defaultTheme = document.require<String>('defaultTheme');
    if (!_themes.any((theme) => theme.id == defaultTheme)) {
      throw StateError(
        'Configured defaultTheme "$defaultTheme" is not defined.',
      );
    }
    _selectedThemeId = defaultTheme;
  }

  List<MoztopiaThemeDefinition> _parseThemes(ConfigurationDocument document) {
    final values = document.require<Map<String, dynamic>>('themes');
    return [
      for (final entry in values.entries)
        _parseTheme(entry.key, (entry.value as Map).cast<String, dynamic>()),
    ];
  }

  MoztopiaThemeDefinition _parseTheme(String id, Map<String, dynamic> values) =>
      MoztopiaThemeDefinition(
        id: id,
        name: values['name']! as String,
        primary: _color(values['primary']! as String),
        secondary: _optionalColor(values['secondary']),
        tertiary: _optionalColor(values['tertiary']),
      );

  Color? _optionalColor(Object? value) =>
      value is String ? _color(value) : null;

  Color _color(String value) =>
      Color(int.parse(value.substring(1), radix: 16) | 0xFF000000);

  Never _notInitialized() =>
      throw StateError('Moztopia theme has not been initialized.');
}

final moztopiaTheme = MoztopiaThemeController();
