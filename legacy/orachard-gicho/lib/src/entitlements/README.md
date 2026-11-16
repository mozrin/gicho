> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Entitlements

Gicho entitlements is a reusable, provider-neutral store lifecycle feature.
It owns configuration validation, provider initialization, product grouping,
purchase and restore operations, identified-user transitions, entitlement
observation, stale-state handling, typed failures, Riverpod access, and
structured lifecycle logging. A consuming application owns product IDs,
presentation, authenticated account identity, and server reconciliation.

The bundled adapter uses `qonversion_flutter`. No consumer imports Qonversion
directly, and a different provider can implement `GichoEntitlementAdapter`
without changing application feature code. Client state exists for responsive
presentation only; it is never proof that a protected backend action is
authorized.

## Configuration

Gicho ships package defaults and a JSON Schema:

```text
lib/src/entitlements/entitlements.config.yaml
lib/src/entitlements/entitlements.config.schema.json
```

Applications override permitted values at:

```text
assets/gicho/entitlements.config.yaml
```

An inactive application configuration is intentionally small:

```yaml
enabled: false
provider:
  environment: sandbox
products: []
```

Activation supplies a client-facing Qonversion project key for each supported
target and stable application mappings:

```yaml
enabled: true
provider:
  environment: production
  projectKeys:
    android: public-android-project-key
    ios: public-ios-project-key
products:
  - id: application.plus.monthly
    offeringId: application.plus
    entitlementId: application.plus
    providerProductId: provider-monthly-id
    providerEntitlementId: provider-premium-id
```

Project keys used by the mobile SDK are client-facing identifiers, not server
API secrets. Qonversion management credentials, webhooks, and reconciliation
belong in the consuming backend. Vendor enrollment, terms, store products,
prices, production keys, and activation remain explicit human-owned steps.

## Product and offering model

The public models use stable application IDs. Provider product and entitlement
IDs occur only in configuration mappings. Qonversion's current Flutter SDK
deprecates its legacy offering API, so the adapter loads current store products
with `products()` and groups mapped products into provider-neutral Gicho
offerings. Product title, description, localized display price, currency, and
period remain store-supplied values.

## Bootstrap and state

Enable loading through the standard bootstrap:

```dart
GichoBootstrap(
  entitlementsEnabled: true,
  child: application,
)
```

The wrapper installs `GichoEntitlements` and starts initialization without
blocking Gicho startup or authentication. Widgets can watch
`gichoEntitlementsProvider` or read `GichoEntitlements.of(context)`.
When the feature is disabled or the current platform is unsupported, both
seams remain installed with a typed unavailable state.

Qonversion currently supports Android, iOS, and macOS. Gicho reports web,
Linux, Windows, and Fuchsia as unsupported instead of invoking a missing native
plugin. A consuming app can still build and run those targets.

## Identity and lifecycle

After application authentication produces a stable opaque account identifier,
call `identify`. On account logout or switching, call `logout` before exposing
another account's state. Do not use an access token, email address, device ID,
or temporary session ID as the Qonversion identity.

The controller supports:

- product loading and application offering groups;
- current entitlement checks and provider-pushed updates;
- purchased, cancelled, pending, and failed outcomes;
- deferred purchase updates and purchase restoration;
- periodic refresh and last-known snapshots marked stale after the configured
  interval; and
- disabled, unsupported, configuration, network, store, product, purchase,
  identity, provider, and unknown failure classes.

Logs name lifecycle operations and non-sensitive stable product IDs. Project
keys, account identifiers, receipts, tokens, and provider payloads are never
logged. Consumers should use test adapters for deterministic feature tests;
real store integration remains a platform/store test concern.
