# GichoModalPage

`GichoModalPage` is a full-screen page for a guided flow, not a floating
dialog. It uses the ordinary Material page frame with one title, optional app
actions and safe-area content while omitting ancillary navigation. Use it for
onboarding, About, License or a focused task. Authackage may later use it for
provider selection.

Back is visible by default. Its tooltip uses the active Material locale unless
the caller supplies `backLabel`. By default it calls `Navigator.maybePop`;
supply `onBack` for a deep link or root fallback. Set `showBackButton: false`
for an entry page with no Back action. The caller owns the body, router origin,
save/cancel behavior, authorization and any app-specific fallback.

```dart
GichoModalPage(
  title: 'Scan code',
  backLabel: 'Back',
  body: const ScannerContent(),
)
```

The modal page and `GichoAppShell` use the same internal
[page frame](../page_frame/README.md). Broader app-bar and shell configuration,
including navigation state, remains on Gicho #31. Pass a resolved `brand`
to show the compact mark beside this page's title, or set `showBrand: false` to
hide it. This construct does not manage a route stack.
