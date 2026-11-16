> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Authentication

Gicho authentication is a reusable, configuration-driven presentation
feature. Gicho owns the login pages, provider placement, disabled states,
localized copy, accessibility semantics, and secondary-provider navigation.
The consuming application owns its authentication protocol, server SDK,
session lifecycle, and brand through `AuthenticationDelegate`.

Authentication never handles provider account recovery. A member signs in,
recovers an account, or resolves provider-specific problems entirely inside
the provider's redirected interface.

## Configuration files

Gicho ships the defaults and schema:

```text
lib/src/authentication/authentication.config.yaml
lib/src/authentication/authentication.config.schema.json
```

A consuming app may replace presentation values with:

```text
assets/gicho/authentication.config.yaml
```

The standard Gicho configuration service validates package and app YAML
against the package-owned JSON Schema, then merges them. Provider lists replace
as a complete list; they are not appended. Google must occur exactly once in
every supplied provider list and therefore cannot be omitted. Unknown fields,
invalid slugs, non-boolean state values, and placements other than `primary`
or `secondary` are rejected.

## Provider entries

```yaml
providers:
  - slug: google
    label: orchard.auth.providers.google
    placement: primary
    enabled: true
  - slug: github
    label: orchard.auth.providers.github
    placement: secondary
    enabled: false
```

- Omit a provider to keep it out of the app.
- `enabled: false` keeps the provider visible but inactive.
- `placement: primary` shows it on the main login page.
- `placement: secondary` shows it on the full modal page opened by
  `More Login Providers…`.
- The secondary-page button is absent when no secondary providers are
  configured.

Provider slugs use lowercase letters, digits, and hyphens. Gicho does not
hard-code a closed provider enum: an application can configure adapters from
the Social / Platform catalogue at <https://socialiteproviders.com/about/>,
including Apple, Facebook, Instagram, GitHub, and X/Twitter. The Laravel app
must install and register the matching SocialiteProviders adapter.

## Server reconciliation

After the consumer delegate initializes, Gicho calls
`AuthenticationDelegate.getProviders()`. The consumer obtains that set through
its generated backend SDK. Every configured provider missing from the server
set is rendered inactive, and Gicho emits a WARN naming the missing slug.
Configuration controls presentation; the server remains authoritative for
runtime availability.

For Orchard, the accepted routes are:

```text
GET /api/auth/providers
GET /api/auth/{provider-slug}
GET /api/auth/{provider-slug}/callback
```

The callback is registered with the provider and is not a client SDK action.
Gicho never constructs these routes or reads provider credentials.

## Bootstrap and delegate

Enable the gate through the existing bootstrap switch and supply the consumer
adapter:

```dart
GichoBootstrap(
  authenticationEnabled: true,
  authenticationDelegate: MyAuthenticationDelegate(),
  child: GichoMaterialApp.router(router: router),
)
```

When enabled, bootstrap loads `moztopiaAuthentication` through the shared
configuration registry and installs `AuthenticationStage`. The delegate must:

- restore and publish `AuthenticationState`;
- publish protocol-neutral `AuthenticationViewState` phase/failure changes;
- return server-configured provider slugs;
- start, retry, and cancel provider authentication;
- build the consuming application's compact brand widget;
- end the current session; and
- release its own resources.

The application adapts its generated SDK through `GichoOAuthAdapter`.
Gicho owns PKCE creation, secure pending-attempt storage, external-browser
launch, registered callbacks, and ephemeral desktop loopback callbacks. It
owns no application endpoint, provider credential, token model, or backend
client, and it never polls an application server for OAuth completion.

## Localization

Every visible string is resolved through a localization key from the `copy`
map or a provider's `label`. The consuming app must supply those keys for every
maintained language. Phase and failure strings receive a named `{provider}`
argument. Disabled provider controls expose the localized reason through
tooltip and accessibility hint semantics.

## Navigation and extension points

Secondary providers open as a full modal page with a standard back button.
Authentication does not use bottom sheets, stacked dialogs, snackbar-only
destinations, embedded provider webviews, or provider recovery pages.

Adding a provider requires four deliberate changes: install/register the
SocialiteProviders adapter in Laravel, expose the slug from the server provider
list, add a validated provider entry to app configuration, and add localized
labels. Provider policy remains in the consumer; the reusable Gicho
protocol and UI do not change.
