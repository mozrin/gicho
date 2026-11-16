# Package linkage

Use the public `moztopia/gicho` library in compile-time smoke tests to verify
that the package is linked correctly. Gicho does not expose a `ping()` API.

## Usage

```dart
import 'package:moztopia/gicho.dart';

final client = Dio();
```

If another dependency exposes the same symbols, use an import prefix:

```dart
import 'package:moztopia/gicho.dart' as gicho;

final client = gicho.Dio();
```

## When to use it

Use a small compile-time check in examples, smoke tests, and setup diagnostics.
Constructing a client does not perform a network request or verify external
services.
