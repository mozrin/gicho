/// The runtime availability and progress of the startup stage.
final class StartupState {
  const StartupState._({required this.isAvailable, required this.isRunning});

  const StartupState.running() : this._(isAvailable: true, isRunning: true);
  const StartupState.complete() : this._(isAvailable: true, isRunning: false);
  const StartupState.unavailable()
    : this._(isAvailable: false, isRunning: false);

  /// True when the startup stage is enabled for this application.
  final bool isAvailable;

  /// True while startup presentation or blocking tasks are incomplete.
  final bool isRunning;
}
