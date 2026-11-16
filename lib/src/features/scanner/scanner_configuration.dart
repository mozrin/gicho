import 'dart:async';

import 'scan_code.dart';
import 'scanner_code_types.dart';
import 'scanner_look.dart';

/// Code selection, appearance and scan callback for an embeddable viewport.
class ScannerConfiguration {
  const ScannerConfiguration({
    required this.codeTypes,
    required this.look,
    required this.onDetected,
    required this.cameraErrorMessage,
    required this.permissionDeniedMessage,
    required this.torchOnLabel,
    required this.torchOffLabel,
    this.showTorch = true,
  });

  final ScannerCodeTypes codeTypes;
  final ScannerLook look;
  final FutureOr<void> Function(ScanCode code) onDetected;
  final String cameraErrorMessage;
  final String permissionDeniedMessage;
  final String torchOnLabel;
  final String torchOffLabel;
  final bool showTorch;
}
