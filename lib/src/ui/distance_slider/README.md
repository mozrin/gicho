# Distance slider

`DistanceSlider` is a controlled maximum-distance picker. It offers discrete
slider stops, manual entry, and an optional no-limit state. Values are stored
as whole kilometres, from 1 through 500.

For a Git dependency, use a tested, pushed revision of the root package:

```yaml
dependencies:
  gicho:
    git:
      url: https://github.com/mozrin/gicho.git
      ref: <tested-commit-sha>
```

```dart
import 'package:gicho/gicho.dart';

DistanceSelectorValue value = DistanceSelectorValue.finite(25);

DistanceSlider(
  value: value,
  onChanged: (nextValue) => setState(() => value = nextValue),
  maximumDistance: 300,
  increment: 5,
  incrementThreshold: 20,
  defaultDistance: 1,
  allowNoLimit: true,
  unit: DistanceUnit.kilometres,
)
```

`value` is owned by the parent. Pass each `onChanged` value back to the
component on rebuild. Use `DistanceSelectorValue.finite(kilometres)` for a
finite limit or `const DistanceSelectorValue.noLimit()` when no limit is
allowed.

## Configuration

- `increment` controls the larger slider steps and defaults to `5`; zero or
  negative values throw an `ArgumentError`.
- `incrementThreshold` defaults to `20`: values step by one from 1 through 20,
  then use multiples of `increment` (for example, 20 → 25 → 50 with an
  increment of 25). The minimum and maximum remain selectable even when they
  are not multiples. Set it to `0` or `null` to begin directly at the
  increment stops (1, then the increment value, then each increment after it).
- `minimumDistance` defaults to `1`; `maximumDistance` is required. Together
  they define the accepted manual-entry range and the slider endpoints.
- `label` defaults to `Maximum distance`. Set it to `null` to omit the header
  text.
- `defaultDistance` is the finite value restored when leaving no-limit mode and
  defaults to `1`. It must be between 1 and 500 kilometres.
- `allowNoLimit` defaults to `true`; setting it to `false` removes the no-limit
  control.
- `unit` defaults to `DistanceUnit.kilometres`. Set it to
  `DistanceUnit.miles` for an `m` suffix, or to `null` for no suffix. Changing
  the unit changes only the label, never the numeric value.

Manual entry accepts whole numbers from 1 to 500 and does not require a value
to match the slider increment.
