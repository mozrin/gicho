import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

class ConfigInspectorModal extends StatefulWidget {
  const ConfigInspectorModal({super.key});

  @override
  State<ConfigInspectorModal> createState() => _ConfigInspectorModalState();
}

class _ConfigInspectorModalState extends State<ConfigInspectorModal> {
  String _feature = ConfigurationService.supportedFeatures.first;
  late Future<_ConfigSources> _sources = _loadSources(_feature);

  Future<_ConfigSources> _loadSources(String feature) async {
    const loader = FlutterAssetConfigurationLoader();
    const service = ConfigurationService(loader: loader);
    final packageLocation = ConfigurationService.packageConfigAsset(feature);
    final appLocation = ConfigurationService.appConfigAsset(feature);

    final results = await Future.wait([
      loader.load(packageLocation),
      loader.load(appLocation, optional: true),
      service.loadFeature(feature),
    ]);
    final document = results[2]! as ConfigurationDocument;

    return _ConfigSources(
      packageYaml: results[0]! as String,
      appYaml: results[1] as String? ?? '# No app override supplied.\n',
      mergedYaml: _yaml(document.values),
    );
  }

  void _selectFeature(String? feature) {
    if (feature == null || feature == _feature) return;
    setState(() {
      _feature = feature;
      _sources = _loadSources(feature);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: GichoPageShell(
        appBar: GichoAppBar(
          leading: BackButton(onPressed: context.pop),
          title: const Text('Configuration inspector'),
          showStandardActions: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Package'),
              Tab(text: 'App'),
              Tab(text: 'Merged'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: DropdownButtonFormField<String>(
                initialValue: _feature,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Configuration feature',
                  prefixIcon: Icon(Icons.settings_suggest_outlined),
                ),
                items: [
                  for (final feature in ConfigurationService.supportedFeatures)
                    DropdownMenuItem(
                      value: feature,
                      child: Text(_title(feature)),
                    ),
                ],
                onChanged: _selectFeature,
              ),
            ),
            Expanded(
              child: FutureBuilder<_ConfigSources>(
                key: ValueKey(_feature),
                future: _sources,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SelectableText(
                          'Unable to load $_feature configuration:\n'
                          '${snapshot.error}',
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sources = snapshot.data!;
                  return TabBarView(
                    children: [
                      _YamlView(source: sources.packageYaml),
                      _YamlView(source: sources.appYaml),
                      _YamlView(source: sources.mergedYaml),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YamlView extends StatelessWidget {
  const _YamlView({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            source.trim(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigSources {
  const _ConfigSources({
    required this.packageYaml,
    required this.appYaml,
    required this.mergedYaml,
  });

  final String packageYaml;
  final String appYaml;
  final String mergedYaml;
}

String _title(String value) => '${value[0].toUpperCase()}${value.substring(1)}';

String _yaml(Object? value, {int depth = 0}) {
  final indent = '  ' * depth;
  if (value is Map) {
    return value.entries
        .map((entry) {
          final item = entry.value;
          if (item is Map || item is List) {
            return '$indent${entry.key}:\n${_yaml(item, depth: depth + 1)}';
          }
          return '$indent${entry.key}: ${_scalar(item)}';
        })
        .join('\n');
  }
  if (value is List) {
    return value
        .map((item) {
          if (item is Map || item is List) {
            final nested = _yaml(item, depth: depth + 1).trimLeft();
            return '$indent- $nested';
          }
          return '$indent- ${_scalar(item)}';
        })
        .join('\n');
  }
  return '$indent${_scalar(value)}';
}

String _scalar(Object? value) {
  if (value is String && RegExp(r'^[A-Za-z0-9_./-]+$').hasMatch(value)) {
    return value;
  }
  return jsonEncode(value);
}
