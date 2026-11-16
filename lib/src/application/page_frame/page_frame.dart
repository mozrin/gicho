import 'package:flutter/material.dart';

import '../../features/branding/brand/index.dart';
import '../../ui/brand_image/index.dart';

/// Common Material page chrome for shell and modal presentations.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.body,
    this.brand,
    this.showBrand = true,
    this.titlePrefix,
    this.onTitlePressed,
    this.leading,
    this.actions = const [],
    this.scaffoldKey,
    this.drawer,
    this.onDrawerChanged,
    this.automaticallyImplyLeading = true,
  });

  final Widget title;
  final Widget body;
  final GichoBrand? brand;
  final bool showBrand;
  final Widget? titlePrefix;
  final VoidCallback? onTitlePressed;
  final Widget? leading;
  final List<Widget> actions;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? drawer;
  final DrawerCallback? onDrawerChanged;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: leading,
        title: titlePrefix != null || brand != null && showBrand
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (titlePrefix != null)
                    titlePrefix!
                  else
                    GichoBrandImage(brand: brand!, compact: true),
                  const SizedBox(width: 8),
                  Flexible(child: _titleControl()),
                ],
              )
            : _titleControl(),
        actions: actions,
      ),
      drawer: drawer,
      onDrawerChanged: onDrawerChanged,
      body: SafeArea(child: body),
    );
  }

  Widget _titleControl() => onTitlePressed == null
      ? title
      : InkWell(
          onTap: onTitlePressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: title,
          ),
        );
}
