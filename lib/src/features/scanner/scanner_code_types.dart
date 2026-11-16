import 'scan_code.dart';

/// Code formats a scanner may accept. `all` lets the decoder detect any code.
class ScannerCodeTypes {
  const ScannerCodeTypes.all() : formats = null;

  const ScannerCodeTypes.qr()
    : formats = const {ScanCodeFormat.qrCode, ScanCodeFormat.microQrCode};

  const ScannerCodeTypes.barcodes()
    : formats = const {
        ScanCodeFormat.code128,
        ScanCodeFormat.code39,
        ScanCodeFormat.code93,
        ScanCodeFormat.codabar,
        ScanCodeFormat.dataMatrix,
        ScanCodeFormat.ean13,
        ScanCodeFormat.ean8,
        ScanCodeFormat.itf2of5,
        ScanCodeFormat.itf2of5WithChecksum,
        ScanCodeFormat.itf14,
        ScanCodeFormat.upcA,
        ScanCodeFormat.upcE,
        ScanCodeFormat.pdf417,
        ScanCodeFormat.aztec,
        ScanCodeFormat.maxiCode,
        ScanCodeFormat.dataBar,
        ScanCodeFormat.dataBarExpanded,
        ScanCodeFormat.dataBarLimited,
      };

  ScannerCodeTypes.only(Set<ScanCodeFormat> formats)
    : formats = Set.unmodifiable(formats) {
    if (formats.isEmpty || formats.contains(ScanCodeFormat.unknown)) {
      throw ArgumentError.value(
        formats,
        'formats',
        'Choose at least one known code format.',
      );
    }
  }

  /// Null means every decoder-supported format, including an unknown result.
  final Set<ScanCodeFormat>? formats;

  bool accepts(ScanCodeFormat format) => formats?.contains(format) ?? true;
}
