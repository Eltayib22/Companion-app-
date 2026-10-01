// Prayer time calculations, done fully on the device.
//
// The astronomy follows the well-known PrayTimes.org formulas, and the
// Moonsighting Committee seasonal rules follow the open-source "adhan"
// library. All results are verified against published timetables in
// test/prayer_calc_test.dart.

import 'dart:math' as math;

enum Prayer { fajr, dhuhr, asr, maghrib, isha }

extension PrayerInfo on Prayer {
  String get label => const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'][index];
  String get arabic =>
      const ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'][index];
}

enum CalcMethod {
  mwl,
  isna,
  egypt,
  makkah,
  karachi,
  dubai,
  qatar,
  kuwait,
  singapore,
  moonsighting,
  custom,
}

enum AsrMethod { standard, hanafi }

enum HighLatRule { angleBased, seventhOfNight, middleOfNight }

enum IshaEnd { midnight, fajr }

class MethodInfo {
  final String name;
  final String usedIn;
  final double fajrAngle;
  final double ishaAngle; // 0 when Isha is a fixed number of minutes
  final int ishaMinutes; // 0 when Isha uses an angle
  final int dhuhrMinutes;
  final int maghribMinutes;
  const MethodInfo(this.name, this.usedIn, this.fajrAngle, this.ishaAngle,
      this.ishaMinutes, this.dhuhrMinutes, this.maghribMinutes);
}

const Map<CalcMethod, MethodInfo> kMethods = {
  CalcMethod.mwl: MethodInfo('Muslim World League',
      'Europe, the Far East, parts of the US', 18, 17, 0, 0, 0),
  CalcMethod.isna: MethodInfo(
      'ISNA (North America)', 'United States and Canada', 15, 15, 0, 0, 0),
  CalcMethod.egypt: MethodInfo('Egyptian General Authority',
      'Africa, Syria, Lebanon, Iraq', 19.5, 17.5, 0, 0, 0),
  CalcMethod.makkah: MethodInfo('Umm al-Qura, Makkah',
      'Saudi Arabia and the Gulf', 18.5, 0, 90, 0, 0),
  CalcMethod.karachi: MethodInfo('Islamic Sciences, Karachi',
      'Pakistan, India, Bangladesh, Afghanistan', 18, 18, 0, 0, 0),
  CalcMethod.dubai:
      MethodInfo('Dubai', 'United Arab Emirates', 18.2, 18.2, 0, 0, 0),
  CalcMethod.qatar: MethodInfo('Qatar', 'Qatar', 18, 0, 90, 0, 0),
  CalcMethod.kuwait: MethodInfo('Kuwait', 'Kuwait', 18, 17.5, 0, 0, 0),
  CalcMethod.singapore: MethodInfo('Singapore, Malaysia, Indonesia',
      'Southeast Asia', 20, 18, 0, 0, 0),
  CalcMethod.moonsighting: MethodInfo('Moonsighting Committee',
      'UK and North America, adjusts with the seasons', 18, 18, 0, 5, 3),
  CalcMethod.custom:
      MethodInfo('Custom angles', 'Set your own Fajr and Isha angles', 18, 17, 0, 0, 0),
};

/// Suggests a sensible default method from coordinates.
CalcMethod suggestMethod(double lat, double lng) {
  if (lat > 12 && lat < 33 && lng > 34 && lng < 60) return CalcMethod.makkah;
  if (lat > 5 && lat < 38 && lng >= 60 && lng < 93) return CalcMethod.karachi;
  if (lat > -11 && lat < 21 && lng >= 94 && lng < 142) {
    return CalcMethod.singapore;
  }
  if (lat > 14 && lng > -170 && lng < -50) return CalcMethod.isna;
  if (lat > -36 && lat < 33 && lng > -20 && lng <= 34) return CalcMethod.egypt;
  return CalcMethod.mwl;
}

