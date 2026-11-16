import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes Logger through the Gicho public library', () {
    final output = MemoryOutput();
    final log = Logger(
      filter: ProductionFilter(),
      printer: SimplePrinter(colors: false),
      output: output,
    );

    log.i('Moztopia logging');

    expect(output.buffer, isNotEmpty);
  });
}
