import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

import 'app_drawer.dart';
import 'destination.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) {
    moztopiaLog.info(
      'Primary navigation selected: ${destinations[index].label}',
    );
    if (destinations[index].path == '/config') {
      moztopiaLog.debug('Config navigation selected');
      moztopiaLog.debug('Configured debug color test');
    }
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final selected = destinations[shell.currentIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 840;

        return GichoPageShell(
          appBar: GichoAppBar(
            title: Text(selected.label),
            actionOverrides: {
              // Language is globally hidden but available on FNav1.
              if (selected.path == '/fnav1')
                GichoAppBarFeature.languageSelector: true,
              // Configuration display is global except on focused FNav2.
              if (selected.path == '/fnav2')
                GichoAppBarFeature.configurationDisplay: false,
            },
          ),
          drawer: const AppDrawer(),
          body: Row(
            children: [
              if (useRail) ...[
                NavigationRail(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: shell),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
