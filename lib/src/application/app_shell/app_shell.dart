import 'package:flutter/material.dart';

import '../../features/branding/brand/index.dart';
import '../../features/localization/locale_controller/index.dart';
import '../page_frame/index.dart';

class GichoAppShell extends StatefulWidget {
  const GichoAppShell({
    super.key,
    required this.title,
    required this.body,
    required this.locales,
    this.brand,
    this.showBrand = true,
    this.titlePrefix,
    this.onTitlePressed,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.actions = const [],
  }) : assert(
         destinations.length == 0 ||
             selectedIndex >= 0 && selectedIndex < destinations.length,
       );

  final String title;
  final Widget body;
  final GichoLocaleController locales;
  final GichoBrand? brand;
  final bool showBrand;
  final Widget? titlePrefix;
  final VoidCallback? onTitlePressed;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<Widget> actions;

  @override
  State<GichoAppShell> createState() => _GichoAppShellState();
}

class _GichoAppShellState extends State<GichoAppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _menuFocus = FocusNode();

  @override
  void dispose() {
    _menuFocus.dispose();
    super.dispose();
  }

  void _drawerChanged(bool open) {
    if (!open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _menuFocus.requestFocus();
        }
      });
    }
  }

  String _copy(String key) => widget.locales.text('gicho.navigation.$key');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.locales,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final hasNavigation = widget.destinations.isNotEmpty;
          final wide = constraints.maxWidth >= 1280 && hasNavigation;
          if (wide) {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: true,
                    minExtendedWidth: 240,
                    scrollable: true,
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                    destinations: [
                      for (final destination in widget.destinations)
                        NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                          disabled: !destination.enabled,
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: PageFrame(
                    title: Text(widget.title),
                    brand: widget.brand,
                    showBrand: widget.showBrand,
                    titlePrefix: widget.titlePrefix,
                    onTitlePressed: widget.onTitlePressed,
                    actions: widget.actions,
                    body: widget.body,
                  ),
                ),
              ],
            );
          }
          return PageFrame(
            title: Text(widget.title),
            brand: widget.brand,
            showBrand: widget.showBrand,
            titlePrefix: widget.titlePrefix,
            onTitlePressed: widget.onTitlePressed,
            leading: hasNavigation
                ? IconButton(
                    focusNode: _menuFocus,
                    tooltip: _copy('open'),
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
            actions: widget.actions,
            scaffoldKey: _scaffoldKey,
            drawer: hasNavigation ? _drawer() : null,
            onDrawerChanged: hasNavigation ? _drawerChanged : null,
            body: widget.body,
          );
        },
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(_copy('title'))),
                  IconButton(
                    tooltip: _copy('close'),
                    icon: const Icon(Icons.close),
                    onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NavigationDrawer(
                selectedIndex: widget.selectedIndex,
                onDestinationSelected: (index) {
                  _scaffoldKey.currentState?.closeDrawer();
                  widget.onDestinationSelected?.call(index);
                },
                children: [
                  for (final destination in widget.destinations)
                    NavigationDrawerDestination(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      label: Text(destination.label),
                      enabled: destination.enabled,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
