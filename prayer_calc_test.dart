import 'package:flutter_test/flutter_test.dart';
import 'package:salah_companion/core/prayer_calc.dart';

/// Expected values come from published timetables and an independent
/// implementation of the same formulas. Times are compared in UTC so the
/// test does not depend on the computer's time zone.
void main() {
  CalcSettings settings(CalcMethod m, {AsrMethod asr = AsrMethod.standard}) => CalcSettings(
        method: m,
        asr: asr,
        highLat: HighLatRule.angleBased,
        customFajr: 18,
        customIsha: 17,
        offsets: const {},
      );

  void near(DateTime actual, int hourUtc, int minuteUtc, String label) {
    final a = actual.toUtc();
    final diff = (a.hour * 60 + a.minute) - (hourUtc * 60 + minuteUtc);
    expect(diff.abs() <= 2, isTrue,
        reason: '$label was ${a.hour}:${a.minute} UTC, expected about $hourUtc:$minuteUtc');
  }

  test('London, 30 September 2026, Muslim World League', () {
    final t = PrayerCalculator.compute(
      date: DateTime(2026, 9, 30),
      lat: 51.5074,
      lng: -0.1278,
      s: settings(CalcMethod.mwl),
    );
    near(t.fajr, 4, 7, 'Fajr');
    near(t.sunrise, 5, 59, 'Sunrise');
    near(t.dhuhr, 11, 50, 'Dhuhr');
    near(t.asr, 14, 58, 'Asr');
    near(t.maghrib, 17, 41, 'Maghrib');
    near(t.isha, 19, 26, 'Isha');
  });

  test('London midsummer, Moonsighting Committee keeps Isha reasonable', () {
    final t = PrayerCalculator.compute(
      date: DateTime(2026, 6, 21),
      lat: 51.5074,
      lng: -0.1278,
      s: settings(CalcMethod.moonsighting),
    );
    near(t.fajr, 1, 43, 'Fajr');
    near(t.isha, 21, 42, 'Isha');
  });

  test('Makkah, Umm al-Qura uses 90 minutes for Isha', () {
    final t = PrayerCalculator.compute(
      date: DateTime(2026, 9, 30),
      lat: 21.4225,
      lng: 39.8262,
      s: settings(CalcMethod.makkah),
    );
    near(t.fajr, 1, 56, 'Fajr');
    near(t.maghrib, 15, 10, 'Maghrib');
    expect(t.isha.difference(t.maghrib).inMinutes, 90);
  });

  test('Hanafi Asr is later than standard Asr', () {
    final std = PrayerCalculator.compute(
        date: DateTime(2026, 9, 30), lat: 24.8607, lng: 67.0011, s: settings(CalcMethod.karachi));
    final han = PrayerCalculator.compute(
        date: DateTime(2026, 9, 30),
        lat: 24.8607,
        lng: 67.0011,
        s: settings(CalcMethod.karachi, asr: AsrMethod.hanafi));
    expect(han.asr.isAfter(std.asr), isTrue);
    near(han.asr, 11, 40, 'Hanafi Asr');
  });

  test('Hijri dates', () {
    final a = HijriDate.fromDate(DateTime(2026, 2, 18));
    expect([a.year, a.month, a.day], [1447, 9, 1]);
    final b = HijriDate.fromDate(DateTime(2026, 5, 27));
    expect([b.year, b.month, b.day], [1447, 12, 10]);
  });

  test('Qibla bearings', () {
    expect(PrayerCalculator.qibla(51.5074, -0.1278), closeTo(119.0, 0.5));
    expect(PrayerCalculator.qibla(40.7128, -74.006), closeTo(58.5, 0.5));
  });
}
