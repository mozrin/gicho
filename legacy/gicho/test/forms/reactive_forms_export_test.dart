import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes Reactive Forms through the Gicho public library', () {
    final control = FormControl<String>(validators: [Validators.required]);

    expect(control, isA<AbstractControl<String>>());
  });
}
