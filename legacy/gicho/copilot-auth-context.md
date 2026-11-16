# Gicho authentication design context

## Purpose

I am designing authentication support for **Gicho**, a shared Flutter
package used by multiple consumer applications. I want help designing the
boundary between the package-owned application startup framework and each
consumer application's authentication implementation.

Do not assume that every application uses OAuth or OpenID Connect. One app may
use browser OAuth, another may use username/password, passkeys, a proprietary
API, an existing session, device credentials, or no authentication at all.
Gicho should coordinate where authentication occurs without owning one
universal authentication mechanism.

## Existing package philosophy

Gicho is the single dependency and public API entry point for shared Flutter
integrations used by Moztopia applications. Consumers use:

```dart
import 'package:moztopia/gicho.dart';
```

The package provides a simple application foundation while consumer apps keep
ownership of routes, screens, layout, application policy, API endpoints,
credentials, and business logic.

The current application root looks like this:

```dart
GichoBootstrap(
  startupEnabled: true,
  authenticationEnabled: true,
  localizationsEnabled: false,
  notificationsEnabled: true,
  child: GichoMaterialApp.router(router: appRouter),
)
```

All optional features default to `false` and must be explicitly enabled by the
consumer.

## Fixed launch order

The platform launcher icon and native launch-screen process are not managed or
changed by Gicho. After Flutter starts, the package framework must preserve
this order:

```text
┌──────────────────────────────┐
│ Platform launch icon/screen  │  Consumer/platform-owned
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Startup stage                │  Optional; package slot
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Authentication stage         │  Optional; package coordination slot
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Consumer application/router  │  Consumer-owned
└──────────────────────────────┘
```

Valid configurations include:

```text
launch -> app
launch -> authentication -> app
launch -> startup -> app
launch -> startup -> authentication -> app
```

Startup and authentication are ordered stages, not ordinary wrappers whose
relative positions may change.

## Current proof-of-concept

The startup slot currently displays a minimal page for three seconds and then
continues. It exists only to prove that the stage is present.

The Gicho authentication slot has no built-in authentication behavior or UI.
A separate `FlextensionAuthMock` currently proves the delegate contract with a
modal-style page that has no back arrow and two buttons:

- `LOGIN` continues to the consumer application.
- `EXIT` asks the platform to close the application.

This is development-only behavior in the additions repository. It is not a
Gicho default or a production authentication implementation.

The current public enable flags are:

```dart
GichoBootstrap(
  startupEnabled: false,
  authenticationEnabled: false,
  authenticationDelegate: null,
  child: app,
)
```

The package also exposes runtime availability state so descendants can tell
whether a stage was enabled.

## Example consumer-side authentication code under discussion

A possible consumer application has an `AuthController` that:

- reads and writes a token using Flutter Secure Storage;
- publishes authentication state through Riverpod;
- launches a browser authentication URL;
- listens for an application deep link;
- extracts a returned token;
- supports login and logout;
- depends on the consumer application's API client.

That code may be useful for one application, but it is not a complete generic
authentication solution. It assumes browser/OAuth-like behavior and includes
application-specific details such as:

- API paths and response envelopes;
- redirect schemes;
- token formats and storage keys;
- Riverpod providers;
- generated API clients;
- deep-link rules;
- session renewal and logout policy.

Those details should generally remain in the consumer application or in a
separate optional authentication implementation—not in the core Gicho
bootstrap.

## Desired responsibility boundary

Gicho should own orchestration, not identity policy.

```text
Gicho framework owns                 Consumer auth module owns
─────────────────────────────────────   ─────────────────────────────────────
The authentication stage position       Authentication protocol/mechanism
Whether the stage is enabled             Login and logout screens
Transition into the application         API endpoints and generated clients
Basic loading/error composition hooks   Credentials, tokens, and sessions
A small implementation contract         Secure-storage keys and token format
Predictable lifecycle/disposal           Deep links, OAuth, PKCE, or passkeys
Neutral authenticated outcome           Refresh, revocation, and expiry policy
                                        User/account state and app redirects
```

The package must not require OAuth concepts such as authorization URLs,
redirect URIs, access tokens, refresh tokens, scopes, or PKCE in its core API.
An OAuth consumer implementation may use all of those behind the neutral
boundary.

