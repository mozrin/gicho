import 'package:flutter/material.dart';

import '../../features/branding/brand/index.dart';
import '../brand_image/index.dart';

/// Generic application branding, independent of authentication.
class GichoBrandHeader extends StatelessWidget {
  const GichoBrandHeader({super.key, required this.title, this.logo})
    : brand = null;

  const GichoBrandHeader.branded({super.key, required this.brand})
    : title = null,
      logo = null;

  final String? title;
  final Widget? logo;
  final GichoBrand? brand;

  @override
  Widget build(BuildContext context) {
    final resolvedBrand = brand;
    if (resolvedBrand != null) {
      return GichoBrandImage(brand: resolvedBrand);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (logo != null) ...[Center(child: logo!), const SizedBox(height: 24)],
        Text(title!, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}
