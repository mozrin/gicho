# GichoBrandHeader

```dart
const GichoBrandHeader(title: 'Customer')
```

The existing title and logo constructor remains available. For resolved
Gicho branding, use:

```dart
GichoBrandHeader.branded(brand: brand)
```

The branded form renders the full logo without a second title. A missing image
shows the built-in symbol with the brand name. For a compact mark in an app
bar, use `GichoBrandImage(brand: brand, compact: true)`.

Import through `package:gicho/gicho.dart`. This generic presentation
does not control authentication provider buttons.
