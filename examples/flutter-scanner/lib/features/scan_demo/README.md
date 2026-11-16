# ScanDemo

This app-owned feature selects **employee**, **menu**, or **product** meaning, places the
shared `GichoScanner` inside an app-owned `GichoModalPage`, and displays
its accepted result. All routes use
the same camera viewport with different code selections and app-owned interpretation. The
`EMP:` prefix and `example.org/menu/` URL are demonstration formats, never
Gicho contracts. The sample QRs can be displayed on a second screen.

Import [index.dart](index.dart) from the app composition. The main widget is
in [scan_demo.dart](scan_demo.dart); its small sample QR presentation stays
private because it has no independent reusable API.
