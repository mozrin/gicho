# Distance selector

## Problem this component solves

Choosing a discovery radius with a conventional continuous slider is imprecise.
It makes nearby, city-scale choices unnecessarily hard to set, while giving
equal visual weight to differences that are less meaningful across suburbs and
rural areas. It also makes a person with limited dexterity, a small screen, or
an imprecise touch target work around a *fat-finger* problem to choose a known
maximum.

The Distance Selector lets a person set a maximum distance in a quick,
understandable way. It offers fine-grained choices where they matter most and
coarser choices where they are sufficient. A directly editable maximum lets a
person enter a known value without having to drag the slider accurately.

## Scope and terminology

This is a controlled, single-value form component for a maximum distance. Its
unit is kilometres (`km`) in this specification. A product may localize the
display unit only if the API and all related copy use the same canonical value.

The component has two modes:

- **Finite limit:** a maximum distance is selected.
- **No limit:** there is no maximum distance. The finite selector is inactive,
  but its most recently selected value is retained for when the person returns
  to finite mode.

The component owns interaction and presentation. The containing form owns
validation persistence, saving, loading, server errors, and whether the option
to choose no limit is available.

## Functional requirements

### Supported finite values

The selectable finite domain is 1 through 500 km, inclusive.

| Range | Increment | Rationale |
| --- | ---: | --- |
| 1–20 km | 1 km | Supports close, granular choices in city spaces. |
| 25–500 km | 5 km | Supports practical larger choices for suburbs and rural areas without an overly dense control. |

The slider must expose exactly these values in ascending order. There must be
no selectable value between 20 km and 25 km, nor between five-kilometre values
above 20 km.

### Value model

The public value is either:

```text
{ noLimit: true, maximumDistanceKm: null }
{ noLimit: false, maximumDistanceKm: supported finite integer }
```

The pair is atomic: `noLimit: true` requires a null maximum; `noLimit: false`
requires one supported finite maximum. Do not represent no limit as `0`, an
arbitrarily large number, an omitted field, or an infinity value in persisted
data.

### Slider interaction

- The slider moves through the supported finite values only, never through a
  visually continuous 1–500 range.
- Each thumb movement immediately updates the displayed maximum and emits the
  changed finite value.
- The slider has a visible lower endpoint of `1 km` and a visible current-value
  marker. The current marker is also the direct-edit affordance.
- Do not imply that the spacing between marks is geographically linear. The
  scale is a list of choices with a deliberate change in increment after 20 km.
- In no-limit mode, the slider is disabled and unavailable to pointer, touch,
  keyboard, and assistive-technology value changes.

### Direct maximum-distance editing

- The displayed finite maximum is an obvious button-like control, with an edit
  icon or an equivalent visible cue; it must not depend on a hidden gesture.
- Activating it opens a focused numeric entry surface: a dialog, bottom sheet,
  or inline field appropriate to the host platform. It is prefilled with the
  current finite value and labels the unit as kilometres.
- Provide **Set** and **Cancel** actions. Cancel leaves the current selection
  unchanged. Enter/Return submits where that is conventional.
- Accept whole-number input only. On submit, constrain input below 1 to 1 and
  input above 500 to 500. For input from 21 to 499 that is not a supported
  five-kilometre value, round *up* to the next supported value. For example,
  `22` becomes `25 km` and `498` becomes `500 km`.
- Once accepted, the normalized result becomes the selected slider value and
  is announced and displayed immediately.
- Invalid non-numeric or blank input remains in the entry surface with a clear,
  local error. It must not silently change the existing selection.
- Direct editing is unavailable in no-limit mode. The no-limit state displays
  a clear non-numeric value such as `No limit` or `∞` with an accessible label;
  it is not editable as a number.

Rounding is deliberately consistent with the slider domain: direct entry is a
precision escape hatch for choosing a known supported value, not a second set
of values that the slider cannot represent.

### No-limit interaction

- When no limit is selected, retain the current finite value as the restore
  value and emit the no-limit value model.
- When finite mode is selected again, restore that retained value (or the
  product default if no previous finite value exists) and make the slider and
  edit control available again.
- Changing the no-limit state must not reset the remembered finite value.

### Defaults and external updates

- A finite initial value must be a supported value. If a host receives another
  finite integer, normalize it by the direct-entry rule before rendering.
- A host-provided update replaces both the current and remembered finite value
  when finite, or replaces only the visible mode when no-limit. This prevents
  stale local state after a successful save or a server refresh.
- The host may disable the entire component while loading or saving. In that
  state, preserve the visible value and prevent all changes.

