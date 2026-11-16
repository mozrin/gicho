# PageFrame

`PageFrame` is the package-internal page foundation shared by
`GichoAppShell` and `GichoModalPage`. It provides one Material app bar,
actions, a safe-area body and optional drawer wiring. The parent presentation
chooses its leading control and navigation: the shell supplies a menu when it
has destinations, while a modal page may supply Back or omit it.
When a page supplies a resolved brand, the shared app bar places its compact
mark beside the page title. `showBrand: false` hides that mark for the page;
the title remains visible once. Full logos belong in body/startup surfaces.
An optional `titlePrefix` replaces the compact mark and lets a consuming app
place an interactive, accessibly named control beside the title.
When `onTitlePressed` is supplied, the title gains a focusable Material tap
target while retaining the app bar's title typography.

Import this construct through `page_frame/index.dart` from another Gicho
application construct. Consumers use the public shell or modal page instead;
`PageFrame` is deliberately absent from `package:gicho/gicho.dart`.
It owns no route stack, section state, authentication or product policy.