class CalcSettings {
  final CalcMethod method;
  final AsrMethod asr;
  final HighLatRule highLat;
  final double customFajr;
  final double customIsha;
  final Map<Prayer, int> offsets;
  const CalcSettings({
    required this.method,
    required this.asr,
    required this.highLat,
    required this.customFajr,
    required this.customIsha,
    required this.offsets,
  });
}

class DayTimes {
  final DateTime date;
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha;

  /// Islamic midnight: halfway between sunset and the next Fajr.
  final DateTime midnight;
  final DateTime nextFajr;

  /// True when the sun never rises or sets on this day at this latitude.
  final bool approximate;

  const DayTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.midnight,
    required this.nextFajr,
    required this.approximate,
  });

  DateTime start(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return fajr;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
    }
  }

  /// When the time for a prayer runs out.
  DateTime end(Prayer p, IshaEnd ishaEnd) {
    switch (p) {
      case Prayer.fajr:
        return sunrise;
      case Prayer.dhuhr:
        return asr;
      case Prayer.asr:
        return maghrib;
      case Prayer.maghrib:
        return isha;
      case Prayer.isha:
        return ishaEnd == IshaEnd.midnight ? midnight : nextFajr;
    }
  }
}

class PrayerCalculator {
  static double _dtr(double d) => d * math.pi / 180.0;
  static double _rtd(double r) => r * 180.0 / math.pi;
  static double _sin(double d) => math.sin(_dtr(d));
  static double _cos(double d) => math.cos(_dtr(d));
  static double _tan(double d) => math.tan(_dtr(d));
  static double _asin(double x) => _rtd(math.asin(x));
  static double _acos(double x) => _rtd(math.acos(x));
  static double _atan2(double y, double x) => _rtd(math.atan2(y, x));
  static double _acot(double x) => _rtd(math.atan(1.0 / x));

  static double _fixAngle(double a) {
    final r = a - 360.0 * (a / 360.0).floorToDouble();
    return r < 0 ? r + 360.0 : r;
  }

  static double _fixHour(double h) {
    final r = h - 24.0 * (h / 24.0).floorToDouble();
    return r < 0 ? r + 24.0 : r;
  }

  static double julian(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final whole = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b;
    return whole.toDouble() - 1524.5;
  }

