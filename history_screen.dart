import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/prayer_calc.dart';
import 'theme.dart';
import 'today_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _openDay(DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: AppState.instance,
        builder: (ctx, _) {
          final s = AppState.instance;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text('${longDate(day)}\n${s.hijri(day)}',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                for (final p in Prayer.values)
                  ListTile(
                    leading: Icon(Icons.circle, size: 14, color: statusColour(ctx, s.statusOf(day, p))),
                    title: Text(prayerName(p, day)),
                    subtitle: Text(s.statusOf(day, p).label),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => showStatusSheet(ctx, day, p),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final text = Theme.of(context).textTheme;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Panel(
                child: Row(
                  children: [
                    _Stat('${s.streak}', 'days in a row with every prayer prayed or excused'),
                    _Stat('${(s.onTimeRate(days: 30) * 100).round()}%', 'on time over the last 30 days'),
                  ],
                ),
              ),
              const SectionLabel('Calendar'),
              _MonthHeader(
                month: _month,
                onPrev: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              ),
              _MonthGrid(month: _month, onTap: _openDay),
              const _Legend(),
              const SectionLabel('Make-up prayers (qaḍāʾ)'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Missed prayers are added here automatically. When you make one up, tap minus. You can also add prayers you owe from before you started using the app.',
                  style: text.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              Panel(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final p in Prayer.values)
                      ListTile(
                        title: Text(p.label),
                        subtitle: Text(p.arabic, style: arabicStyle(context, size: 14)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Made one up',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: (s.qada[p.name] ?? 0) > 0 ? () => s.adjustQada(p, -1) : null,
                            ),
                            SizedBox(
                              width: 40,
                              child: Text('${s.qada[p.name] ?? 0}',
                                  textAlign: TextAlign.center,
                                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                            IconButton(
                              tooltip: 'Add one',
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => s.adjustQada(p, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthHeader({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left), tooltip: 'Previous month'),
          Expanded(
            child: Text('${monthName(month.month)} ${month.year}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            onPressed: isCurrent ? null : onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final void Function(DateTime day) onTap;
  const _MonthGrid({required this.month, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1; // Monday first
    final today = dateOnly(DateTime.now());
    final cells = <Widget>[
      for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Center(child: Text(d, style: text.labelMedium)),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
    ];
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      final future = day.isAfter(today);
      final isToday = dayKey(day) == dayKey(today);
      cells.add(InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: future ? null : () => onTap(day),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isToday ? Border.all(color: scheme.primary, width: 1.5) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$d',
                  style: text.bodyMedium?.copyWith(
                      color: future ? scheme.onSurface.withValues(alpha: 0.3) : null)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final p in Prayer.values)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 0.8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: future
                            ? Colors.transparent
                            : statusColour(context, s.statusOf(day, p)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.9,
        children: cells,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final items = [
      PrayerStatus.onTime,
      PrayerStatus.late,
      PrayerStatus.missed,
      PrayerStatus.exempt,
      PrayerStatus.none,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          for (final i in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: statusColour(context, i)),
                const SizedBox(width: 4),
                Text(i.label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}
