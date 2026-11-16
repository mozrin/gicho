import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../catalog/index.dart';

/// Application theme choices and device-local user preference.
class ThemeController extends ChangeNotifier {
  ThemeController({
    required this.catalog,
    required List<String> available,
    required String defaultName,
    Future<String?> Function(String key)? readPreference,
    Future<void> Function(String key, String value)? writePreference,
  }) : available = List.unmodifiable(available),
       _readPreference = readPreference ?? SharedPreferencesAsync().getString,
       _writePreference = writePreference ?? SharedPreferencesAsync().setString,
       _name = defaultName {
    if (available.isEmpty ||
        !available.contains(defaultName) ||
        available.any((name) => !ThemeCatalog.names.contains(name))) {
      throw ArgumentError('The default theme must be in the allowed subset');
    }
  }

  factory ThemeController.fromConfiguration({
    required ThemeCatalog catalog,
    required Map<String, dynamic> configuration,
    Future<String?> Function(String key)? readPreference,
    Future<void> Function(String key, String value)? writePreference,
  }) {
    final values = configuration['theme'] as Map<String, dynamic>;
    return ThemeController(
      catalog: catalog,
      available: (values['available'] as List).cast<String>(),
      defaultName: values['default'] as String,
      readPreference: readPreference,
      writePreference: writePreference,
    );
  }

  final ThemeCatalog catalog;
  final List<String> available;
  final Future<String?> Function(String key) _readPreference;
  final Future<void> Function(String key, String value) _writePreference;
  String _name;
  ThemeMode _mode = ThemeMode.system;

  String get name => _name;
  ThemeMode get mode => _mode;
  ThemeData get lightTheme => catalog.theme(_name, Brightness.light);
  ThemeData get darkTheme => catalog.theme(_name, Brightness.dark);

  Future<void> restore() async {
    final savedName = await _readPreference('gicho.theme.name');
    final savedMode = await _readPreference('gicho.theme.mode');
    if (savedName != null && available.contains(savedName)) {
      _name = savedName;
    }
    _mode = switch (savedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> select(String name) async {
    if (!available.contains(name)) {
      throw ArgumentError.value(name, 'name', 'Theme is not available');
    }
    _name = name;
    notifyListeners();
    await _writePreference('gicho.theme.name', name);
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _writePreference('gicho.theme.mode', mode.name);
  }
}