  /// Returns [declination, equation of time].
  static List<double> _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final ra = _atan2(_cos(e) * _sin(l), _cos(l)) / 15.0;
    final eqt = q / 15.0 - _fixHour(ra);
    final decl = _asin(_sin(e) * _sin(l));
    return [decl, eqt];
  }

  static bool _isLeap(int y) => y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);

  static int _daysSinceSolstice(int dayOfYear, int year, double lat) {
    final daysInYear = _isLeap(year) ? 366 : 365;
    if (lat >= 0) {
      var d = dayOfYear + 10;
      if (d >= daysInYear) d -= daysInYear;
      return d;
    }
    var d = dayOfYear - (_isLeap(year) ? 173 : 172);
    if (d < 0) d += daysInYear;
    return d;
  }

  static double _piecewise(double a, double b, double c, double d, int dyy) {
    if (dyy < 91) return a + (b - a) / 91.0 * dyy;
    if (dyy < 137) return b + (c - b) / 46.0 * (dyy - 91);
    if (dyy < 183) return c + (d - c) / 46.0 * (dyy - 137);
    if (dyy < 229) return d + (c - d) / 46.0 * (dyy - 183);
    if (dyy < 275) return c + (b - c) / 46.0 * (dyy - 229);
    return b + (a - b) / 91.0 * (dyy - 275);
  }

  /// Minutes before sunrise (Moonsighting Committee).
  static double _seasonMorning(double lat, int doy, int year) {
    final l = lat.abs();
    return _piecewise(75 + 28.65 / 55.0 * l, 75 + 19.44 / 55.0 * l,
        75 + 32.74 / 55.0 * l, 75 + 48.10 / 55.0 * l,
        _daysSinceSolstice(doy, year, lat));
  }

  /// Minutes after sunset (Moonsighting Committee, general shafaq).
  static double _seasonEvening(double lat, int doy, int year) {
    final l = lat.abs();
    return _piecewise(75 + 25.60 / 55.0 * l, 75 + 2.050 / 55.0 * l,
        75 - 9.21 / 55.0 * l, 75 + 6.14 / 55.0 * l,
        _daysSinceSolstice(doy, year, lat));
  }

  static DayTimes compute({
    required DateTime date,
    required double lat,
    required double lng,
    required CalcSettings s,
    bool ramadan = false,
  }) {
    final jd = julian(date.year, date.month, date.day) - lng / (15.0 * 24.0);

    double midDay(double t) => _fixHour(12 - _sunPosition(jd + t)[1]);

    double sunAngleTime(double angle, double t, {bool ccw = false}) {
      final decl = _sunPosition(jd + t)[0];
      final noon = midDay(t);
      final c = (-_sin(angle) - _sin(decl) * _sin(lat)) /
          (_cos(decl) * _cos(lat));
      if (c.isNaN || c > 1 || c < -1) return double.nan;
      final tt = _acos(c) / 15.0;
      return ccw ? noon - tt : noon + tt;
    }

    double asrTime(double factor, double t) {
      final decl = _sunPosition(jd + t)[0];
      final angle = -_acot(factor + _tan((lat - decl).abs()));
      return sunAngleTime(angle, t);
    }

    double or(double v, double fallback) => v.isNaN ? fallback : v;

    final info = kMethods[s.method]!;
    final fajrAngle = s.method == CalcMethod.custom ? s.customFajr : info.fajrAngle;
    final ishaAngle = s.method == CalcMethod.custom ? s.customIsha : info.ishaAngle;
    var ishaMinutes = s.method == CalcMethod.custom ? 0 : info.ishaMinutes;
    if (s.method == CalcMethod.makkah && ramadan) ishaMinutes = 120;
    final asrFactor = s.asr == AsrMethod.hanafi ? 2.0 : 1.0;

    double fajr = 5, sunrise = 6, dhuhr = 12, asr = 13, sunset = 18, isha = 18;
    for (var i = 0; i < 2; i++) {
      fajr = sunAngleTime(fajrAngle, or(fajr, 5) / 24, ccw: true);
      sunrise = sunAngleTime(0.833, or(sunrise, 6) / 24, ccw: true);
      dhuhr = midDay(or(dhuhr, 12) / 24);
      asr = asrTime(asrFactor, or(asr, 13) / 24);
      sunset = sunAngleTime(0.833, or(sunset, 18) / 24);
      isha = ishaMinutes > 0 ? double.nan : sunAngleTime(ishaAngle, or(isha, 18) / 24);
    }

    final approximate = sunrise.isNaN || sunset.isNaN;
    if (approximate) {
      // Polar day or night: fall back to a fixed shape around solar noon.
      sunrise = dhuhr - 6;
      sunset = dhuhr + 6;
      if (asr.isNaN) asr = dhuhr + 3;
    }

    var maghrib = sunset + info.maghribMinutes / 60.0;
    dhuhr += info.dhuhrMinutes / 60.0;
    if (ishaMinutes > 0) isha = maghrib + ishaMinutes / 60.0;

    final night = _fixHour(sunrise - sunset);
    double portion(double angle) {
      switch (s.highLat) {
        case HighLatRule.angleBased:
          return angle / 60.0;
        case HighLatRule.seventhOfNight:
          return 1.0 / 7.0;
        case HighLatRule.middleOfNight:
          return 0.5;
      }
    }

    if (s.method == CalcMethod.moonsighting) {
      final doy = DateTime.utc(date.year, date.month, date.day)
              .difference(DateTime.utc(date.year, 1, 1))
              .inDays +
          1;
      if (lat >= 55) fajr = sunrise - night / 7.0;
      final safeFajr = sunrise - _seasonMorning(lat, doy, date.year) / 60.0;
      if (fajr.isNaN || safeFajr > fajr) fajr = safeFajr;
      if (lat >= 55) isha = sunset + night / 7.0;
      final safeIsha = sunset + _seasonEvening(lat, doy, date.year) / 60.0;
      if (isha.isNaN || safeIsha < isha) isha = safeIsha;
    } else {
      final fp = portion(fajrAngle) * night;
      if (fajr.isNaN || _fixHour(sunrise - fajr) > fp) fajr = sunrise - fp;
      if (ishaMinutes == 0) {
        final ip = portion(ishaAngle) * night;
        if (isha.isNaN || _fixHour(isha - sunset) > ip) isha = sunset + ip;
      }
    }

    int off(Prayer p) => s.offsets[p] ?? 0;
    fajr += off(Prayer.fajr) / 60.0;
    dhuhr += off(Prayer.dhuhr) / 60.0;
    asr += off(Prayer.asr) / 60.0;
    maghrib += off(Prayer.maghrib) / 60.0;
    isha += off(Prayer.isha) / 60.0;

    final nextFajr = fajr + 24.0;
    final midnight = sunset + (nextFajr - sunset) / 2.0;

    DateTime toLocal(double hours) {
      final utcHours = hours - lng / 15.0;
      final base = DateTime.utc(date.year, date.month, date.day);
      return base.add(Duration(minutes: (utcHours * 60).round())).toLocal();
    }

    return DayTimes(
      date: DateTime(date.year, date.month, date.day),
      fajr: toLocal(fajr),
      sunrise: toLocal(sunrise),
      dhuhr: toLocal(dhuhr),
      asr: toLocal(asr),
      maghrib: toLocal(maghrib),
      isha: toLocal(isha),
      midnight: toLocal(midnight),
      nextFajr: toLocal(nextFajr),
      approximate: approximate,
    );
  }

  /// Bearing to the Kaaba in degrees clockwise from true north.
  static double qibla(double lat, double lng) {
    const kLat = 21.4225, kLng = 39.8262;
    final dl = _dtr(kLng - lng);
    final y = math.sin(dl);
    final x = math.cos(_dtr(lat)) * math.tan(_dtr(kLat)) -
        math.sin(_dtr(lat)) * math.cos(dl);
    return (_rtd(math.atan2(y, x)) + 360.0) % 360.0;
  }
}

