# Tomorrow: configuration sync, startup engine, and generated API clients

> [!CAUTION]
> Historical planning scratchpad — not an active Orchard backlog
>
> Preserve for traceability only. Project 10 issues, native dependencies, and
> accepted baselines supersede this TODO.

## When I get back from lunch

## Goal

Design a server-driven configuration and resource synchronization system, the
startup engine that stages it before application or authentication flows, and
an endpoint workflow where a developer can add an OpenAPI YAML document, run
one documented command, and consume a typed client through Gicho.

Do not implement a generator or commit to a directory layout until the options
below have been evaluated.

## Configuration and resource sync (`config/`)

`config/` is a server-integrated synchronization tool, not only a collection of
environment constants. It retrieves configuration and resource manifests
through the networking layer, compares them with local state, and decides
whether to retrieve, add, replace, merge, remove, retain, or defer resources.

Design requirements:

- Define a dated manifest and operation schema.
- Support explicit operations such as `add`, `replace`, `merge`, `remove`,
  `retain`, `skip`, `expire`, and `activate`.
- Allow the server to indicate that the client is current so downloads are
  skipped.
- Compare approved modification dates, hashes, size, locale, platform,
  application version,
  audience, activation time, and expiration time before downloading.
- Download through the shared networking layer with cancellation, retry,
  progress, authentication, checksums, and safe logging.
- Stage downloads before activation; never overwrite the last known-good copy
  with a partial, invalid, or incompatible resource.
- Apply a manifest atomically and roll back when validation or activation
  fails.
- Define conflict and ordering rules for batched operations.
- Separate ordinary configuration, localization catalogs, images, documents,
  and other resource types while using one synchronization protocol.
- Store manifests and non-secret resources in ordinary application storage;
  keep credentials and sensitive configuration in secure storage.
- Enforce quotas, cleanup expired resources, and protect against unbounded
  downloads.
- Keep schemas forward-compatible so unknown optional fields or operations do
  not break older clients.
- Expose typed status, progress, results, and failure reasons to `startup/` and
  background execution.
- Keep all components injectable for deterministic offline tests.

### Per-resource modification check

Every independently updateable resource needs a stable ID and locally stored
modification metadata. For example, the bundled or cached English catalog may
be:

```text
id: localization.en
path: assets/gicho/en.json
updatedAt: 2026-08-09T12:30:00Z
sha256: "..."
```

The client points the configuration engine at a resource endpoint and asks only
whether its known copy is current. The preferred HTTP flow is conditional:

```http
GET /resources/localization.en
If-Modified-Since: Sun, 09 Aug 2026 12:30:00 GMT
```

- `304 Not Modified`: stop immediately and use the local copy; do not download
  or parse another catalog.
- `200 OK`: the response has a later approved `Last-Modified` date or its
  download descriptor; download only when the server file is newer and
  compatible.
- Offline, timeout, or recoverable server failure: use the last known-good local
  copy and allow startup according to policy.
- Invalid date, hash, signature, schema, or content: reject the candidate and
  preserve the last known-good copy.

If the endpoint uses a manifest request instead, send the approved modification
dates of all known resources in one compact request and return only changed
resource descriptors. Avoid one network round trip per language or asset when
a batch modification check is available.

For `en.json`, the engine must:

1. load the bundled or cached catalog immediately;
2. report its approved modification date to the endpoint;
3. do nothing further when the server copy has not changed;
4. stage and validate a later catalog when available;
5. atomically activate it and persist its `Last-Modified` date and integrity
   metadata;
6. keep displaying the old catalog, or translation keys if none exists, on any
   failure.

Modification dates are server/repository authority values, always normalized to
UTC. Do not use the phone clock or download time to decide freshness. An ETag
may also be retained as an optional conditional-request optimization, but a
resource version number is not required.

### Dynamic language registry and catalogs

Languages must not be compiled into a fixed Dart `List<Locale>`. Localization
uses two independently dated JSON resource levels:

1. a core language registry JSON describing every language available to the
   application;
