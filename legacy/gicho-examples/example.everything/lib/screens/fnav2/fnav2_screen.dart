import 'package:flutter/material.dart';

class FNav2Screen extends StatelessWidget {
  const FNav2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 8,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text('FNav2 item ${index + 1}'),
        subtitle: const Text('An example list-oriented destination.'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
