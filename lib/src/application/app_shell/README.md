# GichoAppShell

Use the public `package:gicho/gicho.dart` entry point:

```dart
GichoAppShell(
  title: 'Customer',
  locales: locales,
  body: const Center(child: Text('Memberships')),
)
```

Generic Material shell with app-owned title, destinations, selection, actions
and body. Below 1280 logical pixels it uses a modal navigation drawer with
an accessible close action; at 1280 and above it uses a persistent extended
navigation rail. Selecting a drawer destination closes the drawer. The menu
button regains focus when the drawer closes.

The shell and `GichoModalPage` use the same internal
[page frame](../page_frame/README.md) for the app bar and safe-area body.
Pass `brand: resolvedBrand` to place its compact mark beside the page title.
Set `showBrand: false` for a page that should omit the mark. The title is never
duplicated. New Flutter apps use this shell with `GichoBootstrap` and
`GichoMaterialApp` unless the owner explicitly directs an exception.
Pass `titlePrefix` for an app-owned control immediately beside the title. It
replaces the compact brand mark on that page; the app supplies the control's
accessible label and behavior.
Pass `onTitlePressed` when the page title itself is a destination. Gicho
provides keyboard focus, tap and hover feedback; the app decides whether the
destination is currently available.

The app supplies `NavigationDestination` values and handles selection. Gicho
preserves each destination's `enabled` state in both the drawer and rail, so a
consumer can disable an unavailable section without custom navigation chrome.
The consumer still decides when a section is unavailable and what its body shows.
Gicho
does not define an application route map, auth state, tenant or permissions.
Pass the shared locale controller for package-owned navigation labels; the app
can override those fully qualified catalog keys.
Pass an empty list for a screen with no primary navigation. The body should be
page content rather than another Scaffold with a duplicate app bar.
