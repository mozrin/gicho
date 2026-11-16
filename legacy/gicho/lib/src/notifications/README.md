> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Notifications

Gicho provides a stable wrapper over its supported Toastification version.

```dart
GichoNotifications(
  child: MaterialApp(home: const HomePage()),
);

toastification.show(
  title: const Text('Saved'),
  type: ToastificationType.success,
  autoCloseDuration: const Duration(seconds: 3),
);
```

Simple applications start with notifications off. Set
`notificationsEnabled: true` on `GichoBootstrap` to install the
`GichoNotifications` layer. The compatible Toastification API remains
exported as an advanced escape hatch for displaying and customizing transient
in-app feedback. This is not a push-notification or operating-system
notification service.

## Runtime availability

Widgets below `GichoBootstrap` can ask whether the notification layer is
actually installed:

```dart
final notifications = GichoNotifications.of(context);

if (notifications.isAvailable) {
  // Gicho's notification UI layer is available in this subtree.
}
```

Barrel files are utility-generated and must not be edited manually.

## Configuration reference

Notifications currently has no Gicho YAML parameters and no
`notifications.config.yaml`. Placement, animation, duration, styling, and
dismissal behavior are supplied through the Toastification API by the
application. Adding `assets/gicho/notifications.config.yaml` has no effect.