class HijriDate {
  final int year, month, day;
  const HijriDate(this.year, this.month, this.day);

  static const monthNames = [
    'Muḥarram',
    'Ṣafar',
    'Rabīʿ al-Awwal',
    'Rabīʿ al-Ākhir',
    'Jumādā al-Ūlā',
    'Jumādā al-Ākhirah',
    'Rajab',
    'Shaʿbān',
    'Ramaḍān',
    'Shawwāl',
    'Dhū al-Qaʿdah',
    'Dhū al-Ḥijjah',
  ];

  String get monthName => monthNames[(month - 1).clamp(0, 11).toInt()];

  @override
  String toString() => '$day $monthName $year AH';

  /// Tabular (arithmetical) Islamic calendar with a manual day adjustment,
  /// because local moon sighting can differ by a day or two.
  static HijriDate fromDate(DateTime date, {int adjust = 0}) {
    final d = DateTime(date.year, date.month, date.day + adjust);
    final a = (14 - d.month) ~/ 12;
    final yy = d.year + 4800 - a;
    final mm = d.month + 12 * a - 3;
    final jdn = d.day +
        (153 * mm + 2) ~/ 5 +
        365 * yy +
        yy ~/ 4 -
        yy ~/ 100 +
        yy ~/ 400 -
        32045;
    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final hm = (24 * l) ~/ 709;
    final hd = l - (709 * hm) ~/ 24;
    final hy = 30 * n + j - 30;
    return HijriDate(hy, hm, hd);
  }
}