## Conceptual composition

One possible direction is for Gicho to accept a consumer-provided
authentication gate or delegate:

```dart
GichoBootstrap(
  authenticationEnabled: true,
  authentication: ConsumerAuthenticationGate(
    controller: consumerAuthController,
  ),
  child: GichoMaterialApp.router(router: appRouter),
)
```

Conceptually, the consumer gate reports only enough state for orchestration:

```text
checking ────────────────┐
                        ▼
unauthenticated -> authenticating -> authenticated -> app
       │                   │
       └──── failed <──────┘
```

The exact Dart API has not been decided. Alternatives worth comparing include:

1. A consumer-provided `Widget` or `WidgetBuilder` that calls a continuation
   when authentication is complete.
2. An `AuthenticationDelegate` interface that exposes state and operations,
   with the consumer still supplying the UI.
3. A `Listenable`, `Stream`, or Riverpod-independent state contract observed by
   a package-owned gate.
4. A route-level redirect contract integrated with `GoRouter`.
5. A minimal composition object containing an authentication-state source and
   builders for loading, unauthenticated, error, and authenticated states.

The design should avoid forcing Riverpod, OAuth, a token model, or a particular
router architecture on the consumer. Gicho happens to export Riverpod and
GoRouter, but authentication should not become unnecessarily coupled to either.

## Important questions

- What is the smallest useful contract between `GichoBootstrap` and a
  consumer-owned authentication module?
- `authenticationEnabled: true` requires a delegate supplied by a consumer or
  Flextension. Gicho retains no development placeholder.
- How should the auth module signal `checking`, `unauthenticated`,
  `authenticated`, and `failed`?
- Should authenticated state be a boolean, a sealed result, or an opaque
  consumer-defined session?
- Who owns the authentication screen and its navigation?
- How does the consumer signal that authentication completed so Gicho can
  reveal the app?
- How should logout return from the running app to the authentication stage?
- Should authentication be a widget gate outside the router, a router redirect,
  or support both patterns?
- How should startup pass information or failures into authentication without
  coupling the two implementations?
- How can the contract remain testable with an in-memory fake?
- How should lifecycle cleanup work for streams, deep links, and controllers?
- Which behaviors belong in core Gicho versus optional reusable auth
  adapters?
- How do we keep `authenticationEnabled: false` simple and ensure it adds no
  authentication UI, initialization, or runtime requirements?

## Constraints and preferences

- Preserve the fixed sequence:
  `launch -> startup (optional) -> authentication (optional) -> app`.
- Both startup and authentication default to disabled.
- Do not change the native launcher-icon process.
- Consumer applications own authentication mechanisms and policy.
- Do not assume OAuth.
- Do not require Riverpod in the neutral authentication contract unless there
  is a compelling reason.
- Do not put application routes, API paths, storage keys, or credentials into
  package configuration.
- Prefer normal Flutter composition and familiar Dart naming.
- Keep the initial implementation small enough that the partner who owns the
  eventual startup/authentication work has a clear slot to extend.
- Separate a stable core contract from optional protocol-specific adapters.
- Avoid designing an oversized authentication framework before real consumer
  implementations establish the requirements.

## Prompt for another AI

Act as a senior Flutter package/API designer. Review the complete context above
and help design a minimal, authentication-mechanism-neutral boundary between
`GichoBootstrap` and consumer-owned authentication modules.

Do not assume OAuth, OIDC, tokens, Riverpod, or a specific backend. Treat those
as possible consumer implementations. Preserve the fixed launch order and the
default-disabled behavior.

Please provide:

1. Two or three viable API designs with short Dart examples.
2. The tradeoffs of a widget gate, delegate/state contract, and router redirect.
3. Your recommended minimal MVP contract and why it leaves room for future
   implementations.
4. A state model covering initialization, unauthenticated, authentication in
   progress, authenticated, and failure without exposing protocol details.
5. How login completion, logout, retry, lifecycle disposal, and testing should
   work.
6. A clear responsibility table for Gicho versus the consumer application.
7. Pitfalls that would accidentally couple Gicho to OAuth or to one state
   management library.

Keep the recommendation intentionally small. The immediate goal is to create a
safe extension slot for a partner's future implementation, not to build a
complete authentication framework now.
