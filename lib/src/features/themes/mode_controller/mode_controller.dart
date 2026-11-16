import 'package:flutter/material.dart';

/// Persists appearance mode for the currently bound account or context.
/// The application supplies its own light and dark themes.
class GichoThemeModeController extends ChangeNotifier {
  GichoThemeModeController({
    required this.readPreference,
    required this.writePreference,
  });

  final Future<String?> Function(String key) readPreference;
  final Future<void> Function(String key, String value) writePreference;
  String? _preferenceKey;
  ThemeMode _mode = ThemeMode.system;
  int _generation = 0;
  int _modeRevision = 0;
  bool _writePending = false;

  ThemeMode get mode => _mode;
  bool get isWriting => _writePending;

  /// Clears the previous account immediately, then restores this key if set.
  Future<void> bind(
    String? preferenceKey, {
    ThemeMode initialMode = ThemeMode.system,
  }) async {
    final generation = ++_generation;
    final modeRevision = ++_modeRevision;
    _preferenceKey = preferenceKey;
    _writePending = false;
    _mode = initialMode;
    notifyListeners();
    if (preferenceKey == null) {
      return;
    }
    final saved = await readPreference(preferenceKey);
    if (generation != _generation || modeRevision != _modeRevision) {
      return;
    }
    final restored = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => initialMode,
    };
    if (restored != _mode) {
      _mode = restored;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    final key = _preferenceKey;
    if (key == null) {
      throw StateError('Bind a preference key before changing theme mode');
    }
    if (_writePending) {
      throw StateError('A theme mode change is already in progress');
    }
    if (_mode == mode) {
      return;
    }
    final generation = _generation;
    final previous = _mode;
    _modeRevision++;
    _writePending = true;
    _mode = mode;
    notifyListeners();
    try {
      await writePreference(key, mode.name);
    } catch (_) {
      if (generation == _generation) {
        _mode = previous;
        notifyListeners();
      }
      rethrow;
    } finally {
      if (generation == _generation) {
        _writePending = false;
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
