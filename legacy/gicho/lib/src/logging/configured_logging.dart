import 'package:easy_localization/easy_localization.dart';
import 'package:logger/logger.dart';

import '../config/configuration_service.dart';
import '../config/configuration_registry.dart';

/// Package logging configured by package defaults and optional app overrides.
class MoztopiaLogging {
  MoztopiaLogging({
    ConfigurationService? configurationService,
    ConfigurationRegistry? configurationRegistry,
  }) : assert(
         configurationService == null || configurationRegistry == null,
         'Provide either configurationService or configurationRegistry.',
       ),
       _configurationService = configurationService,
       _configurationRegistry =
           configurationRegistry ??
           (configurationService == null ? moztopiaConfig : null);

  final ConfigurationService? _configurationService;
  final ConfigurationRegistry? _configurationRegistry;
  Future<Logger>? _initialization;
  Logger? _logger;

  /// Initializes logging once and returns the configured logger.
  Future<Logger> initialize() => _initialization ??= _createLogger();

  /// The configured logger after [initialize] has completed.
  Logger get logger =>
      _logger ??
      (throw StateError('Moztopia logging has not been initialized.'));

  Future<void> debug(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    (await initialize()).d(
      message,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> trace(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    (await initialize()).t(
      message,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> info(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    (await initialize()).i(
      message,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> warn(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    (await initialize()).w(
      message,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> error(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    (await initialize()).e(
      message,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> fatal(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    (await initialize()).f(
      message,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<Logger> _createLogger() async {
    final configuration =
        await (_configurationRegistry?.loadFeature('logging') ??
            _configurationService!.loadFeature('logging'));
    final colors = configuration.require<Map<String, dynamic>>('colors');
    final boxing = configuration.require<bool>('boxing');

    final levelColors = <Level, AnsiColor>{
      Level.debug: loggingAnsiColor(colors['debug'] as String),
      Level.info: loggingAnsiColor(colors['info'] as String),
      Level.warning: loggingAnsiColor(colors['warn'] as String),
      Level.error: loggingAnsiColor(colors['error'] as String),
    };

    _logger = Logger(
      printer: boxing
          ? PrettyPrinter(
              methodCount: 0,
              errorMethodCount: 6,
              lineLength: 90,
              printEmojis: false,
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
              levelColors: levelColors,
            )
          : CompactLogPrinter(levelColors: levelColors),
    );
    _redirectEasyLocalizationLogging();
    return _logger!;
  }

  void _redirectEasyLocalizationLogging() {
    EasyLocalization.logger.printer =
        (
          Object message, {
          String? name,
          dynamic level,
          StackTrace? stackTrace,
        }) {
          final text = name == null ? message : '[$name] $message';
          switch (level.toString().split('.').last) {
            case 'error':
              _logger!.e(text, stackTrace: stackTrace);
            case 'warning':
              _logger!.w(text, stackTrace: stackTrace);
            case 'info':
              _logger!.i(text, stackTrace: stackTrace);
            default:
              _logger!.d(text, stackTrace: stackTrace);
          }
        };
  }
}

/// Formats each event as one colored `time [LEVEL] message` line.
class CompactLogPrinter extends LogPrinter {
  CompactLogPrinter({required this.levelColors});

  final Map<Level, AnsiColor> levelColors;

  @override
  List<String> log(LogEvent event) {
    final parts = <String>[
      _formatTime(event.time),
      '[${_levelLabel(event.level)}]',
      _singleLine(event.message),
    ];
    if (event.error != null) parts.add('error: ${_singleLine(event.error)}');
    if (event.stackTrace != null) {
      parts.add('stack: ${_singleLine(event.stackTrace)}');
    }
    final line = parts.join(' ');
    return [(levelColors[event.level] ?? const AnsiColor.none())(line)];
  }

  String _formatTime(DateTime time) =>
      '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}:'
      '${_twoDigits(time.second)}.${_threeDigits(time.millisecond)}';

  String _levelLabel(Level level) => switch (level) {
    Level.warning => 'WARN',
    _ => level.name.toUpperCase(),
  };

  String _singleLine(Object? value) =>
      '$value'.replaceAll(RegExp(r'[\r\n]+'), ' ↵ ');

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _threeDigits(int value) => value.toString().padLeft(3, '0');
}

/// The default lazily initialized package logging API.
final moztopiaLog = MoztopiaLogging();

/// Converts a schema-approved logging color name to an ANSI color.
AnsiColor loggingAnsiColor(String name) => switch (name) {
  'blue' => const AnsiColor.fg(12),
  'red' => const AnsiColor.fg(196),
  'yellow' => const AnsiColor.fg(226),
  'green' => const AnsiColor.fg(46),
  'purple' => const AnsiColor.fg(129),
  _ => throw ArgumentError.value(name, 'name', 'Unsupported logging color'),
};
