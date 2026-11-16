# Application composition

These constructs compose an entire Flutter application. Import their supported
APIs from `package:gicho/gicho.dart`.

- [Bootstrap](bootstrap/README.md) runs an app-owned preparation task and
  presents loading or retry before building the ready application.
- [Material app](material_app/README.md) applies consumer-owned theme, title,
  locale and home content to Flutter's `MaterialApp`.
- [App shell](app_shell/README.md) supplies a responsive application
  frame around app-owned content and destinations.
- [Modal page](modal_page/README.md) frames a full-screen guided flow with
  optional Back and no ancillary navigation.
- [Page frame](page_frame/README.md) is the internal shared app bar and safe-area
  foundation used by shell and modal presentations.
- [Startup gate](startup_gate/README.md) handles asynchronous readiness and
  retry; [startup splash](startup_splash/README.md) presents loading feedback.
- [Startup sequence](startup_sequence/README.md) runs timed full-page scenes,
  live initialization jobs and their visual transitions before app handoff.
- [Splash scene](splash_scene/README.md) displays consumer-owned portrait and
  landscape artwork with optional overlaid content.
- [Configured startup](configured_startup/README.md) assembles the full
  company/product/loading sequence from validated consumer configuration.

New Flutter applications compose `GichoBootstrap`, `GichoMaterialApp`
and `GichoAppShell` together unless the owner explicitly directs an
exception. The bootstrap's ready builder creates the Material app, and its
home or app-owned routes use the shell. The shell owns no route map or product
policy; a screen without primary navigation passes an empty destination list.
