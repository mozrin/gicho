// ignore_for_file: file_names

/// One ordered, consumer-owned product scene for an annual or fixed date range.
class GichoStartupScheduledScene {
  GichoStartupScheduledScene.fromConfiguration(Map values)
    : portraitAsset = values['portraitSceneAsset'] as String,
      landscapeAsset = values['landscapeSceneAsset'] as String,
      countries = List<String>.unmodifiable(
        (values['countries'] as List? ?? const []).cast<String>(),
      ),
      start = _parse(values['start'] as String),
      end = _parse(values['end'] as String) {
    if (start.annual != end.annual) {
      throw const FormatException(
        'Startup scene dates must use one date format',
      );
    }
    if (!start.annual && start.ordinal > end.ordinal) {
      throw const FormatException('Startup scene end must follow start');
    }
  }

  final String portraitAsset;
  final String landscapeAsset;
  final List<String> countries;
  final GichoStartupScheduleDate start;
  final GichoStartupScheduleDate end;

  bool includes(DateTime localDate, String? countryCode) {
    if (countries.isNotEmpty && !countries.contains(countryCode)) {
      return false;
    }
    return includesDate(localDate);
  }

  bool includesDate(DateTime localDate) {
    final day = localDate.year * 10000 + localDate.month * 100 + localDate.day;
    if (!start.annual) {
      return day >= start.ordinal && day <= end.ordinal;
    }
    final monthDay = localDate.month * 100 + localDate.day;
    if (start.ordinal <= end.ordinal) {
      return monthDay >= start.ordinal && monthDay <= end.ordinal;
    }
    return monthDay >= start.ordinal || monthDay <= end.ordinal;
  }

  static GichoStartupScheduleDate _parse(String source) {
    final annual = RegExp(r'^\d{2}-\d{2}$');
    final fixed = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (annual.hasMatch(source)) {
      final month = int.parse(source.substring(0, 2));
      final day = int.parse(source.substring(3, 5));
      _validate(2000, month, day);
      return GichoStartupScheduleDate(month * 100 + day, annual: true);
    }
    if (fixed.hasMatch(source)) {
      final year = int.parse(source.substring(0, 4));
      final month = int.parse(source.substring(5, 7));
      final day = int.parse(source.substring(8, 10));
      _validate(year, month, day);
      return GichoStartupScheduleDate(
        year * 10000 + month * 100 + day,
        annual: false,
      );
    }
    throw FormatException('Invalid startup scene date: $source');
  }

  static void _validate(int year, int month, int day) {
    final value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      throw const FormatException('Invalid startup scene calendar date');
    }
  }
}

/// Parsed date value scoped to Gicho's startup schedule.
class GichoStartupScheduleDate {
  const GichoStartupScheduleDate(this.ordinal, {required this.annual});

  final int ordinal;
  final bool annual;
}
