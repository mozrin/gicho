// Focused helper tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:gicho/gicho.dart';

void main() {
  const service = GichoConfigurationService();
  final schema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'required': ['brand', 'providers', 'version'],
    'properties': {
      'version': {'type': 'integer', 'const': 1, 'x-moztopia-locked': true},
      'brand': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['name', 'logo'],
        'properties': {
          'name': {'type': 'string'},
          'logo': {
            'type': ['string', 'null'],
          },
        },
      },
      'providers': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'locked': {'\$ref': '#/\$defs/locked'},
    },
    '\$defs': {
      'locked': {'type': 'string', 'x-moztopia-locked': true},
    },
  };
  final defaults = <String, dynamic>{
    'version': 1,
    'brand': {'name': 'Default', 'logo': null},
    'providers': ['google', 'github'],
    'locked': 'package',
  };

  test(
    'partial layers inherit nested defaults and lists replace explicitly',
    () {
      final result = service.resolve(
        defaults: defaults,
        schema: schema,
        consumer: {
          'brand': {'name': 'Consumer'},
          'providers': ['google'],
        },
        overrides: {
          'brand': {'logo': 'assets/logo.png'},
          'providers': [],
        },
      );
      expect(result['brand'], {'name': 'Consumer', 'logo': 'assets/logo.png'});
      expect(result['providers'], isEmpty);
      expect(
        () => (result['brand'] as Map)['name'] = 'mutation',
        throwsUnsupportedError,
      );
      expect(defaults['brand'], {'name': 'Default', 'logo': null});
    },
  );

  test('schema references retain locks through both override layers', () {
    expect(
      service.resolve(
        defaults: defaults,
        schema: schema,
        consumer: {'locked': 'consumer'},
        overrides: {'locked': 'argument'},
      )['locked'],
      'package',
    );
  });

  test(
    'invalid types, unknown keys and incompatible versions fail clearly',
    () {
      for (final change in <Map<String, dynamic>>[
        {
          'brand': {'unknown': true},
        },
        {'providers': null},
        {'version': 2},
      ]) {
        expect(
          () => service.resolve(
            defaults: defaults,
            schema: schema,
            consumer: change,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('merged result is validated even when partial input passes', () {
    expect(
      () => service.resolve(
        defaults: defaults,
        schema: schema,
        overrides: {
          'brand': {'logo': null},
        },
        consumer: {
          'brand': {'name': 3},
        },
      ),
      throwsFormatException,
    );
    final constrained = <String, dynamic>{
      'type': 'object',
      'maxProperties': 2,
      'properties': {
        'a': {'type': 'integer'},
        'b': {'type': 'integer'},
        'c': {'type': 'integer'},
      },
      'required': ['a', 'b'],
    };
    expect(
      () => service.resolve(
        defaults: {'a': 1, 'b': 2},
        schema: constrained,
        consumer: {'c': 3},
      ),
      throwsFormatException,
    );
  });

  final applicationSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'required': ['schemaVersion', 'app'],
    'properties': {
      'schemaVersion': {
        'type': 'integer',
        'const': 1,
        'x-moztopia-locked': true,
      },
      'app': {
        'type': 'object',
        'additionalProperties': false,
        'properties': <String, dynamic>{},
      },
    },
  };
  final applicationDefaults = <String, dynamic>{
    'schemaVersion': 1,
    'app': <String, dynamic>{},
  };
  final applicationExtension = <String, dynamic>{
    'type': 'object',
    'properties': {
      'app': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['welcome'],
        'properties': {
          'welcome': {'type': 'string'},
          'showQr': {'type': 'boolean'},
        },
      },
    },
  };

  test('app schema extends only consumer keys after package validation', () {
    final result = service.resolve(
      defaults: applicationDefaults,
      schema: applicationSchema,
      consumerSchema: applicationExtension,
      consumer: {
        'app': {'welcome': 'Hello', 'showQr': false},
      },
      overrides: {
        'app': {'showQr': true},
      },
    );
    expect(result, {
      'schemaVersion': 1,
      'app': {'welcome': 'Hello', 'showQr': true},
    });
    expect(applicationDefaults['app'], isEmpty);
    expect(
      () => (result['app'] as Map)['welcome'] = 'changed',
      throwsUnsupportedError,
    );
  });

  test('consumer app keys must satisfy the final combined schema', () {
    for (final consumer in <Map<String, dynamic>>[
      {'app': <String, dynamic>{}},
      {
        'app': {'welcome': 'Hello', 'unknown': true},
      },
      {
        'app': {'welcome': 3},
      },
      {
        'schemaVersion': 2,
        'app': {'welcome': 'Hello'},
      },
    ]) {
      expect(
        () => service.resolve(
          defaults: applicationDefaults,
          schema: applicationSchema,
          consumerSchema: applicationExtension,
          consumer: consumer,
        ),
        throwsFormatException,
      );
    }
  });

  test('consumer schemas cannot redefine package-owned keys', () {
    for (final consumerSchema in <Map<String, dynamic>>[
      {
        'type': 'object',
        'properties': {
          'brand': {'type': 'object'},
        },
      },
      {
        'type': 'object',
        'properties': {
          'app': {'type': 'string', 'properties': <String, dynamic>{}},
        },
      },
      {
        'type': 'object',
        'properties': {
          'app': {
            'type': 'object',
            'additionalProperties': true,
            'properties': <String, dynamic>{},
          },
        },
      },
    ]) {
      expect(
        () => service.resolve(
          defaults: applicationDefaults,
          schema: applicationSchema,
          consumerSchema: consumerSchema,
        ),
        throwsFormatException,
      );
    }
  });
}
