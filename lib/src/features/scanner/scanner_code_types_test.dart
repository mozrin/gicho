// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'scan_code.dart';
import 'scanner_code_types.dart';

void main() {
  test('all, family and exact selections cover different code scopes', () {
    expect(const ScannerCodeTypes.all().accepts(ScanCodeFormat.aztec), isTrue);
    expect(
      const ScannerCodeTypes.qr().accepts(ScanCodeFormat.microQrCode),
      isTrue,
    );
    expect(const ScannerCodeTypes.qr().accepts(ScanCodeFormat.ean13), isFalse);
    expect(
      const ScannerCodeTypes.barcodes().accepts(ScanCodeFormat.ean13),
      isTrue,
    );
    expect(
      const ScannerCodeTypes.barcodes().accepts(ScanCodeFormat.qrCode),
      isFalse,
    );
    final exact = ScannerCodeTypes.only({
      ScanCodeFormat.qrCode,
      ScanCodeFormat.code128,
    });
    expect(exact.accepts(ScanCodeFormat.qrCode), isTrue);
    expect(exact.accepts(ScanCodeFormat.code128), isTrue);
    expect(exact.accepts(ScanCodeFormat.microQrCode), isFalse);
    expect(() => ScannerCodeTypes.only({}), throwsArgumentError);
  });
}
