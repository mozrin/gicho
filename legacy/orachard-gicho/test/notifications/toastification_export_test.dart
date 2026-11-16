import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes Toastification through the Gicho public library', () {
    const wrapper = ToastificationWrapper(child: SizedBox());

    expect(wrapper, isA<ToastificationWrapper>());
  });
}
