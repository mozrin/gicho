import 'package:material_ui/material_ui.dart';

/// An optional page-level composition helper built from ordinary Flutter
/// scaffold regions.
///
/// Only [body] is required. Omitting a region means that region is not shown.
final class GichoPageShell extends StatelessWidget {
  const GichoPageShell({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    drawer: drawer,
    endDrawer: endDrawer,
    body: body,
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
    floatingActionButtonLocation: floatingActionButtonLocation,
    backgroundColor: backgroundColor,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    extendBody: extendBody,
    extendBodyBehindAppBar: extendBodyBehindAppBar,
  );
}
