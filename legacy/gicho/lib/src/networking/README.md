> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Networking

Gicho exposes Dio through `package:moztopia/gicho.dart`.

```dart
final client = Dio(
  BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
  ),
);

final response = await client.get<Map<String, Object?>>('/status');
```

Use it directly for HTTP requests, interceptors, cancellation, uploads,
downloads, timeouts, adapters, and response transformation. Configure clients
inside the consuming application so authentication and environment policy stay
application-owned.

Barrel files are utility-generated and must not be edited manually.

## Configuration reference

Networking currently has no Gicho YAML parameters and no
`networking.config.yaml`. Base URLs, timeouts, headers, authentication,
interceptors, adapters, and retry policy remain application-owned. Adding
`assets/gicho/networking.config.yaml` has no effect.
