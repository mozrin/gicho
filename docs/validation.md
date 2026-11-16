# Validation status

Initial Gicho source release validation is in progress. No completion is implied
by this document's existence. The numeric release target is 0.1.0.

Verified so far on 16 November 2026 with Flutter 3.47.6 and Dart 3.13.5:
- Package analysis passes.
- All 76 existing package tests pass when running both test/ and lib/.
- Dependency resolution and analysis pass for all seven maintained examples.
- Initial example testing found bootstrap expectations needing startup-default
  updates and a Material/ListTile rendering assertion in distance-slider.
- Place lookup lacked tests and required a key. An explicitly labelled offline
  demonstration and functional coverage are being added without removing Google mode.

Build, runtime, final regression and clean tagged-consumer acceptance remain
pending. Live Google service tests need a user-owned restricted development key.
Physical camera/device acceptance requires appropriate available hardware.
Historical snapshots are not current examples and are excluded from acceptance.
