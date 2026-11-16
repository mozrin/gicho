import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

class LoggingExamplesScreen extends StatefulWidget {
  const LoggingExamplesScreen({super.key});

  @override
  State<LoggingExamplesScreen> createState() => _LoggingExamplesScreenState();
}

class _LoggingExamplesScreenState extends State<LoggingExamplesScreen> {
  var _batch = 0;

  void _logAllLevels() {
    final batch = ++_batch;
    moztopiaLog.trace('Trace event from batch $batch');
    moztopiaLog.debug('Debug state', time: DateTime.now());
    moztopiaLog.info('User generated logging batch $batch');
    moztopiaLog.warn('Example warning: no action is required');
    moztopiaLog.error(
      'Example recoverable error',
      error: StateError('Synthetic error for batch $batch'),
      stackTrace: StackTrace.current,
    );
    moztopiaLog.fatal('Example fatal event (demonstration only)');
    setState(() {});
  }

  void _logStructuredData() {
    moztopiaLog.info({
      'event': 'example_action',
      'destination': 'Logging',
      'authenticated': false,
      'items': [1, 2, 3],
      'occurredAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return GichoPageShell(
      appBar: GichoAppBar(
        leading: BackButton(onPressed: context.pop),
        title: const Text('Logging'),
        showStandardActions: false,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Logger showcase',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'These controls write through the Logger API exported by '
                'Gicho. Watch the debug console to inspect the output.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _logAllLevels,
                    icon: const Icon(Icons.dynamic_feed_outlined),
                    label: const Text('Log every level'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _logStructuredData,
                    icon: const Icon(Icons.data_object),
                    label: const Text('Log structured data'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Generated batches'),
                  trailing: Text('$_batch'),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Production applications should redact secrets and '
                    'personal data before sending events to any output.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
