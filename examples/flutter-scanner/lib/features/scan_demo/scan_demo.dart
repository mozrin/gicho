import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _employeeCode = 'EMP:DEMO-123';
const _menuCode = 'https://example.org/menu/demo';

/// Consumer-owned navigation and interpretation for two unrelated QR uses.
class ScanDemo extends StatefulWidget {
  const ScanDemo({super.key, required this.locales});

  final GichoLocaleController locales;

  @override
  State<ScanDemo> createState() => _ScanDemoState();
}

class _ScanDemoState extends State<ScanDemo> {
  String? _result;

  Future<void> _scan({required bool employee, bool product = false}) async {
    final text = widget.locales.text;
    final feedback = ValueNotifier<String?>(null);
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (routeContext) => GichoModalPage(
          title: text(
            product
                ? 'app.product'
                : employee
                ? 'app.employee'
                : 'app.menu',
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: ValueListenableBuilder<String?>(
                  valueListenable: feedback,
                  builder: (context, message, _) => Text(
                    message ??
                        text(
                          product
                              ? 'app.product.instruction'
                              : employee
                              ? 'app.employee.instruction'
                              : 'app.menu.instruction',
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: GichoScanner(
                      configuration: ScannerConfiguration(
                        codeTypes: product
                            ? const ScannerCodeTypes.barcodes()
                            : const ScannerCodeTypes.qr(),
                        look: ScannerLook.cylonSquare,
                        cameraErrorMessage: text('app.camera.error'),
                        permissionDeniedMessage: text('app.camera.permission'),
                        torchOnLabel: text('app.torch.on'),
                        torchOffLabel: text('app.torch.off'),
                        onDetected: (code) {
                          final raw = code.rawValue;
                          if (product) {
                            Navigator.of(routeContext).pop(
                              '${code.format.name}: ${raw ?? '[binary code]'}',
                            );
                            return;
                          }
                          if (raw != null &&
                              employee &&
                              raw.startsWith('EMP:')) {
                            Navigator.of(routeContext).pop(raw);
                            return;
                          }
                          final uri = raw == null ? null : Uri.tryParse(raw);
                          if (!employee &&
                              uri?.host == 'example.org' &&
                              uri?.pathSegments.firstOrNull == 'menu') {
                            Navigator.of(routeContext).pop(raw);
                            return;
                          }
                          feedback.value = text(
                            employee
                                ? 'app.employee.invalid'
                                : 'app.menu.invalid',
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    feedback.dispose();
    if (mounted && result != null) {
      setState(() => _result = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.locales.text;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(text('app.intro')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _scan(employee: true),
              child: Text(text('app.employee')),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _scan(employee: false),
              child: Text(text('app.menu')),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _scan(employee: false, product: true),
              child: Text(text('app.product')),
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              Text(text('app.result')),
              SelectableText(_result!),
            ],
            const SizedBox(height: 24),
            ExpansionTile(
              title: Text(text('app.samples')),
              children: [
                _SampleQr(
                  label: text('app.sample.employee'),
                  value: _employeeCode,
                ),
                _SampleQr(label: text('app.sample.menu'), value: _menuCode),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleQr extends StatelessWidget {
  const _SampleQr({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(label),
        const SizedBox(height: 8),
        QrImageView(data: value, size: 180, semanticsLabel: '$label: $value'),
        SelectableText(value),
      ],
    ),
  );
}