2. one translation catalog JSON per language.

Conceptual local layout:

```text
application support storage/
  localization/
    languages.json
    catalogs/
      en.json
      th.json
      es.json
```

Conceptual registry:

```json
{
  "schemaVersion": 1,
  "updatedAt": "2026-08-09T12:30:00Z",
  "languages": [
    {
      "locale": "en",
      "name": "English",
      "nativeName": "English",
      "catalogUpdatedAt": "2026-08-09T12:00:00Z",
      "enabled": true
    },
    {
      "locale": "th",
      "name": "Thai",
      "nativeName": "ไทย",
      "catalogUpdatedAt": "2026-08-08T16:45:00Z",
      "enabled": true
    }
  ]
}
```

The schema is conceptual and may also need direction, fallback locale,
catalog hash/ETag, minimum application version, activation window, and catalog
URL or resource ID.

Required behavior:

- Ship a bundled registry and several baseline catalogs for reliable first
  launch and offline recovery. New application releases may contain corrected
  and expanded copies of those same resources.
- Record the repository-approved UTC modification date in the bundled registry
  for every bundled catalog. Packaged asset filesystem timestamps are not a
  portable source of truth.
- On every application start, reconcile bundled and app-storage dates before
  contacting the server so a stale downloaded override cannot shadow a newer
  catalog shipped with an application update.
- During startup, reconcile bundled and validated stored registries before
  constructing the localization provider and language selector.
- Check the active registry modification date against the server and skip
  retrieval when it is current.
- When later, download, validate, and atomically store the new registry in
  application support storage together with its server modification metadata.
- Derive `supportedLocales` and language-selection UI dynamically from the
  active registry.
- Check and retrieve each required catalog independently, storing later
  catalogs in application support storage rather than the compiled asset
  bundle.
- Permit a newly listed language and its catalog to become available without an
  application build or store release.
- Download the selected language first; stage other languages according to
  startup/background policy instead of blocking on every catalog.
- Never advertise a language as usable until its catalog is present and valid,
  unless the UI deliberately marks it as downloadable.
- Preserve the previous registry and catalogs if any replacement fails.
- Fall back from the newest valid bundled/stored catalog to the other valid
  local catalog and finally to visible translation keys.
- Retain approved modification date, optional ETag, hash, download time,
  activation time, and validation status for every stored registry and catalog.
- Remove disabled or expired language resources only after the active registry
  commits successfully.

The localization asset loader must resolve the active catalog selected by the
bundle/storage reconciliation step, rather than blindly preferring app
storage. The registry loader and catalog loader remain replaceable so the
endpoint, cache, and storage implementation can evolve without changing screens
or `translate(key)` calls.

### Community translation workflow

Translation catalogs should live in a public repository so contributors can
add languages and improve existing translations with ordinary pull requests.

Proposed flow:

1. A contributor edits an existing locale JSON or adds a catalog and registry
   entry for a new locale.
2. CI validates JSON syntax, schema, allowed locale identifiers, required keys,
   placeholder compatibility, plural forms, and file size.
3. Reviewers approve language content and resolve missing or unsafe values.
4. The merge/publishing workflow assigns the authoritative UTC modification
   date, hashes the approved content, and publishes the registry/catalog.
5. Applications discover the later date during their next resource check and
   retrieve only the approved changed files.

Do not trust contributor filesystem dates, commit author dates, or client
device clocks. The authoritative `updatedAt`/`Last-Modified` value is assigned
by the approved merge or publishing service. Content changes must always
produce a later date; metadata-only rebuilds should not force downloads.

Repository contribution documentation should include:

- catalog naming and locale-code conventions;
- how to add a language to the core registry;
- translation-key and placeholder rules;
- how fallback languages work;
- automated validation commands;
- review and approval expectations;
- licensing and contributor terms for submitted translations.

### Bundle, app-storage, and server precedence

The active resource is chosen by approved modification date and validity, not
by a fixed rule that app storage always overrides bundled assets:

