# Optional navigation-shell refactor

## Problem

`example.everything/lib/navigation/` contains substantial code for a consuming
application. Some of that code is necessary because the example deliberately
demonstrates five persistent navigation stacks, a drawer, adaptive navigation,
modal routes, animated branch switching, and custom error handling. However,
some of it is mechanical GoRouter and Flutter composition that simple-mode
consumers should not have to repeat.

The goal is to reduce repeated navigation setup without making the
`example.everything` layout mandatory for every Gicho application.

## Architectural boundary

### The navigation shell remains optional

`GichoMaterialApp` must not automatically install a drawer, navigation rail,
or bottom navigation bar. A consumer may use a content-only layout, its own
custom shell, or the optional Gicho shell. Choosing the Gicho shell means
choosing one convenient navigation pattern, not accepting a framework
requirement.

### Routes remain consumer-owned Dart

Consumers still declare their pages, paths, parameters, redirects, guards, and
modal behavior in Dart. The optional shell may make primary branch declarations
shorter, but it must not move the route table into YAML. `GichoRouter`
continues to provide the standardized GoRouter foundation.

### Layout data remains consumer-owned

The consumer decides destination labels, icons, pages, drawer grouping, and
responsive behavior. Gicho may provide typed models and widgets that render
that data. It must not know about names such as `FNav1`, `DNav1`, `Logging`, or
`Config`.

## Current navigation files

```text
lib/navigation/
├── app_drawer.dart
├── app_router.dart
├── app_shell.dart
├── branch_container.dart
├── destination.dart
└── secondary_destination.dart
```

My assessment:

- `app_router.dart` is required in some form, but can be shortened.
- `app_shell.dart` expresses the example's layout and should remain
  consumer-owned unless the optional Gicho shell is selected.
- `app_drawer.dart` contains consumer content, branding, grouping, and labels.
  A package component may render it, but the package should not own that data.
- `branch_container.dart` is avoidable because GoRouter already provides an
  indexed-stack stateful shell.
- `destination.dart` and `secondary_destination.dart` duplicate much of the
  same navigation metadata and can become one model.

## Phase 1: remove avoidable local boilerplate

### Use GoRouter's indexed-stack shell

Replace the custom `BranchContainer` with
`StatefulShellRoute.indexedStack`. GoRouter will preserve each primary branch's
navigation state without requiring the consumer to implement its own stack,
opacity, pointer, and ticker management.

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AppShell(shell: shell),
  branches: primaryDestinations.map((destination) {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: destination.path,
          builder: destination.builder,
        ),
      ],
    );
  }).toList(),
)
```

Tradeoff: the existing cross-fade animation disappears unless GoRouter's
default container is later replaced intentionally. Preserving navigation state
is important; preserving this particular animation is optional.

### Remove forwarding page builders

Functions such as `_buildFNav1` only return a constant page and do not add
policy. Declare the page builder beside the destination instead.

```dart
GoRoute(
  path: '/fnav1',
  builder: (context, state) => const FNav1Screen(),
)
```

Keep a named builder only when it performs meaningful parameter parsing,
dependency lookup, authorization, or error handling.

### Consolidate destination models

Replace `Destination` and `SecondaryDestination` with one consumer-owned model.
Fields that do not apply to every destination remain optional.

```dart
typedef GichoPageBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

