import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_state.dart';
import 'format.dart';
import 'prayer_calc.dart';

class _Planned {
  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String kind; // pre, adhan, repeat, closing, adhkar, refresh
  final String payload;
  const _Planned(
      this.id, this.at, this.title, this.body, this.kind, this.payload);
}

/// How alerts work:
/// * At each prayer time an alert fires with an "I've prayed" button.
/// * It repeats every few minutes until the prayer is checked off, or until
///   the time for that prayer ends, with a final "time is ending" warning.
/// * Checking a prayer off (in the app or from the notification) cancels
///   the remaining alerts for it and clears the ones already showing.
/// * Alerts are planned a few days ahead and re-planned every time the app
///   opens. iOS keeps at most 64 pending alerts, so on iPhone the plan is
///   shorter and ends with a reminder to open the app.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const actionPrayed = 'mark_prayed';
  static const _iosLimit = 58;
  static const _androidLimit = 300;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _launchHandled = false;
  Timer? _debounce;
  bool _busy = false;
  bool _again = false;

  /// UI listens to this to open a screen after a notification is tapped.
  /// Values: 'today', 'prayed:<prayer>', 'adhkar:<set>'.
  final ValueNotifier<String?> openRequest = ValueNotifier<String?>(null);

  /// Summary for the settings screen.
  final ValueNotifier<String> status = ValueNotifier<String>('Not scheduled yet');

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          'prayer_alert',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              actionPrayed,
              'I’ve prayed',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );
    try {
      await _plugin.initialize(
        settings: InitializationSettings(android: android, iOS: darwin),
        onDidReceiveNotificationResponse: _onResponse,
      );
      _ready = true;
    } catch (e) {
      status.value = 'Notifications could not start: $e';
    }
    AppState.instance.onScheduleNeeded = scheduleSoon;
  }

  // ---------------------------------------------------------- responses

  void _onResponse(NotificationResponse r) => _handle(r.payload, r.actionId);

  /// Handles the notification that launched the app, once per launch.
  Future<void> handleLaunch() async {
    if (!_ready || _launchHandled) return;
    _launchHandled = true;
    try {
      final d = await _plugin.getNotificationAppLaunchDetails();
      final r = d?.notificationResponse;
      if ((d?.didNotificationLaunchApp ?? false) && r != null) {
        _handle(r.payload, r.actionId);
      }
    } catch (_) {}
  }

  void _handle(String? payload, String? actionId) {
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    if (parts.first == 'prayer' && parts.length == 3) {
      final day = parseDayKey(parts[1]);
      Prayer? prayer;
      for (final p in Prayer.values) {
        if (p.name == parts[2]) prayer = p;
      }
      if (day == null || prayer == null) return;
      if (actionId == actionPrayed) {
        final s = AppState.instance;
        final current = s.statusOf(day, prayer);
        if (current == PrayerStatus.none || current == PrayerStatus.missed) {
          s.markPrayed(day, prayer);
        }
        openRequest.value = 'prayed:${prayer.name}';
      } else {
        openRequest.value = 'today';
      }
    } else if (parts.first == 'adhkar' && parts.length >= 2) {
      openRequest.value = 'adhkar:${parts[1]}';
    }
  }

  // --------------------------------------------------------- permissions

  Future<bool> requestPermissions() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        final a = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final ok = await a?.requestNotificationsPermission() ?? true;
        final exact = await a?.canScheduleExactNotifications() ?? true;
        if (!exact) await a?.requestExactAlarmsPermission();
        return ok;
      }
      if (Platform.isIOS) {
        final i = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await i?.requestPermissions(alert: true, badge: false, sound: true) ??
            false;
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
    return true;
  }

  Future<bool> exactAlarmsAllowed() async {
    if (!_ready || !Platform.isAndroid) return true;
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await a?.canScheduleExactNotifications() ?? true;
  }

  Future<void> openExactAlarmSettings() async {
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await a?.requestExactAlarmsPermission();
  }

  Future<void> showTest() async {
    if (!_ready) return;
    Future<void> show(bool defaultSound) => _plugin.show(
          id: 999998,
          title: 'Test alert',
          body: 'This is how a prayer alert looks and sounds.',
          notificationDetails: _details('adhan', defaultSound: defaultSound),
          payload: 'test',
        );
    try {
      await show(false);
    } catch (_) {
      await show(true);
    }
  }

  // ---------------------------------------------------------- scheduling

  void scheduleSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), reschedule);
  }

  Future<void> reschedule() async {
    if (!_ready) return;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    try {
      await _plugin.cancelAllPendingNotifications();
      await _clearShownForSettled();
      final plan = _buildPlan(DateTime.now());
      var mode = AndroidScheduleMode.exactAllowWhileIdle;
      if (!await exactAlarmsAllowed()) {
        mode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
      var soundMissing = false;
      Future<void> schedule(_Planned n, NotificationDetails details) =>
          _plugin.zonedSchedule(
            id: n.id,
            title: n.title,
            body: n.body,
            scheduledDate: tz.TZDateTime.from(n.at.toUtc(), tz.UTC),
            notificationDetails: details,
            androidScheduleMode: mode,
            payload: n.payload,
          );
      for (final n in plan) {
        try {
          await schedule(n, _details(n.kind, defaultSound: soundMissing));
        } catch (e) {
          // Usually the adhan file was not added to the build; fall back to
          // the normal sound rather than losing the alert.
          if (n.kind == 'adhan' && AppState.instance.settings.customSound && !soundMissing) {
            soundMissing = true;
            await schedule(n, _details(n.kind, defaultSound: true));
          } else {
            rethrow;
          }
        }
      }
      final alerts = plan.where((n) => n.kind != 'refresh').toList();
      if (alerts.isEmpty) {
        status.value = 'No alerts scheduled';
      } else {
        final last = alerts.last.at;
        status.value =
            '${alerts.length} alerts scheduled, through ${shortDate(last)} ${clock(last, h24: AppState.instance.use24h)}'
            '${mode == AndroidScheduleMode.inexactAllowWhileIdle ? '. Exact timing is off, so alerts may arrive a few minutes late.' : ''}'
            '${soundMissing ? '. Your adhan file is not in this build, so the normal sound is used.' : ''}';
      }
    } catch (e) {
      status.value = 'Scheduling failed: $e';
      debugPrint('Scheduling failed: $e');
    } finally {
      _busy = false;
      if (_again) {
        _again = false;
        unawaited(reschedule());
      }
    }
  }

  int _epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  /// id = dayCode * 1000 + slot * 100 + seq.
  /// slot 0-4 = prayers, 5 = morning adhkar, 6 = evening adhkar, 9 = refresh.
  int _id(DateTime day, int slot, int seq) =>
      (_epochDay(day) % 400) * 1000 + slot * 100 + seq;

  Future<void> _clearShownForSettled() async {
    try {
      final active = await _plugin.getActiveNotifications();
      if (active.isEmpty) return;
      final s = AppState.instance;
      final today = dateOnly(DateTime.now());
      final days = <int, DateTime>{
        for (var i = -2; i <= 1; i++)
          _epochDay(addDays(today, i)) % 400: addDays(today, i),
      };
      for (final a in active) {
        final id = a.id;
        if (id == null) continue;
        final day = days[id ~/ 1000];
        if (day == null) continue;
        final slot = (id % 1000) ~/ 100;
        if (slot > 4) continue;
        if (s.statusOf(day, Prayer.values[slot]) != PrayerStatus.none) {
          await _plugin.cancel(id: id);
        }
      }
    } catch (_) {
      // Not supported on very old OS versions; nothing else to do.
    }
  }

  List<_Planned> _buildPlan(DateTime now) {
    final s = AppState.instance;
    final st = s.settings;
    final out = <_Planned>[];
    if (!s.hasLocation || !st.onboarded) return out;
    final h24 = s.use24h;
    final today = dateOnly(now);
    final soon = now.add(const Duration(seconds: 5));

    for (var i = -1; i <= 3; i++) {
      final day = addDays(today, i);
      final t = s.timesFor(day)!;

      if (st.alertsOn && !st.exempt) {
        for (final p in Prayer.values) {
          if (!(st.prayerAlerts[p] ?? true)) continue;
          if (s.statusOf(day, p) != PrayerStatus.none) continue;
          final start = t.start(p);
          final end = t.end(p, st.ishaEnd);
          if (!end.isAfter(now)) continue;
          final name = prayerName(p, day);
          final payload = 'prayer|${dayKey(day)}|${p.name}';

          if (st.preReminder > 0) {
            out.add(_Planned(
              _id(day, p.index, 0),
              start.subtract(Duration(minutes: st.preReminder)),
              '$name in ${st.preReminder} minutes',
              'Time to make wudu and get ready. $name begins at ${clock(start, h24: h24)}.',
              'pre',
              payload,
            ));
          }
          out.add(_Planned(
            _id(day, p.index, 1),
            start,
            'It’s time for $name',
            'Tap “I’ve prayed” when you’re done. Reminders continue until you check it off.',
            'adhan',
            payload,
          ));

          final closeAt = st.closingWarning > 0
              ? end.subtract(Duration(minutes: st.closingWarning))
              : null;
          final stopBefore = (closeAt ?? end).subtract(const Duration(minutes: 2));
          for (var k = 1; k <= 90; k++) {
            if (st.maxRepeats > 0 && k > st.maxRepeats) break;
            final at = start.add(Duration(minutes: st.repeatEvery * k));
            if (!at.isBefore(stopBefore)) break;
            out.add(_Planned(
              _id(day, p.index, 1 + k),
              at,
              '$name isn’t checked off yet',
              'Reminder $k. The time for $name ends at ${clock(end, h24: h24)}.',
              'repeat',
              payload,
            ));
          }
          if (closeAt != null && closeAt.isAfter(start)) {
            out.add(_Planned(
              _id(day, p.index, 98),
              closeAt,
              '$name ends in ${st.closingWarning} minutes',
              'If you haven’t prayed yet, now is the time. Tap “I’ve prayed” to stop the reminders.',
              'closing',
              payload,
            ));
          }
        }
      }

      if (st.morningAdhkarReminder && !s.adhkarDoneOn(day, 'morning')) {
        var at = t.fajr.add(const Duration(minutes: 20));
        final latest = t.sunrise.subtract(const Duration(minutes: 10));
        if (at.isAfter(latest)) at = latest;
        out.add(_Planned(_id(day, 5, 0), at, 'Morning adhkar',
            'A few minutes of remembrance to begin the day.', 'adhkar', 'adhkar|morning'));
      }
      if (st.eveningAdhkarReminder && !s.adhkarDoneOn(day, 'evening')) {
        var at = t.asr.add(const Duration(minutes: 30));
        final latest = t.maghrib.subtract(const Duration(minutes: 15));
        if (at.isAfter(latest)) at = latest;
        out.add(_Planned(_id(day, 6, 0), at, 'Evening adhkar',
            'A few minutes of remembrance before sunset.', 'adhkar', 'adhkar|evening'));
      }
    }

    final plan = out.where((n) => n.at.isAfter(soon)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final limit = Platform.isIOS ? _iosLimit : _androidLimit;
    List<_Planned> kept;
    DateTime? refreshAt;
    if (plan.length <= limit) {
      kept = plan;
      if (kept.isNotEmpty) refreshAt = kept.last.at;
    } else {
      // Keep the start-of-prayer alerts and final warnings for the next two
      // days, then fill the remaining room with the soonest repeats.
      final horizon = now.add(const Duration(hours: 48));
      final essential = plan
          .where((n) => n.kind != 'repeat' && n.at.isBefore(horizon))
          .take(limit)
          .toList();
      final repeats =
          plan.where((n) => n.kind == 'repeat').take(limit - essential.length).toList();
      kept = [...essential, ...repeats]..sort((a, b) => a.at.compareTo(b.at));
      refreshAt = repeats.isNotEmpty
          ? repeats.last.at
          : (kept.isNotEmpty ? kept.last.at : null);
    }
    if (refreshAt != null) {
      final at = refreshAt.add(const Duration(minutes: 1));
      kept.add(_Planned(
        _id(at, 9, 0),
        at,
        'Open Salah Companion',
        'Open the app so your prayer reminders keep repeating.',
        'refresh',
        'refresh',
      ));
    }
    return kept;
  }

  NotificationDetails _details(String kind, {bool defaultSound = false}) {
    final st = AppState.instance.settings;
    final useAdhan = st.customSound && !defaultSound;
    final withAction =
        kind == 'adhan' || kind == 'repeat' || kind == 'closing';
    final actions = withAction
        ? <AndroidNotificationAction>[
            AndroidNotificationAction(
              actionPrayed,
              'I’ve prayed',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ]
        : null;

    AndroidNotificationDetails android;
    switch (kind) {
      case 'adhan':
        android = useAdhan
            ? AndroidNotificationDetails(
                'prayer_time_adhan',
                'Prayer time (adhan sound)',
                channelDescription: 'The alert at the start of each prayer, using your adhan recording.',
                importance: Importance.max,
                priority: Priority.high,
                category: AndroidNotificationCategory.alarm,
                playSound: true,
                sound: const RawResourceAndroidNotificationSound('adhan'),
                actions: actions,
              )
            : AndroidNotificationDetails(
                'prayer_time',
                'Prayer time',
                channelDescription: 'The alert at the start of each prayer.',
                importance: Importance.max,
                priority: Priority.high,
                category: AndroidNotificationCategory.alarm,
                actions: actions,
              );
        break;
      case 'repeat':
      case 'closing':
        android = AndroidNotificationDetails(
          'prayer_reminders',
          'Prayer reminders',
          channelDescription: 'Repeats until the prayer is checked off.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: actions,
        );
        break;
      case 'pre':
        android = const AndroidNotificationDetails(
          'prayer_heads_up',
          'Before prayer',
          channelDescription: 'A heads-up a few minutes before each prayer.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
        break;
      default:
        android = const AndroidNotificationDetails(
          'adhkar_reminders',
          'Adhkar and app reminders',
          channelDescription: 'Morning and evening adhkar, and reminders to open the app.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
    }

    final darwin = DarwinNotificationDetails(
      categoryIdentifier: withAction ? 'prayer_alert' : null,
      threadIdentifier: kind == 'adhkar' ? 'adhkar' : 'prayer',
      sound: kind == 'adhan' && useAdhan ? 'adhan.caf' : null,
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    );
    return NotificationDetails(android: android, iOS: darwin);
  }
}
