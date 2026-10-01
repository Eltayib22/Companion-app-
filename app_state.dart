import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_calc.dart';

enum PrayerStatus { none, onTime, late, missed, exempt }

extension PrayerStatusInfo on PrayerStatus {
  String get label => const [
        'Not marked',
        'Prayed on time',
        'Prayed late',
        'Missed',
        'Excused',
      ][index];

  bool get settled =>
      this == PrayerStatus.onTime ||
      this == PrayerStatus.late ||
      this == PrayerStatus.exempt;
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

DateTime? parseDayKey(String k) {
  final parts = k.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

class PrayerSlot {
  final Prayer prayer;
  final DateTime day;
  final DateTime start;
  final DateTime end;
  const PrayerSlot(this.prayer, this.day, this.start, this.end);
}

class Settings {
  double? lat;
  double? lng;
  String place = '';
  CalcMethod method = CalcMethod.mwl;
  AsrMethod asr = AsrMethod.standard;
  HighLatRule highLat = HighLatRule.angleBased;
  IshaEnd ishaEnd = IshaEnd.midnight;
  double customFajr = 18;
  double customIsha = 17;
  Map<Prayer, int> offsets = {for (final p in Prayer.values) p: 0};

  bool alertsOn = true;
  Map<Prayer, bool> prayerAlerts = {for (final p in Prayer.values) p: true};
  int preReminder = 0; // minutes before the prayer, 0 = off
  int repeatEvery = 10; // minutes between repeat alerts
  int maxRepeats = 0; // 0 = keep going until the time for the prayer ends
  int closingWarning = 20; // minutes before the end, 0 = off
  bool customSound = false;
  bool morningAdhkarReminder = true;
  bool eveningAdhkarReminder = true;

  bool exempt = false;
  bool travel = false;
  String ramadanMode = 'auto'; // auto, on, off
  bool trackSunnah = false;

  int hijriAdjust = 0;
  String theme = 'system'; // system, light, dark
  double arabicScale = 1.0;
  bool takbir34 = false;
  bool tajweedColours = true;
  bool onboarded = false;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'place': place,
        'method': method.name,
        'asr': asr.name,
        'highLat': highLat.name,
        'ishaEnd': ishaEnd.name,
        'customFajr': customFajr,
        'customIsha': customIsha,
        'offsets': {for (final e in offsets.entries) e.key.name: e.value},
        'alertsOn': alertsOn,
        'prayerAlerts': {
          for (final e in prayerAlerts.entries) e.key.name: e.value
        },
        'preReminder': preReminder,
        'repeatEvery': repeatEvery,
        'maxRepeats': maxRepeats,
        'closingWarning': closingWarning,
        'customSound': customSound,
        'morningAdhkarReminder': morningAdhkarReminder,
        'eveningAdhkarReminder': eveningAdhkarReminder,
        'exempt': exempt,
        'travel': travel,
        'ramadanMode': ramadanMode,
        'trackSunnah': trackSunnah,
        'hijriAdjust': hijriAdjust,
        'theme': theme,
        'arabicScale': arabicScale,
        'takbir34': takbir34,
        'tajweedColours': tajweedColours,
        'onboarded': onboarded,
      };

  static Settings fromJson(Map<String, dynamic> j) {
    final s = Settings();
    s.lat = (j['lat'] as num?)?.toDouble();
    s.lng = (j['lng'] as num?)?.toDouble();
    s.place = (j['place'] as String?) ?? '';
    s.method = _enumByName(CalcMethod.values, j['method'], CalcMethod.mwl);
    s.asr = _enumByName(AsrMethod.values, j['asr'], AsrMethod.standard);
    s.highLat =
        _enumByName(HighLatRule.values, j['highLat'], HighLatRule.angleBased);
    s.ishaEnd = _enumByName(IshaEnd.values, j['ishaEnd'], IshaEnd.midnight);
    s.customFajr = (j['customFajr'] as num?)?.toDouble() ?? 18;
    s.customIsha = (j['customIsha'] as num?)?.toDouble() ?? 17;
    final off = j['offsets'];
    if (off is Map) {
      for (final p in Prayer.values) {
        s.offsets[p] = (off[p.name] as num?)?.toInt() ?? 0;
      }
    }
    s.alertsOn = (j['alertsOn'] as bool?) ?? true;
    final pa = j['prayerAlerts'];
    if (pa is Map) {
      for (final p in Prayer.values) {
        s.prayerAlerts[p] = (pa[p.name] as bool?) ?? true;
      }
    }
    s.preReminder = (j['preReminder'] as num?)?.toInt() ?? 0;
    s.repeatEvery = (j['repeatEvery'] as num?)?.toInt() ?? 10;
    s.maxRepeats = (j['maxRepeats'] as num?)?.toInt() ?? 0;
    s.closingWarning = (j['closingWarning'] as num?)?.toInt() ?? 20;
    s.customSound = (j['customSound'] as bool?) ?? false;
    s.morningAdhkarReminder = (j['morningAdhkarReminder'] as bool?) ?? true;
    s.eveningAdhkarReminder = (j['eveningAdhkarReminder'] as bool?) ?? true;
    s.exempt = (j['exempt'] as bool?) ?? false;
    s.travel = (j['travel'] as bool?) ?? false;
    s.ramadanMode = (j['ramadanMode'] as String?) ?? 'auto';
    s.trackSunnah = (j['trackSunnah'] as bool?) ?? false;
    s.hijriAdjust = (j['hijriAdjust'] as num?)?.toInt() ?? 0;
    s.theme = (j['theme'] as String?) ?? 'system';
    s.arabicScale = (j['arabicScale'] as num?)?.toDouble() ?? 1.0;
    s.takbir34 = (j['takbir34'] as bool?) ?? false;
    s.tajweedColours = (j['tajweedColours'] as bool?) ?? true;
    s.onboarded = (j['onboarded'] as bool?) ?? false;
    return s;
  }
}

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const _storageKey = 'salah_companion_state_v1';
  SharedPreferences? _prefs;
  Timer? _saveTimer;