1. Read the bundled registry and the validated app-storage registry.
2. For each resource, choose the later compatible valid file.
3. If the new application bundle is later than the stored copy, use the bundled
   resource and remove or supersede the stale stored override.
4. If the stored copy is later, retain it across application upgrades.
5. Ask the server about the chosen active modification date.
6. Store and activate a server resource only when the response is later and
   valid.

For example:

```text
installed app v1: bundled en.json updated 2026-06-01
downloaded fix:   stored en.json updated 2026-06-12 -> use stored file
installed app v2: bundled en.json updated 2026-07-15 -> use bundled file
server response:  en.json updated 2026-07-20        -> store and use it
```

Approved repository/server modification dates provide the ordering contract.
They must never move backward for an approved resource update. ETags remain
useful for conditional HTTP requests but are opaque and optional.

Potential manifest concepts to evaluate:

```yaml
schema: 1
updatedAt: 2026-12-01T03:00:00Z
resources:
  - id: holiday.home.hero
    type: image
    operation: replace
    updatedAt: 2026-12-01T02:45:00Z
    url: https://example.invalid/resources/holiday-home.webp
    sha256: "..."
    activateAt: 2026-12-20T00:00:00Z
    expiresAt: 2026-12-27T00:00:00Z
```

The example is conceptual. Final field names and supported operations must be
designed and documented before implementation.

## Startup engine (`startup/`)

`startup/` runs after the native launch/splash phase and before the application,
authentication, or another product-specific entry flow is released. It is a
background-capable loading and orchestration engine, not a single loading
screen.

Responsibilities:

- Execute a configurable dependency-ordered startup pipeline.
- Load the last known-good local configuration immediately.
- Decide which tasks block entry and which may continue in the background.
- Invoke `config/` to check manifests, synchronize required resources, and
  stage optional future resources.
- Preload holiday graphics, campaigns, translations, or other time-sensitive
  assets ahead of their activation windows.
- Resume interrupted downloads and avoid downloading unchanged content.
- Support online, offline, degraded, retrying, cancelled, complete, and fatal
  startup states.
- Emit progress suitable for a branded loading screen without coupling the
  engine to one UI.
- Apply strict time budgets so an unavailable server cannot trap users at
  startup.
- Route to application, authentication, maintenance, upgrade-required, or
  recoverable-error flows based on typed outcomes.
- Record structured timings and failures through logging.
- Allow startup tasks to be registered by applications without modifying the
  engine.
- Expose a background refresh entry point for supported platforms after the
  initial application launch.

The engine must distinguish:

- **required now:** blocks entry until available or a defined failure policy is
  reached;
- **use cached:** permits entry using the last known-good local resource;
- **stage for later:** downloads in advance but does not activate yet;
- **background optional:** never delays application entry.

Do not make the native splash screen perform networking. Native launch should
remain fast; Flutter-owned startup UI and orchestration begin immediately after
it.

## Base application configuration

- Define what belongs to organization-wide configuration versus an individual
  application.
- Provide typed bootstrap values such as environment, manifest endpoint,
  timeouts, and trust policy.
- Keep secrets out of source-controlled configuration and generated clients.
- Decide how compile-time values, runtime values, local development overrides,
  server-managed values, and test overrides are layered.
- Keep the bootstrap configuration small: it must contain only what is needed
  to locate and validate server-managed configuration.
- Make invalid or incomplete bootstrap configuration fail with useful
  diagnostics.
- Determine whether Riverpod exposes engine state to UI or the core remains
  framework-neutral with an optional Riverpod adapter.

## Networking connector

- Build on the Dio API already exposed by Gicho.
- Establish shared behavior for base URLs, timeouts, headers, authentication,
  retries, cancellation, serialization errors, and safe request logging.
- Keep authentication and environment policy injectable and application-owned.
- Define a consistent error model without hiding useful Dio or generated-client
  details.
- Support multiple backend services without relying on a single global client.
- Make generated clients easy to replace with fakes in tests.

## OpenAPI workflow

