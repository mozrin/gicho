# ComponentGallery

This example-owned screen hosts the existing interactive distance-slider
controls, a startup-demo destination and an About modal. It uses Gicho's
public `GichoAppShell`, `DistanceSlider` and `GichoModalPage` APIs. The
gallery owns only demo state and navigation callbacks; it has no package API
or authentication policy.

Import `ComponentGallery` through `index.dart` from the example's `app.dart`.
The widget's Flutter `State` owns its demo settings and disposes with the
screen. This broad gallery is retained for current behavior and tests while
focused examples under `examples/{scenario-slug}` replace its mixed scenarios.
New scenarios should go into their own example instead of enlarging this file.
