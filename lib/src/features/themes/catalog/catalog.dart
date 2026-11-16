import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../theme_builder/index.dart';

/// Permanent named theme definitions supplied by Gicho assets.
class ThemeCatalog {
  const ThemeCatalog._(this._colors, this._labels);

  static const names = ['default', 'ocean', 'ember'];

  final Map<String, Color> _colors;
  final Map<String, String> _labels;

  static Future<ThemeCatalog> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    final colors = <String, Color>{};
    final labels = <String, String>{};
    for (final name in names) {
      final path = 'packages/gicho/assets/themes/$name.yaml';
      final values = loadYaml(await assets.loadString(path));
      if (values is! YamlMap ||
          values['name'] is! String ||
          values['seedColor'] is! String) {
        throw FormatException('$path must define name and seedColor');
      }
      final hex = values['seedColor'] as String;
      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) {
        throw FormatException('$path has an invalid seedColor');
      }
      labels[name] = values['name'] as String;
      colors[name] = Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
    return ThemeCatalog._(Map.unmodifiable(colors), Map.unmodifiable(labels));
  }

  String displayName(String name) {
    final label = _labels[name];
    if (label == null) {
      throw ArgumentError.value(name, 'name', 'Unknown Gicho theme');
    }
    return label;
  }

  ThemeData theme(String name, Brightness brightness) {
    final color = _colors[name];
    if (color == null) {
      throw ArgumentError.value(name, 'name', 'Unknown Gicho theme');
    }
    return gichoTheme(seedColor: color, brightness: brightness);
  }
}
