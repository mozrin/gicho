/// Generic application identity shared by Gicho and higher-level packages.
class GichoBrand {
  const GichoBrand({required this.name, this.logoAsset, this.markAsset});

  factory GichoBrand.fromConfiguration(Map<String, dynamic> configuration) {
    final values = configuration['brand'] as Map<String, dynamic>;
    return GichoBrand(
      name: values['name'] as String,
      logoAsset: values['logoAsset'] as String?,
      markAsset: values['markAsset'] as String?,
    );
  }

  final String name;
  final String? logoAsset;
  final String? markAsset;
}
