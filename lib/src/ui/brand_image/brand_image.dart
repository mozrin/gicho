import 'package:flutter/material.dart';

import '../../features/branding/brand/index.dart';

/// A full application logo or compact mark with an accessible fallback.
class GichoBrandImage extends StatelessWidget {
  const GichoBrandImage({
    super.key,
    required this.brand,
    this.compact = false,
  });

  final GichoBrand brand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final asset = compact ? brand.markAsset : brand.logoAsset;
    final height = compact ? 32.0 : 96.0;
    return Semantics(
      label: brand.name,
      image: true,
      child: ExcludeSemantics(
        child: asset == null
            ? _fallback(context)
            : Image.asset(
                asset,
                width: compact ? 32 : null,
                height: height,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _fallback(context),
              ),
      ),
    );
  }

  Widget _fallback(BuildContext context) => compact
      ? Icon(
          Icons.layers_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        )
      : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(brand.name, style: Theme.of(context).textTheme.headlineSmall),
          ],
        );
}
