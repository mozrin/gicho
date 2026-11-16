import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scan_code.dart';
import 'scanner_code_types.dart';
import 'scanner_configuration.dart';
import 'scanner_look.dart';

/// Embeddable square camera viewport for QR and barcode codes.
class GichoScanner extends StatefulWidget {
  const GichoScanner({super.key, required this.configuration});

  final ScannerConfiguration configuration;

  @override
  State<GichoScanner> createState() => _GichoScannerState();
}

class _GichoScannerState extends State<GichoScanner>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _camera = MobileScannerController(
    formats: _cameraFormats(widget.configuration.codeTypes),
  );
  late final AnimationController _scanLine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
    value: 0.5,
  );
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scanLine.stop();
      _scanLine.value = 0.5;
    } else if (!_scanLine.isAnimating) {
      _scanLine.repeat(reverse: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_camera.value.hasCameraPermission) {
        unawaited(_camera.start());
      }
      if (!MediaQuery.disableAnimationsOf(context)) {
        _scanLine.repeat(reverse: true);
      }
    } else {
      unawaited(_camera.stop());
      _scanLine.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLine.dispose();
    _camera.dispose();
    super.dispose();
  }

  Future<void> _detect(BarcodeCapture capture) async {
    if (_busy) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final format = _scanCodeFormat(barcode.format);
      if (!widget.configuration.codeTypes.accepts(format)) {
        continue;
      }
      final bytes = switch (barcode.rawDecodedBytes) {
        DecodedBarcodeBytes(:final bytes) => bytes,
        DecodedVisionBarcodeBytes(:final bytes) => bytes,
        _ => null,
      };
      if ((barcode.rawValue == null || barcode.rawValue!.isEmpty) &&
          (bytes == null || bytes.isEmpty)) {
        continue;
      }
      _busy = true;
      try {
        await widget.configuration.onDetected(
          ScanCode(
            format: format,
            rawValue: barcode.rawValue,
            rawBytes: bytes == null ? null : Uint8List.fromList(bytes),
            displayValue: barcode.displayValue,
          ),
        );
      } finally {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        _busy = false;
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final configuration = widget.configuration;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _camera,
              onDetect: _detect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? configuration.permissionDeniedMessage
                        : configuration.cameraErrorMessage,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          if (configuration.look == ScannerLook.cylonSquare)
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ListenableBuilder(
                    listenable: _camera,
                    builder: (context, _) => _camera.value.isRunning
                        ? AnimatedBuilder(
                            animation: _scanLine,
                            builder: (context, _) => Align(
                              alignment: Alignment(
                                0,
                                -0.8 + _scanLine.value * 1.6,
                              ),
                              child: FractionallySizedBox(
                                widthFactor: 0.76,
                                child: const SizedBox(
                                  height: 2,
                                  child: ColoredBox(color: Colors.redAccent),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          if (configuration.showTorch)
            Positioned(
              top: 8,
              right: 8,
              child: ListenableBuilder(
                listenable: _camera,
                builder: (context, _) {
                  final state = _camera.value.torchState;
                  if (state == TorchState.unavailable) {
                    return const SizedBox.shrink();
                  }
                  final enabled = state == TorchState.on;
                  return IconButton.filledTonal(
                    tooltip: enabled
                        ? configuration.torchOffLabel
                        : configuration.torchOnLabel,
                    icon: Icon(enabled ? Icons.flash_off : Icons.flash_on),
                    onPressed: () async {
                      await _camera.toggleTorch();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

List<BarcodeFormat> _cameraFormats(ScannerCodeTypes codeTypes) {
  final selected = codeTypes.formats;
  if (selected == null) {
    return const [];
  }
  return [for (final format in selected) _barcodeFormat(format)];
}

BarcodeFormat _barcodeFormat(ScanCodeFormat format) => switch (format) {
  ScanCodeFormat.unknown => BarcodeFormat.unknown,
  ScanCodeFormat.qrCode => BarcodeFormat.qrCode,
  ScanCodeFormat.microQrCode => BarcodeFormat.microQrCode,
  ScanCodeFormat.code128 => BarcodeFormat.code128,
  ScanCodeFormat.code39 => BarcodeFormat.code39,
  ScanCodeFormat.code93 => BarcodeFormat.code93,
  ScanCodeFormat.codabar => BarcodeFormat.codabar,
  ScanCodeFormat.dataMatrix => BarcodeFormat.dataMatrix,
  ScanCodeFormat.ean13 => BarcodeFormat.ean13,
  ScanCodeFormat.ean8 => BarcodeFormat.ean8,
  ScanCodeFormat.itf2of5 => BarcodeFormat.itf2of5,
  ScanCodeFormat.itf2of5WithChecksum => BarcodeFormat.itf2of5WithChecksum,
  ScanCodeFormat.itf14 => BarcodeFormat.itf14,
  ScanCodeFormat.upcA => BarcodeFormat.upcA,
  ScanCodeFormat.upcE => BarcodeFormat.upcE,
  ScanCodeFormat.pdf417 => BarcodeFormat.pdf417,
  ScanCodeFormat.aztec => BarcodeFormat.aztec,
  ScanCodeFormat.maxiCode => BarcodeFormat.maxiCode,
  ScanCodeFormat.dataBar => BarcodeFormat.dataBar,
  ScanCodeFormat.dataBarExpanded => BarcodeFormat.dataBarExpanded,
  ScanCodeFormat.dataBarLimited => BarcodeFormat.dataBarLimited,
};

ScanCodeFormat _scanCodeFormat(BarcodeFormat format) => switch (format) {
  BarcodeFormat.qrCode => ScanCodeFormat.qrCode,
  BarcodeFormat.microQrCode => ScanCodeFormat.microQrCode,
  BarcodeFormat.code128 => ScanCodeFormat.code128,
  BarcodeFormat.code39 => ScanCodeFormat.code39,
  BarcodeFormat.code93 => ScanCodeFormat.code93,
  BarcodeFormat.codabar => ScanCodeFormat.codabar,
  BarcodeFormat.dataMatrix => ScanCodeFormat.dataMatrix,
  BarcodeFormat.ean13 => ScanCodeFormat.ean13,
  BarcodeFormat.ean8 => ScanCodeFormat.ean8,
  BarcodeFormat.itf2of5 => ScanCodeFormat.itf2of5,
  BarcodeFormat.itf2of5WithChecksum => ScanCodeFormat.itf2of5WithChecksum,
  BarcodeFormat.itf14 => ScanCodeFormat.itf14,
  BarcodeFormat.upcA => ScanCodeFormat.upcA,
  BarcodeFormat.upcE => ScanCodeFormat.upcE,
  BarcodeFormat.pdf417 => ScanCodeFormat.pdf417,
  BarcodeFormat.aztec => ScanCodeFormat.aztec,
  BarcodeFormat.maxiCode => ScanCodeFormat.maxiCode,
  BarcodeFormat.dataBar => ScanCodeFormat.dataBar,
  BarcodeFormat.dataBarExpanded => ScanCodeFormat.dataBarExpanded,
  BarcodeFormat.dataBarLimited => ScanCodeFormat.dataBarLimited,
  BarcodeFormat.unknown || BarcodeFormat.all => ScanCodeFormat.unknown,
  _ => ScanCodeFormat.unknown,
};