Desired developer experience:

1. Add or update an OpenAPI YAML file.
2. Run one repository command.
3. Receive a formatted, analyzable Dart package with a typed API client.
4. Import that generated package or a deliberate Gicho public entry point.
5. Regenerate deterministically when the specification changes.

Evaluate:

- actively maintained generators and their Dart/Flutter and Dio support;
- OpenAPI 3.x coverage, nullable models, enums, unions, uploads, downloads,
  authentication, and date/time handling;
- deterministic output and generator-version management;
- whether generated output should be committed;
- how specification changes and generated diffs are reviewed;
- custom templates versus a thin handwritten adapter around generated code;
- generation in local development and CI;
- compatibility with package analysis, tests, and release workflows.

## Generated package placement

Prefer treating generated clients as separate packages instead of mixing large
generated files into `lib/src/networking/`. A candidate layout to evaluate is:

```text
openapi/
  specifications/
    service_name.yaml
  generator/
    configuration files
packages/
  service_name_api/
    lib/
    test/
    pubspec.yaml
```

This would give generated code an explicit lifecycle, dependencies, tests, and
version boundary while keeping the handwritten Gicho package small. Confirm
whether these packages should be workspace members, private path dependencies,
or independently versioned packages.

Generated files must be clearly labeled and must not be processed as ordinary
handwritten barrel files. Existing files labeled
`// Created with barrel workflow utility.` remain owned exclusively by that
utility.

## Lower-priority audits

### Right-to-left localization and layout

Flutter and Easy Localization currently switch the example to RTL automatically
for languages such as Arabic. Before treating RTL support as production-ready,
perform a deliberate audit covering:

- back, forward, chevron, and other directional icons;
- `start`/`end` alignment and padding instead of hard-coded `left`/`right`;
- app-bar actions, locale badges, drawers, modal transitions, and navigation
  rails;
- mixed RTL/LTR language names, ISO codes, search input, and punctuation;
- clipping, truncation, text alignment, and long localized strings;
- phone, tablet, desktop, and web layouts in both directions;
- widget and golden tests for at least Arabic plus one LTR locale.

Document any intentionally direction-invariant controls and ensure custom
widgets follow ambient `Directionality` rather than assuming LTR.

## Decisions required before implementation

- Bootstrap and server-managed configuration ownership and precedence.
- Resource manifest schema, supported operations, and compatibility rules.
- Storage layout, atomic activation, rollback, quotas, and cleanup policy.
- Startup task API, dependency graph, time budgets, and blocking policy.
- Platform background-execution scope and limitations.
- Asset trust model: transport security, hashes, signatures, and allowed hosts.
- Generator selection and pinned generator/toolchain strategy.
- One generated package per service versus one combined API package.
- Whether generated packages are committed or produced during builds.
- Public imports: direct generated-package imports or curated Gicho exports.
- Regeneration command, validation command, and CI drift check.
- Versioning relationship among the OpenAPI document, generated package, and
  deployed server API.

## Definition of done

- A cached configuration permits startup while offline.
- A current manifest skips unnecessary retrieval.
- Add, replace, merge, remove, expiration, and staged activation are tested.
- Invalid or interrupted downloads preserve the last known-good resources.
- A future-dated holiday image can be downloaded early and activated on time.
- A new language registry entry and catalog become selectable from app storage
  without recompiling or releasing the application.
- Localization selects the newest valid bundled/stored catalog, falls back to
  the other local copy, then displays keys when neither is usable.
- Required and optional startup tasks demonstrate progress and timeout policy.
- Startup produces typed routing outcomes without depending on authentication
  or application-specific screens.
- A sample OpenAPI YAML document generates a working typed package.
- A configured Dio instance is injected into the generated client.
- Authentication, errors, logging, and cancellation are demonstrated.
- Unit tests use a fake or mock transport without a live server.
- Regeneration is deterministic and documented.
- Analysis and tests cover the root package, example app, and generated package.
- The root README and networking README describe the final workflow.
