import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:json_schema/json_schema.dart';
import 'package:yaml/yaml.dart';

/// Schema-controlled configuration inheritance independent of any feature.
class GichoConfigurationService {
  const GichoConfigurationService();

  Future<Map<String, dynamic>> load({
    required String defaultsAsset,
    required String schemaAsset,
    String? consumerAsset,
    String? consumerSchemaAsset,
    Map<String, dynamic> overrides = const {},
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final defaults = _yaml(
      await assets.loadString(defaultsAsset),
      defaultsAsset,
    );
    final schema = _schema(await assets.loadString(schemaAsset), schemaAsset);
    Map<String, dynamic> consumer = {};
    Map<String, dynamic>? consumerSchema;
    if (consumerAsset != null || consumerSchemaAsset != null) {
      // Consult the manifest rather than swallowing errors from present assets.
      final available = (await AssetManifest.loadFromAssetBundle(assets))
          .listAssets();
      if (consumerAsset != null && available.contains(consumerAsset)) {
        consumer = _yaml(await assets.loadString(consumerAsset), consumerAsset);
      }
      if (consumerSchemaAsset != null &&
          available.contains(consumerSchemaAsset)) {
        consumerSchema = _schema(
          await assets.loadString(consumerSchemaAsset),
          consumerSchemaAsset,
        );
      }
    }
    return resolve(
      defaults: defaults,
      schema: schema,
      consumer: consumer,
      consumerSchema: consumerSchema,
      overrides: overrides,
    );
  }

  /// Loads Gicho's bundled defaults and optional application assets.
  Future<Map<String, dynamic>> loadApplication({
    String consumerAsset = 'assets/gicho/gicho.yaml',
    String consumerSchemaAsset = 'assets/gicho/gicho.schema.json',
    Map<String, dynamic> overrides = const {},
    AssetBundle? bundle,
  }) async {
    final values = await load(
      defaultsAsset: 'packages/gicho/assets/gicho.yaml',
      schemaAsset: 'packages/gicho/assets/gicho.schema.json',
      consumerAsset: consumerAsset,
      consumerSchemaAsset: consumerSchemaAsset,
      overrides: overrides,
      bundle: bundle,
    );
    if (kReleaseMode && values['placeLookup'] is Map) {
      throw StateError(
        'Bundled place lookup keys are blocked in release mode. '
        'Configure a secure provider before deployment.',
      );
    }
    return values;
  }

  Map<String, dynamic> resolve({
    required Map<String, dynamic> defaults,
    required Map<String, dynamic> schema,
    Map<String, dynamic> consumer = const {},
    Map<String, dynamic>? consumerSchema,
    Map<String, dynamic> overrides = const {},
  }) {
    _checkReferences(schema, schema);
    _validate(defaults, schema, 'package defaults');
    final combined = consumerSchema == null
        ? schema
        : _extendSchema(schema, consumerSchema);
    _checkReferences(combined, combined);
    final partial = _partial(combined);
    _validate(consumer, partial, 'consumer configuration');
    _validate(overrides, partial, 'configuration argument');
    final inherited = _merge(defaults, consumer, combined, combined);
    final resolved = _merge(inherited, overrides, combined, combined);
    _validate(resolved, combined, 'resolved configuration');
    return _freeze(resolved) as Map<String, dynamic>;
  }

  Map<String, dynamic> _extendSchema(
    Map<String, dynamic> schema,
    Map<String, dynamic> consumerSchema,
  ) {
    const allowedRootKeys = {
      '\$schema',
      'title',
      'description',
      'type',
      'properties',
    };
    if (consumerSchema.keys.any((key) => !allowedRootKeys.contains(key)) ||
        consumerSchema['type'] != 'object') {
      throw const FormatException(
        'Consumer schema may describe only the app subtree',
      );
    }
    final extensionProperties = consumerSchema['properties'];
    if (extensionProperties is! Map ||
        extensionProperties.length != 1 ||
        !extensionProperties.containsKey('app')) {
      throw const FormatException(
        'Consumer schema must declare only properties.app',
      );
    }
    final extension = extensionProperties['app'];
    if (extension is! Map<String, dynamic> ||
        extension['type'] != 'object' ||
        (extension.containsKey('additionalProperties') &&
            extension['additionalProperties'] != false) ||
        extension.containsKey('x-moztopia-locked')) {
      throw const FormatException(
        'Consumer app schema must be a closed object',
      );
    }
    final appProperties = extension['properties'];
    if (appProperties is! Map<String, dynamic>) {
      throw const FormatException(
        'Consumer app schema must declare properties',
      );
    }
    final packageProperties = schema['properties'];
    if (packageProperties is! Map<String, dynamic> ||
        packageProperties['app'] is! Map<String, dynamic>) {
      throw const FormatException('Package schema must own an app object');
    }
    final packageApp = packageProperties['app'] as Map<String, dynamic>;
    final packageAppProperties = packageApp['properties'];
    if (packageAppProperties is! Map<String, dynamic> ||
        appProperties.keys.any(packageAppProperties.containsKey)) {
      throw const FormatException(
        'Consumer app keys must not redefine package keys',
      );
    }
    final required = extension['required'];
    if (required != null &&
        (required is! List || required.any((item) => item is! String))) {
      throw const FormatException('Consumer app required keys must be names');
    }
    final combinedApp = <String, dynamic>{
      ...packageApp,
      ...extension,
      'type': 'object',
      'additionalProperties': false,
      'properties': {...packageAppProperties, ...appProperties},
      'required': [
        ...(packageApp['required'] as List? ?? const []),
        ...?(required as List?),
      ],
    };
    return {
      ...schema,
      'properties': {...packageProperties, 'app': combinedApp},
    };
  }

  Map<String, dynamic> _yaml(String source, String location) {
    final value = loadYaml(source);
    if (value == null) {
      return {};
    }
    final decoded = _plain(value);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$location must contain an object');
    }
    return decoded;
  }