## Visual and content design

- Put the distance label and the finite/no-limit mode control together in a
  clear section header.
- Place the current-value/edit control at the slider's high end so the selected
  maximum is easy to scan while adjusting it.
- Treat the current value as primary information: it should remain legible at
  large text sizes and never be truncated.
- Use the product's normal interactive, disabled, focus, error, and pressed
  states. Do not rely on color alone to distinguish no-limit, disabled, or
  invalid states.
- The direct-edit target and mode control must meet the product's minimum touch
  target. The slider must remain usable without requiring pixel-precise thumb
  placement.
- Localize the title, mode labels, `km` label, Set/Cancel labels, validation
  messages, and accessible names. Keep the number/unit ordering appropriate to
  the locale.

## Accessibility requirements

- Expose the slider as a single adjustable maximum-distance control with its
  current value and the available 1 km / 5 km increment behavior conveyed in
  its accessible help text.
- Support keyboard adjustment, including normal small and large adjustment
  actions where the platform supplies them. All resulting values must remain in
  the supported domain.
- Make the displayed value's accessible name explicit, for example “Maximum
  distance, 25 kilometres. Edit.” Do not expose an unlabeled edit icon.
- Announce the normalized value after a slider change or accepted direct entry.
- Opening the editor moves focus to the numeric input; closing it returns focus
  to the value/edit control. A dialog or sheet traps focus according to platform
  convention and is dismissible without losing the previous value.
- Provide an input error that is programmatically associated with the input
  and announced to assistive technology.

## States and acceptance criteria

| State | Required outcome |
| --- | --- |
| Finite, enabled | Slider and current-value edit control work; displayed value is one supported finite value. |
| Finite, disabled/busy | Current value remains visible; slider, edit control, and mode control cannot change state. |
| No limit | No-limit value is clear; finite controls cannot change the value; prior finite value is retained. |
| Editing | Numeric input is prefilled, focused, unit-labeled, and offers Set/Cancel. |
| Invalid entry | Existing selection is unchanged; the editor explains what must be corrected. |
| Out-of-range or unsupported numeric entry | The value normalizes according to the direct-entry rule and the selected display updates. |
| External update | Rendered mode/value reflect the supplied value without stale restoration behavior. |

Minimum behavioral checks:

1. Slider selection can reach every integer from 1 to 20 and every multiple of
   five from 25 to 500.
2. Editing `20` keeps `20 km`; editing `21` produces `25 km`; editing `22`
   produces `25 km`; editing `500` keeps `500 km`.
3. Editing `0` produces `1 km`; editing `501` produces `500 km`.
4. Blank and non-numeric entries do not alter the prior selected value.
5. Turning no limit on and then off restores the last finite value.
6. Every interaction is possible by keyboard and with assistive technology.

## React implementation notes

Keep the component controlled: accept the atomic value model and an `onChange`
callback, while keeping transient editor text and open/closed state internally
or in a separately controlled editor state. Construct a `distanceOptions`
array rather than mapping a continuous 1–500 numerical slider directly:

```text
[1, 2, ..., 20, 25, 30, ..., 500]
```

Map the range input's index to that array. Use the native range input only if
its accessibility behavior meets the product standard; otherwise use an
accessible slider primitive that exposes a real range/slider role and keyboard
operations. The value chip should be a semantic `<button>`, and a modal editor
should use a dialog primitive with focus restoration and an `inputMode` of
`numeric`. Centralize normalization in a pure function used by both slider and
direct-entry paths.

Do not put the numeric input inside the slider label or make the value chip a
non-semantic clickable element. Avoid formatting/parsing the displayed localized
number as the source of truth; retain the canonical integer in state.

## Flutter implementation notes

Model the value as a nullable finite integer plus explicit no-limit boolean, or
as a sealed value type that enforces the same two valid states. Build an ordered
distance-options list and use its index as the `Slider` value with divisions
equal to `options.length - 1`; map the rounded index back to the list value.

Use an `InkWell`, `TextButton`, or another semantic button for the displayed
value/edit affordance, with a `Semantics` label and enabled state. Present
direct entry with a platform-appropriate `AlertDialog`, bottom sheet, or inline
form, using a whole-number `TextInputType.number` field. Give the field a label,
surface invalid-entry errors in the form, and restore focus to the edit control
when it closes. Keep normalization in a pure Dart function shared by direct
entry, initial data, and external updates.

Avoid treating the Slider's visual position as the distance itself: it is the
index into the deliberately non-linear option list.
