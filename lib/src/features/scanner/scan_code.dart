import 'dart:typed_data';

/// One decoded code, with the unmodified string and bytes when available.
class ScanCode {
  const ScanCode({
    required this.format,
    this.rawValue,
    this.rawBytes,
    this.displayValue,
  });

  final ScanCodeFormat format;
  final String? rawValue;
  final Uint8List? rawBytes;
  final String? displayValue;
}

/// Stable code formats exposed to applications by the shared scanner.
enum ScanCodeFormat {
  unknown,
  qrCode,
  microQrCode,
  code128,
  code39,
  code93,
  codabar,
  dataMatrix,
  ean13,
  ean8,
  itf2of5,
  itf2of5WithChecksum,
  itf14,
  upcA,
  upcE,
  pdf417,
  aztec,
  maxiCode,
  dataBar,
  dataBarExpanded,
  dataBarLimited;

  bool get isQr => this == qrCode || this == microQrCode;
}