final class AppDestination {
  const AppDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.builder,
    this.selectedIcon,
    this.message,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final GichoPageBuilder builder;
  final String? message;
}
```

The model initially belongs in the example. Move it into Gicho only if more
than one consumer-facing component genuinely needs the same contract.

### Extract repeated modal-page construction

Keep modal decisions in the router, but use a small Dart helper for repeated
`MaterialPage` setup.

```dart
Page<void> modalPage(GoRouterState state, Widget child) => MaterialPage<void>(
  key: state.pageKey,
  fullscreenDialog: true,
  child: child,
);
```

This removes repetition without hiding the fact that the route is modal.

## Phase 2: design an optional Gicho navigation shell

Only proceed with this phase if the reduced example still contains enough
repeated composition to justify a package component.

### Proposed package component

```dart
GichoNavigationShell(
  shell: shell,
  destinations: primaryDestinations,
  appBar: (context, destination) => GichoAppBar(
    title: Text(destination.label),
  ),
  drawer: const AppDrawer(),
)
```

The component would provide the common adaptive behavior:

- use a bottom `NavigationBar` on narrow windows;
- use a `NavigationRail` on wide windows;
- call `StatefulNavigationShell.goBranch` when a destination is selected;
- retain the current branch when the surrounding layout changes;
- place consumer-provided content inside `GichoPageShell`.

The consumer still supplies the destinations, app bar, optional drawer, and
route branches.

### Proposed destination contract

If a package-owned model proves useful, keep it focused on primary navigation
presentation:

```dart
final class GichoNavigationDestination {
  const GichoNavigationDestination({
    required this.path,
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}
```

The destination should not contain a page builder if that would create two
sources of truth between the shell and router. The route table remains the
authoritative mapping from paths to pages.

### Proposed responsive options

Avoid many unrelated boolean flags. Use a small typed presentation object when
the defaults need adjustment.

```dart
const GichoNavigationShellStyle(
  railBreakpoint: 840,
  railLabelType: NavigationRailLabelType.all,
  showDrawerOnWideLayout: true,
)
```

The defaults should reproduce a sensible Material adaptive shell. Consumers
with substantially different navigation should build their own layout rather
than forcing it through this API.

## What must stay in `example.everything`

The following concerns are specific to the demonstration and should not move
into the package:

- Moztopia branding in the drawer header;
- drawer divider placement;
- the explanatory drawer footer;
- destination labels and icons;
- the logging destination and its messages;
- the special logging performed when destinations are selected;
- the decision that `Config` is the fifth primary branch;
- example-specific modal paths and parameters;
- the example-specific not-found page.

## Target consumer structure

After the local cleanup and optional shell adoption, the example should aim for
approximately:

```text
lib/navigation/
├── app_router.dart       # Consumer routes and modal behavior
├── app_shell.dart        # Thin use of GichoNavigationShell
├── app_drawer.dart       # Example branding and drawer content
└── app_destination.dart  # Consumer navigation metadata
```

If `GichoNavigationShell` makes `app_shell.dart` trivial, it may be folded
into `app_router.dart`. Do not combine files solely to reduce the file count if
the result becomes harder to understand.

## Relationship to the examples

`example.minimal` remains the recommended picture of ordinary Gicho
adoption. It should not gain a navigation shell merely because one exists.

`example.everything` is intentionally a complicated showcase. Its README must
state that the navigation system demonstrates optional capabilities rather
than representing required consumer boilerplate.

## Acceptance criteria

- [ ] `BranchContainer` is removed in favor of
  `StatefulShellRoute.indexedStack`, unless its animation is explicitly kept as
  an example-owned enhancement.
- [ ] Primary and secondary destination metadata no longer duplicate separate
  model definitions without a reason.
- [ ] Trivial forwarding route builders are removed.
- [ ] Repeated modal-page construction is reduced with ordinary Dart helpers.
- [ ] Routes, page builders, parameters, redirects, and guards remain in
  consumer Dart.
- [ ] `GichoMaterialApp` does not inject a navigation layout.
- [ ] Any `GichoNavigationShell` implementation is explicitly opt-in.
- [ ] A consumer can supply its own drawer and app bar or omit both.
- [ ] A consumer can ignore `GichoNavigationShell` and use any Flutter
  layout.
- [ ] `example.minimal` remains free of navigation-shell code.
- [ ] `flutter analyze` succeeds for Gicho and the affected examples.
- [ ] The user runs tests after lint succeeds.

## Recommended implementation order

1. Replace `BranchContainer` with `StatefulShellRoute.indexedStack`.
2. Inline trivial page builders.
3. Consolidate the two destination models inside the example.
4. Extract the small modal-page helper.
5. Review the remaining `AppShell` and `AppDrawer` code.
6. Decide whether the remaining repetition justifies
   `GichoNavigationShell`.
7. If justified, implement it as an optional component and reduce
   `example.everything` to a thin consumer.
8. Run `flutter analyze` and hand test execution to the user.
