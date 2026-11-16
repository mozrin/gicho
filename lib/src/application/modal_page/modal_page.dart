import 'package:flutter/material.dart';

import '../../features/branding/brand/index.dart';
import '../page_frame/index.dart';

/// A full-page guided flow with optional Back and no ancillary navigation.
class GichoModalPage extends StatelessWidget {
  const GichoModalPage({
    super.key,
    required this.title,
    required this.body,
    this.brand,
    this.showBrand = true,
    this.backLabel,
    this.showBackButton = true,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final GichoBrand? brand;
  final bool showBrand;
  final String? backLabel;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: Text(title),
      brand: brand,
      showBrand: showBrand,
      body: body,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              tooltip:
                  backLabel ??
                  MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions,
    );
  }
}
