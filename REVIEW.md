> Historical source-baseline record, renamed for readability. These entries
> describe the source before Gicho; they are not Gicho release or validation evidence.

# Gicho review ledger

## Contact entry controls (#63) — 9 October 2026

- `StructuredPostalAddressFields/` renders caller-supplied Google libaddressinput field order, labels and required status through a generic Gicho control. Contackage supplies the metadata.
- `ContactPhoneField/` renders a country selector, phone input and owner-declared capabilities. Formatting is provided by the contact package; verification state is supplied only after delivery confirmation.
- `ContactEmailField/` renders email entry and a verified indicator controlled by a delivered-confirmation service.
- `ContactPhoneField/` expands its country picker to fit narrow form widths; Harmony EMS widget tests exposed and drove this fix.
- Both constructs are exported from `gicho.dart`; package patch version is 0.0.12. Flutter analysis and two focused widget tests pass. Harmony/Contackage consumption is pending.

## Shell title prefix for active POS ticket (#444) — 8 October 2026

- Existing `lib/src/application/app_shell/` and internal `page_frame/` accept an optional app-provided title prefix and tappable title, replacing the compact brand mark for that page. POS supplies its interactive receipt with item count beside Ticket, and both controls open its active ticket. Gicho still owns layout, responsive navigation and app-bar structure; POS owns ticket state and tap behavior. This substantive existing-construct change uses the active Durable Goal review caveat. The Gicho shell widget tests pass at phone and large widths, and `flutter analyze` is clean; POS consumer validation remains pending.

## Disabled shell destinations (#31)

- `lib/src/application/app_shell/`: forwards a consumer-provided
  `NavigationDestination.enabled` value into both the phone/tablet drawer and
  large-screen rail. Gicho still owns no connectivity or authorization
  policy; POS decides which sections are unavailable.
- `test/gicho_app_shell_test.dart`: covers disabled destinations at phone and
  large widths, including ignored taps.
- `lib/src/application/app_shell/README.md`: documents the public behavior.

This substantive existing-construct change is recorded under the active POS
Durable Goal's convention caveat. Host validation and consumer adoption will
be recorded when this slice is complete.
