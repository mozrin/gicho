> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Forms

Gicho exposes Reactive Forms through `package:moztopia/gicho.dart`.

```dart
final form = FormGroup({
  'email': FormControl<String>(validators: [Validators.required, Validators.email]),
});

ReactiveForm(
  formGroup: form,
  child: const ReactiveTextField<String>(formControlName: 'email'),
);
```

Use it directly for model-driven fields, synchronous and asynchronous
validation, form arrays, value binding, and validation state. Keep forms and
their validation rules in the consuming application.

Barrel files are utility-generated and must not be edited manually.

## Configuration reference

Forms currently has no Gicho YAML parameters and no `forms.config.yaml`.
Form models, controls, validators, error messages, and submission behavior
remain application-owned. Adding `assets/gicho/forms.config.yaml` has no effect.
