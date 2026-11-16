import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../../../authentication/authentication_delegate.dart';
import '../../../authentication/authentication_stage.dart';
import '../../../localization/components/language_selector_page.dart';
import '../../../theme/components/theme_selector_page.dart';
import '../../../theme/configured_theme.dart';
import '../../core_configuration.dart';
import '../config_display/config_display_page.dart';
import 'app_bar_action.dart';

/// Actions supplied by Gicho's standard application shell.
List<GichoAppBarAction> standardAppBarActions() => [
  GichoAppBarAction(
    id: GichoAppBarFeature.brightnessToggle,
    builder: (context) => IconButton(
      tooltip: 'Toggle light and dark mode',
      icon: Icon(
        Theme.of(context).brightness == Brightness.dark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
      onPressed: () {
        moztopiaTheme.toggleMode(Theme.of(context).brightness);
      },
    ),
  ),
  GichoAppBarAction(
    id: GichoAppBarFeature.themeSelector,
    builder: (context) => IconButton(
      tooltip: 'Choose theme',
      icon: const Icon(Icons.palette_outlined),
      onPressed: () => _openPage(context, const ThemeSelectorPage()),
    ),
  ),
  GichoAppBarAction(
    id: GichoAppBarFeature.languageSelector,
    builder: (context) => IconButton(
      tooltip: 'Choose language',
      icon: SizedBox.square(
        dimension: 40,
        child: Badge(
          alignment: Alignment.topRight,
          offset: const Offset(-8, 4),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          label: Text(context.locale.languageCode.toUpperCase()),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.translate),
          ),
        ),
      ),
      onPressed: () => _openPage(context, const LanguageSelectorPage()),
    ),
  ),
  GichoAppBarAction(
    id: GichoAppBarFeature.configurationDisplay,
    builder: (context) => IconButton(
      tooltip: 'View configuration',
      icon: const Icon(Icons.data_object),
      onPressed: () => _openPage(context, const ConfigurationDisplayPage()),
    ),
  ),
  GichoAppBarAction(
    id: GichoAppBarFeature.logout,
    isVisible: (context) =>
        AuthenticationStage.maybeOf(context)?.state ==
        AuthenticationState.authenticated,
    builder: (context) => IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout),
      onPressed: () => _confirmLogout(context),
    ),
  ),
];

Future<void> _confirmLogout(BuildContext context) async {
  final runtime = AuthenticationStage.maybeOf(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('LOGOUT'),
        ),
      ],
    ),
  );
  if (confirmed == true) await runtime?.delegate?.logout();
}

void _openPage(BuildContext context, Widget page) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => page));
}
