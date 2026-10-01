import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/prayer_calc.dart';
import 'adhkar_session.dart';
import 'history_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

void showCheckedOffSnack(BuildContext context, Prayer p, PrayerStatus st) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(st == PrayerStatus.late
        ? '${p.label} recorded as prayed late. Reminders stopped.'
        : '${p.label} checked off. Reminders stopped.'),
    action: SnackBarAction(
      label: 'After-prayer adhkar',
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const AdhkarSessionScreen(setId: 'after_prayer'),
      )),
    ),
    duration: const Duration(seconds: 6),
  ));
}

Future<void> showStatusSheet(BuildContext context, DateTime day, Prayer p) {
  final s = AppState.instance;
  final current = s.statusOf(day, p);
  const options = [
    (PrayerStatus.onTime, Icons.check_circle, 'Prayed on time', null),
    (PrayerStatus.late, Icons.schedule, 'Prayed late', 'Made up after its time'),
    (PrayerStatus.missed, Icons.cancel_outlined, 'Missed', 'Adds one to your make-up count'),
    (PrayerStatus.exempt, Icons.do_not_disturb_on_outlined, 'Excused', 'For example, during menstruation'),
    (PrayerStatus.none, Icons.radio_button_unchecked, 'Not marked', 'Alerts resume if its time has not ended'),
  ];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('${prayerName(p, day)}, ${shortDate(day)}',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (final o in options)
            ListTile(
              leading: Icon(o.$2, color: statusColour(ctx, o.$1)),
              title: Text(o.$3),
              subtitle: o.$4 == null ? null : Text(o.$4!),
              trailing: current == o.$1 ? const Icon(Icons.check) : null,
              onTap: () {
                s.setStatus(day, p, o.$1);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      final now = DateTime.now();
      if (dayKey(now) != dayKey(_now)) AppState.instance.reconcile();
      setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _onCheck(DateTime day, Prayer p) {
    final s = AppState.instance;
    final st = s.statusOf(day, p);
    if (st != PrayerStatus.none) {
      showStatusSheet(context, day, p);
      return;
    }
    final now = DateTime.now();
    if (!s.canMark(day, p, now)) {
      final t = s.timesFor(day)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${prayerName(p, day)} begins at ${clock(t.start(p), h24: s.use24h)}.'),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    final recorded = s.markPrayed(day, p);
    showCheckedOffSnack(context, p, recorded);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        if (!s.hasLocation) return _NoLocation();
        final now = _now;
        final today = dateOnly(now);
        final t = s.timesFor(today)!;
        final current = s.currentSlot(now);
        final next = s.nextSlot(now);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SkyHeader(
                  now: now,
                  current: current,
                  next: next,
                  onCheck: _onCheck,
                ),
              ),
              if (t.approximate)
                const SliverToBoxAdapter(
                  child: _Banner(
                    icon: Icons.info_outline,
                    text: 'The sun does not rise or set normally here today, so these times are an approximation. Please follow your local mosque.',
                  ),
                ),
              if (s.settings.exempt)
                SliverToBoxAdapter(
                  child: _Banner(
                    icon: Icons.do_not_disturb_on_outlined,
                    text: 'Excused mode is on. Alerts are paused, and prayers are recorded as excused rather than missed.',
                    action: 'Turn off',
                    onAction: () => s.update((x) => x.exempt = false),
                  ),
                ),
              if (s.settings.travel)
                SliverToBoxAdapter(
                  child: _Banner(
                    icon: Icons.luggage_outlined,
                    text: 'Travel mode is on. Dhuhr, ʿAṣr and ʿIshāʾ may be shortened to two rakʿahs. ʿAṣr can be checked off from Dhuhr time and ʿIshāʾ from Maghrib time if you combine.',
                    action: 'Turn off',
                    onAction: () => s.update((x) => x.travel = false),
                  ),
                ),
              SliverToBoxAdapter(
                child: _Timeline(day: today, times: t, now: now, current: current, onCheck: _onCheck),
              ),
              if (s.isRamadan(today)) SliverToBoxAdapter(child: _RamadanPanel(times: t)),
              if (s.settings.trackSunnah || s.isRamadan(today))
                SliverToBoxAdapter(child: _Extras(day: today)),
              SliverToBoxAdapter(child: _Stats()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

class _NoLocation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text('Set your location to see prayer times',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen())),
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkyHeader extends StatelessWidget {
  final DateTime now;
  final PrayerSlot? current;
  final PrayerSlot? next;
  final void Function(DateTime day, Prayer p) onCheck;
  const _SkyHeader({required this.now, required this.current, required this.next, required this.onCheck});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final h24 = s.use24h;
    final colours = skyColours(current?.prayer, beforeNoon: now.hour < 12);
    final top = MediaQuery.paddingOf(context).top;
    final text = Theme.of(context).textTheme;
    const white = Colors.white;
    final soft = Colors.white.withValues(alpha: 0.78);
    final hijri = s.hijri(now);
    final cur = current;
    final curStatus = cur == null ? null : s.statusOf(cur.day, cur.prayer);

    Widget headline;
    if (cur != null) {
      final name = prayerName(cur.prayer, cur.day);
      headline = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Now', style: text.titleMedium?.copyWith(color: soft)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(name,
                  style: text.displayMedium?.copyWith(
                      color: white, fontWeight: FontWeight.w800, height: 1.05)),
              const SizedBox(width: 12),
              Text(cur.prayer.arabic,
                  style: arabicStyle(context, size: 26, color: soft)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Time remaining: ${duration(cur.end.difference(now))}, until ${clock(cur.end, h24: h24)}',
              style: text.bodyLarge?.copyWith(color: soft)),
          const SizedBox(height: 16),
          if (curStatus == PrayerStatus.none)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: white,
                foregroundColor: colours.first,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              onPressed: () => onCheck(cur.day, cur.prayer),
              icon: const Icon(Icons.check),
              label: Text('I’ve prayed $name'),
            )
          else
            Row(
              children: [
                const Icon(Icons.check_circle, color: white),
                const SizedBox(width: 8),
                Text('$name ${curStatus == PrayerStatus.exempt ? 'excused' : 'checked off'}',
                    style: text.titleMedium?.copyWith(color: white, fontWeight: FontWeight.w600)),
              ],
            ),
        ],
      );
    } else {
      final n = next;
      headline = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next', style: text.titleMedium?.copyWith(color: soft)),
          if (n != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(prayerName(n.prayer, n.day),
                    style: text.displayMedium?.copyWith(
                        color: white, fontWeight: FontWeight.w800, height: 1.05)),
                const SizedBox(width: 12),
                Text(n.prayer.arabic, style: arabicStyle(context, size: 26, color: soft)),
              ],
            ),
          if (n != null)
            Text('in ${duration(n.start.difference(now))}, at ${clock(n.start, h24: h24)}',
                style: text.bodyLarge?.copyWith(color: soft)),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colours,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 8, 12, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(longDate(now),
                        style: text.titleSmall?.copyWith(color: white, fontWeight: FontWeight.w700)),
                    Text('$hijri${s.settings.place.isEmpty ? '' : '\n${s.settings.place}'}',
                        style: text.bodySmall?.copyWith(color: soft)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Qibla',
                color: white,
                icon: const Icon(Icons.explore_outlined),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const QiblaScreen())),
              ),
              IconButton(
                tooltip: 'History and make-up prayers',
                color: white,
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HistoryScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),
          headline,
          if (cur != null && next != null) ...[
            const SizedBox(height: 16),
            Text('Next: ${prayerName(next!.prayer, next!.day)} at ${clock(next!.start, h24: h24)}',
                style: text.bodyMedium?.copyWith(color: soft)),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final DateTime day;
  final DayTimes times;
  final DateTime now;
  final PrayerSlot? current;
  final void Function(DateTime day, Prayer p) onCheck;
  const _Timeline({
    required this.day,
    required this.times,
    required this.now,
    required this.current,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final rows = <Widget>[];
    for (final p in Prayer.values) {
      rows.add(_PrayerRow(
        day: day,
        prayer: p,
        time: times.start(p),
        isCurrent: current != null && current!.prayer == p && dayKey(current!.day) == dayKey(day),
        isPast: times.end(p, s.settings.ishaEnd).isBefore(now),
        onCheck: onCheck,
      ));
      if (p == Prayer.fajr) {
        rows.add(_SunriseRow(time: times.sunrise));
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Column(children: rows),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final DateTime day;
  final Prayer prayer;
  final DateTime time;
  final bool isCurrent;
  final bool isPast;
  final void Function(DateTime day, Prayer p) onCheck;
  const _PrayerRow({
    required this.day,
    required this.prayer,
    required this.time,
    required this.isCurrent,
    required this.isPast,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final status = s.statusOf(day, prayer);
    final colour = statusColour(context, status);
    final dim = isPast && status == PrayerStatus.none;
    final name = prayerName(prayer, day);

    IconData icon;
    switch (status) {
      case PrayerStatus.onTime:
        icon = Icons.check_circle;
        break;
      case PrayerStatus.late:
        icon = Icons.schedule;
        break;
      case PrayerStatus.missed:
        icon = Icons.cancel;
        break;
      case PrayerStatus.exempt:
        icon = Icons.do_not_disturb_on;
        break;
      case PrayerStatus.none:
        icon = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrent ? scheme.primary.withValues(alpha: 0.10) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: scheme.primary.withValues(alpha: 0.5), width: 1.5) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onCheck(day, prayer),
        onLongPress: () => showStatusSheet(context, day, prayer),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  clock(time, h24: s.use24h),
                  style: text.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                    color: dim ? scheme.onSurface.withValues(alpha: 0.45) : null,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: dim ? scheme.onSurface.withValues(alpha: 0.55) : null,
                        )),
                    if (status != PrayerStatus.none)
                      Text(status.label, style: text.bodySmall?.copyWith(color: colour)),
                  ],
                ),
              ),
              Text(prayer.arabic, style: arabicStyle(context, size: 18, color: scheme.onSurface.withValues(alpha: 0.5))),
              IconButton(
                iconSize: 30,
                tooltip: status == PrayerStatus.none ? 'Check off $name' : 'Change status',
                icon: Icon(icon, color: colour),
                onPressed: () => onCheck(day, prayer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SunriseRow extends StatelessWidget {
  final DateTime time;
  const _SunriseRow({required this.time});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(clock(time, h24: AppState.instance.use24h),
                style: text.bodyMedium?.copyWith(
                    color: muted, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          Icon(Icons.wb_sunny_outlined, size: 16, color: muted),
          const SizedBox(width: 6),
          Text('Sunrise, the end of Fajr', style: text.bodyMedium?.copyWith(color: muted)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const _Banner({required this.icon, required this.text, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: scheme.secondary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.secondary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
            if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ),
      ),
    );
  }
}

class _RamadanPanel extends StatelessWidget {
  final DayTimes times;
  const _RamadanPanel({required this.times});

  @override
  Widget build(BuildContext context) {
    final h24 = AppState.instance.use24h;
    final text = Theme.of(context).textTheme;
    Widget cell(String label, DateTime t, IconData icon) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(label, style: text.bodyMedium),
              ]),
              Text(clock(t, h24: h24),
                  style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Ramaḍān'),
        Panel(
          child: Row(children: [
            cell('Suhoor ends', times.fajr, Icons.nights_stay_outlined),
            cell('Ifṭār', times.maghrib, Icons.restaurant_outlined),
          ]),
        ),
      ],
    );
  }
}

class _Extras extends StatelessWidget {
  final DateTime day;
  const _Extras({required this.day});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final done = s.extrasOf(day);
    final items = <(String, String)>[
      if (s.isRamadan(day)) ('fast', 'Fasting'),
      if (s.isRamadan(day)) ('tarawih', 'Tarāwīḥ'),
      if (s.settings.trackSunnah) ...[
        ('fajr_sunnah', 'Fajr sunnah'),
        ('dhuhr_sunnah', 'Dhuhr sunnah'),
        ('maghrib_sunnah', 'Maghrib sunnah'),
        ('isha_sunnah', 'ʿIshāʾ sunnah'),
        ('witr', 'Witr'),
        ('duha', 'Ḍuḥā'),
        ('tahajjud', 'Tahajjud'),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Also today'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in items)
                FilterChip(
                  label: Text(i.$2),
                  selected: done.contains(i.$1),
                  onSelected: (_) => s.toggleExtra(day, i.$1),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final text = Theme.of(context).textTheme;
    Widget stat(String value, String label) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: text.bodySmall),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Your prayers'),
        Panel(
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen())),
          child: Row(
            children: [
              stat('${s.streak}', s.streak == 1 ? 'day in a row' : 'days in a row'),
              stat('${(s.onTimeRate() * 100).round()}%', 'on time, last 7 days'),
              stat('${s.qadaTotal}', 'to make up'),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}
