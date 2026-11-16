> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Flextension Auth Mock

A development-only authentication implementation for Gicho. It has no
external identity provider, credentials, tokens, or backend.

```dart
GichoBootstrap(
  authenticationEnabled: true,
  authenticationDelegate: FlextensionAuthMock(),
  child: app,
)
```

`LOGIN` immediately emits `AuthenticationState.authenticated`. `EXIT` requests
that the platform close the application. Calling `logout()` returns the state
to `AuthenticationState.unauthenticated`.
