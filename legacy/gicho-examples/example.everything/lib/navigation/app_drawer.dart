import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

import 'secondary_destination.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: CircleAvatar(child: Icon(Icons.flutter_dash)),
              title: Text('Moztopia'),
              subtitle: Text('Example navigation'),
            ),
            const Divider(),
            for (final (index, destination)
                in secondaryDestinations.indexed) ...[
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.label),
                onTap: () {
                  moztopiaLog.info(
                    'Drawer navigation selected: ${destination.label}',
                  );
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push(destination.path);
                },
              ),
              if (index == 1 || index == 3)
                const Divider(indent: 16, endIndent: 16),
            ],
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Primary destinations are in the navigation bar.'),
            ),
          ],
        ),
      ),
    );
  }
}