  /// Set in main.dart so alert scheduling reacts to changes.
  void Function()? onScheduleNeeded;

  Settings settings = Settings();
  final Map<String, Map<String, String>> _log = {};
  final Map<String, List<String>> _extras = {};
  final Map<String, int> qada = {for (final p in Prayer.values) p.name: 0};
  final Map<String, int> dhikrDaily = {};
  final Map<String, List<String>> adhkarDone = {};
  final Set<String> lessonsDone = {};
  final List<String> bookmarks = [];
  String? lastRead;
  bool showArabic = true;
  bool showTranslit = true;
  bool showMeaning = true;
  String? lastReconciled;
  int? trackingSince; // ms since epoch; nothing earlier is auto-marked missed
  int tasbihPreset = 0;
  int tasbihCount = 0;
  int tasbihTarget = 33;

  /// Updated by the UI so notification text matches the phone's clock format.
  bool use24h = false;

  final Map<String, DayTimes> _cache = {};

  // ---------------------------------------------------------------- storage

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    if (raw == null) return;
    try {
      _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Could not read saved state: $e');
    }
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'settings': settings.toJson(),
        'log': _log,
        'extras': _extras,
        'qada': qada,
        'dhikrDaily': dhikrDaily,
        'adhkarDone': adhkarDone,
        'lessonsDone': lessonsDone.toList(),
        'bookmarks': bookmarks,
        'lastRead': lastRead,
        'view': {
          'arabic': showArabic,
          'translit': showTranslit,
          'meaning': showMeaning,
        },
        'lastReconciled': lastReconciled,
        'trackingSince': trackingSince,
        'tasbih': {
          'preset': tasbihPreset,
          'count': tasbihCount,
          'target': tasbihTarget,
        },
      };

  void _fromJson(Map<String, dynamic> j) {
    final s = j['settings'];
    settings = s is Map<String, dynamic> ? Settings.fromJson(s) : Settings();

    _log.clear();
    final log = j['log'];
    if (log is Map) {
      log.forEach((k, v) {
        if (v is Map) {
          _log[k as String] = v.map((a, b) => MapEntry('$a', '$b'));
        }
      });
    }
    _extras.clear();
    final ex = j['extras'];
    if (ex is Map) {
      ex.forEach((k, v) {
        if (v is List) _extras[k as String] = v.map((e) => '$e').toList();
      });
    }
    for (final p in Prayer.values) {
      final q = j['qada'];
      qada[p.name] = q is Map ? ((q[p.name] as num?)?.toInt() ?? 0) : 0;
    }
    dhikrDaily.clear();
    final dd = j['dhikrDaily'];
    if (dd is Map) {
      dd.forEach((k, v) => dhikrDaily[k as String] = (v as num).toInt());
    }
    adhkarDone.clear();
    final ad = j['adhkarDone'];
    if (ad is Map) {
      ad.forEach((k, v) {
        if (v is List) adhkarDone[k as String] = v.map((e) => '$e').toList();
      });
    }
    lessonsDone
      ..clear()
      ..addAll(((j['lessonsDone'] as List?) ?? const []).map((e) => '$e'));
    bookmarks
      ..clear()
      ..addAll(((j['bookmarks'] as List?) ?? const []).map((e) => '$e'));
    lastRead = j['lastRead'] as String?;
    final view = j['view'];
    if (view is Map) {
      showArabic = (view['arabic'] as bool?) ?? true;
      showTranslit = (view['translit'] as bool?) ?? true;
      showMeaning = (view['meaning'] as bool?) ?? true;
    }
    lastReconciled = j['lastReconciled'] as String?;
    trackingSince = (j['trackingSince'] as num?)?.toInt();
    final t = j['tasbih'];
    if (t is Map) {
      tasbihPreset = (t['preset'] as num?)?.toInt() ?? 0;
      tasbihCount = (t['count'] as num?)?.toInt() ?? 0;
      tasbihTarget = (t['target'] as num?)?.toInt() ?? 33;
    }
    _cache.clear();
  }

  void _changed({bool timesChanged = false, bool reschedule = false}) {
    if (timesChanged) _cache.clear();
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _writeNow);
    if (reschedule) onScheduleNeeded?.call();
  }

  void _writeNow() {
    _prefs?.setString(_storageKey, jsonEncode(toJson()));
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    await _prefs?.setString(_storageKey, jsonEncode(toJson()));
  }

  /// Change settings. Anything that can move prayer times or alerts
  /// recalculates and reschedules automatically.
  void update(void Function(Settings s) change,
      {bool times = false, bool alerts = true}) {
    change(settings);
    _changed(timesChanged: times, reschedule: alerts || times);
  }

  void completeOnboarding() {
    settings.onboarded = true;
    trackingSince = DateTime.now().millisecondsSinceEpoch;
    lastReconciled = dayKey(DateTime.now());
    _changed(reschedule: true);
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  bool importJson(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic> || j['settings'] == null) return false;
      _fromJson(j);
      _changed(timesChanged: true, reschedule: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetAll() async {
    _fromJson(<String, dynamic>{});
    await _prefs?.remove(_storageKey);
    _changed(timesChanged: true, reschedule: true);
  }

  // ------------------------------------------------------------ prayer times

  bool get hasLocation => settings.lat != null && settings.lng != null;

  CalcSettings get calcSettings => CalcSettings(
        method: settings.method,
        asr: settings.asr,
        highLat: settings.highLat,
        customFajr: settings.customFajr,
        customIsha: settings.customIsha,
        offsets: settings.offsets,
      );

  HijriDate hijri(DateTime day) =>
      HijriDate.fromDate(day, adjust: settings.hijriAdjust);

  bool isRamadan(DateTime day) {
    if (settings.ramadanMode == 'on') return true;
    if (settings.ramadanMode == 'off') return false;
    return hijri(day).month == 9;
  }

  DayTimes? timesFor(DateTime day) {
    if (!hasLocation) return null;
    final k = dayKey(day);
    return _cache[k] ??= PrayerCalculator.compute(
      date: dateOnly(day),
      lat: settings.lat!,
      lng: settings.lng!,
      s: calcSettings,
      ramadan: isRamadan(day),
    );
  }

  double? get qiblaBearing => hasLocation
      ? PrayerCalculator.qibla(settings.lat!, settings.lng!)
      : null;

  PrayerSlot? currentSlot(DateTime now) {
    final today = dateOnly(now);
    for (final d in [addDays(today, -1), today]) {
      final t = timesFor(d);
      if (t == null) return null;
      for (final p in Prayer.values) {
        final s = t.start(p);
        final e = t.end(p, settings.ishaEnd);
        if (!now.isBefore(s) && now.isBefore(e)) return PrayerSlot(p, d, s, e);
      }
    }
    return null;
  }

  PrayerSlot? nextSlot(DateTime now) {
    final today = dateOnly(now);
    for (final d in [today, addDays(today, 1)]) {
      final t = timesFor(d);
      if (t == null) return null;
      for (final p in Prayer.values) {
        final s = t.start(p);
        if (s.isAfter(now)) {
          return PrayerSlot(p, d, s, t.end(p, settings.ishaEnd));
        }
      }
    }
    return null;
  }

  // ------------------------------------------------------------- the tracker

  PrayerStatus statusOf(DateTime day, Prayer p) {
    final v = _log[dayKey(day)]?[p.name];
    if (v == null) return PrayerStatus.none;
    return _enumByName(PrayerStatus.values, v, PrayerStatus.none);
  }

  bool hasAnyLog(DateTime day) => _log.containsKey(dayKey(day));

  void _writeStatus(DateTime day, Prayer p, PrayerStatus st) {
    final old = statusOf(day, p);
    if (old == st) return;
    final k = dayKey(day);
    if (st == PrayerStatus.none) {
      _log[k]?.remove(p.name);
      if (_log[k]?.isEmpty ?? false) _log.remove(k);
    } else {
      _log.putIfAbsent(k, () => {})[p.name] = st.name;
    }
    if (old == PrayerStatus.missed) _bumpQada(p, -1);
    if (st == PrayerStatus.missed) _bumpQada(p, 1);
  }

  void setStatus(DateTime day, Prayer p, PrayerStatus st) {
    _writeStatus(day, p, st);
    _changed(reschedule: true);
  }

  /// Marks a prayer as prayed and returns the status that was recorded.
  PrayerStatus markPrayed(DateTime day, Prayer p) {
    final t = timesFor(day);
    var st = PrayerStatus.onTime;
    if (t != null && DateTime.now().isAfter(t.end(p, settings.ishaEnd))) {
      st = PrayerStatus.late;
    }
    setStatus(day, p, st);
    return st;
  }

  bool canMark(DateTime day, Prayer p, DateTime now) {
    final t = timesFor(day);
    if (t == null) return true;
    if (!now.isBefore(t.start(p))) return true;
    if (settings.travel) {
      if (p == Prayer.asr && !now.isBefore(t.dhuhr)) return true;
      if (p == Prayer.isha && !now.isBefore(t.maghrib)) return true;
    }
    return false;
  }

  /// Prayers whose time has ended without being checked off are recorded as
  /// missed (or excused while excused mode is on). Looks back at most 7 days.
  void reconcile() {
    if (!hasLocation || !settings.onboarded) return;
    final now = DateTime.now();
    final today = dateOnly(now);
    var start = addDays(today, -7);
    final last = lastReconciled == null ? null : parseDayKey(lastReconciled!);
    if (last != null && last.isAfter(start)) start = last;
    final since = trackingSince == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(trackingSince!);
    var changed = false;
    for (var d = start; !d.isAfter(today); d = addDays(d, 1)) {
      final t = timesFor(d)!;
      for (final p in Prayer.values) {
        if (statusOf(d, p) != PrayerStatus.none) continue;
        final end = t.end(p, settings.ishaEnd);
        if (end.isAfter(now) || end.isBefore(since)) continue;
        _writeStatus(
            d, p, settings.exempt ? PrayerStatus.exempt : PrayerStatus.missed);
        changed = true;
      }
    }
    final newKey = dayKey(today);
    if (changed || lastReconciled != newKey) {
      lastReconciled = newKey;
      _changed(reschedule: changed);
    }
  }

  void _bumpQada(Prayer p, int delta) {
    final v = (qada[p.name] ?? 0) + delta;
    qada[p.name] = v < 0 ? 0 : v;
  }

  void adjustQada(Prayer p, int delta) {
    _bumpQada(p, delta);
    _changed();
  }

  int get qadaTotal => qada.values.fold(0, (a, b) => a + b);

  List<String> extrasOf(DateTime day) => _extras[dayKey(day)] ?? const [];

  void toggleExtra(DateTime day, String id) {
    final k = dayKey(day);
    final list = List<String>.from(_extras[k] ?? const []);
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    if (list.isEmpty) {
      _extras.remove(k);
    } else {
      _extras[k] = list;
    }
    _changed();
  }

  bool _dayComplete(DateTime d) =>
      Prayer.values.every((p) => statusOf(d, p).settled);

  /// Consecutive days with every prayer prayed or excused.
  int get streak {
    final today = dateOnly(DateTime.now());
    var d = _dayComplete(today) ? today : addDays(today, -1);
    var n = 0;
    while (n < 5000 && _dayComplete(d)) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  /// Share of prayers prayed on time over the last [days] days.
  double onTimeRate({int days = 7}) {
    final today = dateOnly(DateTime.now());
    var counted = 0;
    var onTime = 0;
    for (var i = 0; i < days; i++) {
      final d = addDays(today, -i);
      for (final p in Prayer.values) {
        final s = statusOf(d, p);
        if (s == PrayerStatus.none || s == PrayerStatus.exempt) continue;
        counted++;
        if (s == PrayerStatus.onTime) onTime++;
      }
    }
    return counted == 0 ? 0 : onTime / counted;
  }

  // ---------------------------------------------------------------- dhikr

  int get dhikrToday => dhikrDaily[dayKey(DateTime.now())] ?? 0;

  void addDhikr(int n) {
    final k = dayKey(DateTime.now());
    dhikrDaily[k] = (dhikrDaily[k] ?? 0) + n;
    _changed();
  }

  void setTasbih({int? preset, int? count, int? target}) {
    if (preset != null) tasbihPreset = preset;
    if (count != null) tasbihCount = count;
    if (target != null) tasbihTarget = target;
    _changed();
  }

  bool adhkarDoneOn(DateTime day, String set) =>
      adhkarDone[dayKey(day)]?.contains(set) ?? false;

  void markAdhkarDone(String set) {
    final k = dayKey(DateTime.now());
    final list = adhkarDone.putIfAbsent(k, () => []);
    if (!list.contains(set)) list.add(set);
    _changed(reschedule: set == 'morning' || set == 'evening');
  }

  // --------------------------------------------------------------- learning

  void markLessonDone(String id) {
    if (lessonsDone.add(id)) _changed();
  }

  // ------------------------------------------------------------------ quran

  bool isBookmarked(String ref) => bookmarks.contains(ref);

  void toggleBookmark(String ref) {
    if (!bookmarks.remove(ref)) bookmarks.add(ref);
    _changed();
  }

  void setLastRead(String ref) {
    if (lastRead == ref) return;
    lastRead = ref;
    _changed();
  }

  void setQuranView({bool? arabic, bool? translit, bool? meaning}) {
    if (arabic != null) showArabic = arabic;
    if (translit != null) showTranslit = translit;
    if (meaning != null) showMeaning = meaning;
    _changed();
  }
}
