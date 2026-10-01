import 'prayer_calc.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String weekdayName(DateTime d, {bool short = false}) {
  final n = _weekdays[d.weekday - 1];
  return short ? n.substring(0, 3) : n;
}

String monthName(int m, {bool short = false}) {
  final n = _months[m - 1];
  return short ? n.substring(0, 3) : n;
}

/// "Wednesday 30 September"
String longDate(DateTime d) => '${weekdayName(d)} ${d.day} ${monthName(d.month)}';

/// "Wed 30 Sep"
String shortDate(DateTime d) =>
    '${weekdayName(d, short: true)} ${d.day} ${monthName(d.month, short: true)}';

String clock(DateTime t, {required bool h24}) {
  final m = t.minute.toString().padLeft(2, '0');
  if (h24) return '${t.hour.toString().padLeft(2, '0')}:$m';
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:$m ${t.hour < 12 ? 'am' : 'pm'}';
}

/// "1 h 12 min", "8 min", "less than a minute"
String duration(Duration d) {
  if (d.isNegative) return '0 min';
  final mins = (d.inSeconds / 60).ceil();
  if (mins < 1) return 'less than a minute';
  final h = mins ~/ 60;
  final m = mins % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}

/// Dhuhr on Friday is shown as Jumuʿah.
String prayerName(Prayer p, DateTime day) =>
    p == Prayer.dhuhr && day.weekday == DateTime.friday ? 'Jumuʿah' : p.label;
