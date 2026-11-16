import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('compact logging is a colored timestamped severity line', () {
    final printer = CompactLogPrinter(levelColors: {});
    final output = printer.log(
      LogEvent(
        Level.warning,
        'Connection is slow',
        time: DateTime(2026, 8, 10, 12, 30, 41, 120),
      ),
    );

    expect(output, ['12:30:41.120 [WARN] Connection is slow']);
  });

  test('compact logging flattens errors and stack traces', () {
    final printer = CompactLogPrinter(levelColors: {});
    final output = printer.log(
      LogEvent(
        Level.error,
        'Request\nfailed',
        time: DateTime(2026, 8, 10, 12, 30, 42, 310),
        error: 'bad\nresponse',
        stackTrace: StackTrace.fromString('first\nsecond'),
      ),
    );

    expect(output, [
      '12:30:42.310 [ERROR] Request ↵ failed error: bad ↵ response stack: first ↵ second',
    ]);
  });

  test('approved logging colors map to ANSI colors', () {
    expect(loggingAnsiColor('blue').fg, 12);
    expect(loggingAnsiColor('red').fg, 196);
    expect(loggingAnsiColor('yellow').fg, 226);
    expect(loggingAnsiColor('green').fg, 46);
    expect(loggingAnsiColor('purple').fg, 129);
  });

  test('unapproved logging colors cannot be converted', () {
    expect(() => loggingAnsiColor('cat'), throwsArgumentError);
  });
}
