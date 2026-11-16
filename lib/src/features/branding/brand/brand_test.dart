// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'brand.dart';

void main() {
  test('reads the resolved generic brand', () {
    final brand = GichoBrand.fromConfiguration({
      'brand': {
        'name': 'Example',
        'logoAsset': 'assets/full.png',
        'markAsset': 'assets/mark.png',
      },
    });

    expect(brand.name, 'Example');
    expect(brand.logoAsset, 'assets/full.png');
    expect(brand.markAsset, 'assets/mark.png');
  });
}