  Map<String, dynamic> _schema(String source, String location) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('schema must contain an object');
      }
      return decoded;
    } on FormatException catch (error) {
      throw FormatException('$location: ${error.message}');
    }
  }

  Object? _plain(Object? value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw const FormatException('Configuration keys must be strings');
        }
        result[entry.key as String] = _plain(entry.value);
      }
      return result;
    }
    if (value is List) {
      return value.map(_plain).toList();
    }
    return value;
  }

  void _validate(
    Map<String, dynamic> values,
    Map<String, dynamic> schema,
    String source,
  ) {
    final result = JsonSchema.create(schema).validate(values);
    if (!result.isValid) {
      throw FormatException('$source: ${result.errors.join('; ')}');
    }
  }

  // Remove required properties only from schema nodes, never from data values.
  Map<String, dynamic> _partial(Map<String, dynamic> node) {
    final result = Map<String, dynamic>.from(node)..remove('required');
    for (final key in [
      'properties',
      '\$defs',
      'definitions',
      'patternProperties',
    ]) {
      final children = result[key];
      if (children is Map) {
        result[key] = {
          for (final entry in children.entries)
            entry.key: entry.value is Map
                ? _partial(Map<String, dynamic>.from(entry.value as Map))
                : entry.value,
        };
      }
    }
    for (final key in [
      'items',
      'additionalProperties',
      'if',
      'then',
      'else',
      'not',
    ]) {
      if (result[key] is Map) {
        result[key] = _partial(Map<String, dynamic>.from(result[key] as Map));
      }
    }
    for (final key in ['allOf', 'anyOf', 'oneOf', 'prefixItems']) {
      if (result[key] is List) {
        result[key] = (result[key] as List)
            .map(
              (item) => item is Map
                  ? _partial(Map<String, dynamic>.from(item))
                  : item,
            )
            .toList();
      }
    }
    return result;
  }

  Map<String, dynamic> _node(
    Map<String, dynamic> node,
    Map<String, dynamic> root,
  ) {
    final ref = node['\$ref'];
    if (ref == null) {
      return node;
    }
    if (ref is! String || !ref.startsWith('#/')) {
      throw const FormatException(
        'Only local configuration schema references are supported',
      );
    }
    dynamic target = root;
    for (final key in ref.substring(2).split('/')) {
      target = target is Map
          ? target[key.replaceAll('~1', '/').replaceAll('~0', '~')]
          : null;
    }
    if (target is! Map<String, dynamic>) {
      throw FormatException('Unresolved schema reference: $ref');
    }
    if (target.containsKey('\$ref')) {
      throw const FormatException('Chained schema references are unsupported');
    }
    return {...target, ...node}..remove('\$ref');
  }

  void _checkReferences(Map<String, dynamic> node, Map<String, dynamic> root) {
    _node(node, root);
    // Merge annotations in composite schemas are ambiguous; reject instead of
    // silently bypassing their locking policy.
    for (final key in [
      'allOf',
      'anyOf',
      'oneOf',
      'if',
      'then',
      'else',
      'patternProperties',
    ]) {
      if (node.containsKey(key)) {
        throw FormatException(
          'Unsupported configuration merge schema keyword: $key',
        );
      }
    }
    for (final key in ['properties', '\$defs', 'definitions']) {
      final children = node[key];
      if (children is Map) {
        for (final child in children.values) {
          if (child is Map<String, dynamic>) {
            _checkReferences(child, root);
          }
        }
      }
    }
  }

  Map<String, dynamic> _merge(
    Map<String, dynamic> base,
    Map<String, dynamic> change,
    Map<String, dynamic> schema,
    Map<String, dynamic> root,
  ) {
    final node = _node(schema, root);
    if (node['x-moztopia-locked'] == true) {
      return Map<String, dynamic>.from(base);
    }
    final properties = node['properties'] as Map? ?? {};
    final result = Map<String, dynamic>.from(base);
    for (final entry in change.entries) {
      final raw = properties[entry.key] ?? node['additionalProperties'];
      final child = raw is Map
          ? _node(Map<String, dynamic>.from(raw), root)
          : <String, dynamic>{};
      if (child['x-moztopia-locked'] == true) {
        continue;
      }
      final previous = base[entry.key];
      final next = entry.value;
      if (next is Map<String, dynamic>) {
        result[entry.key] = _merge(
          previous is Map<String, dynamic> ? previous : {},
          next,
          child,
          root,
        );
      } else {
        result[entry.key] = next;
      }
    }
    return result;
  }

  Object? _freeze(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.unmodifiable(
        value.map((key, item) => MapEntry(key, _freeze(item))),
      );
    }
    if (value is List) {
      return List<dynamic>.unmodifiable(value.map(_freeze));
    }
    return value;
  }
}
