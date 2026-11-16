> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Notifications

Gicho notifications is a reusable, configuration-driven client feature.
It owns the in-app feed lifecycle and presentation, unread badge, pagination,
optimistic read synchronization, localized copy lookup, typed destination
handoff, inline failures, and the seam for later realtime/push adapters. A
consuming application owns its event catalog, generated backend SDK adapter,
domain routing, and brand.

Laravel remains authoritative for creating events, selecting recipients,
enforcing member preferences and consent, retaining delivery evidence,
retrying server delivery, and holding provider credentials. Gicho never
decides who should receive an event and never contains Pusher, Reverb, FCM,
APNs, SMTP, or vendor credentials.

## Configuration

Gicho ships the defaults and schema:

```text
lib/src/notifications/notifications.config.yaml
lib/src/notifications/notifications.config.schema.json
```

An application supplies its override at:

```text
assets/gicho/notifications.config.yaml
```

The standard configuration service validates both documents and merges the
override. `coreCatalog` is locked to Gicho so a consumer cannot replace a
future package-owned notification. `catalog` is application-owned and defines
event types, categories, action types, icons, localized title/detail keys, and
eligible channels. Duplicate types across the two catalogs fail initialization
instead of silently replacing a package event.

```yaml
channels:
  inApp:
    enabled: true
  push:
    enabled: false
  email:
    enabled: false
catalog:
  - type: matchCreated
    category: matches
    action: match
    icon: favorite
    title: orchard.notificationFeed.matchCreatedTitle
    detail: orchard.notificationFeed.matchCreatedDetail
    unavailableDetail: orchard.notificationFeed.unavailableDetail
    channels: [inApp]
```

Channel switches describe features compiled and presented by the application;
they do not override a member's server-held preferences. Push transport is
plugged into the feature through a separate adapter so changing Pusher,
Laravel Reverb, FCM/APNs, or another engine does not alter the catalog or feed.
Email is server-delivered and shares the channel/event policy, but no email
engine or credential belongs in Flutter.

## Consumer delegate

Enable notifications in `GichoBootstrap` and provide a
`GichoNotificationDelegate`:

```dart
GichoBootstrap(
  notificationsEnabled: true,
  notificationDelegate: MyGeneratedSdkNotificationDelegate(),
  child: application,
)
```

The delegate loads cursor pages, marks one or all records read, and opens a
consumer-owned destination. Its models are protocol-neutral; the application
maps generated SDK models into `GichoNotificationRecord`. Gicho does not
construct endpoints or issue HTTP requests.

Use `GichoNotificationButton` in an app bar and route a full modal page to
`GichoNotificationFeedPage`. Both consume the same scoped controller, so
the badge and feed stay synchronized without application-specific state
management.

## Delivery lifecycle boundaries

- In-app records are durable server state; transient Toastification messages
  remain available only for short feedback.
- Foreground/background push receipt, platform permission prompts, device
  registration, token rotation/removal, multi-device logout cleanup, and
  provider feedback belong behind the future push adapter.
- Server types absent from the enabled app catalog are not rendered and emit a
  WARN. Category mismatches are also suppressed.
- Application catalog types absent from the server capability set are disabled
  with a WARN; records outside that capability set are never presented.
- Notification actions carry opaque routing data. The consumer reauthorizes
  current server state before showing protected content.
- Read mutations are optimistic and roll back on failure; the reusable page
  shows an inline localized failure instead of a snackbar-only destination.

Simple applications may enable the wrapper without a delegate to use
Toastification only. In that mode `feedAvailable` is false and the standard
feed button is absent.

Barrel files are utility-generated and must not be edited manually.
