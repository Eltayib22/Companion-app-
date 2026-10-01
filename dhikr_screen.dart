import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../data/adhkar.dart';
import 'adhkar_session.dart';
import 'theme.dart';

class DhikrScreen extends StatelessWidget {
  const DhikrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dhikr')),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final today = DateTime.now();
          final sets = [
            (morningAdhkar(), Icons.wb_sunny_outlined),
            (eveningAdhkar(), Icons.nights_stay_outlined),
            (afterPrayerAdhkar(takbir34: s.settings.takbir34), Icons.self_improvement),
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const _Tasbih(),
              const SectionLabel('Adhkar'),
              for (final entry in sets)
                Panel(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => AdhkarSessionScreen(setId: entry.$1.id),
                  )),
                  child: Row(
                    children: [
                      Icon(entry.$2, size: 28, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.$1.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            Text('${entry.$1.when}. ${entry.$1.items.length} adhkar.',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (entry.$1.id != 'after_prayer' && s.adhkarDoneOn(today, entry.$1.id))
                        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      else
                        const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text('${s.dhikrToday} remembrances counted today',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tasbih extends StatelessWidget {
  const _Tasbih();

  void _tap() {
    final s = AppState.instance;
    final next = s.tasbihCount + 1;
    final target = s.tasbihTarget;
    if (target > 0 && next % target == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    s.setTasbih(count: next);
    s.addDhikr(1);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final preset = kTasbihPresets[s.tasbihPreset.clamp(0, kTasbihPresets.length - 1).toInt()];
    final target = s.tasbihTarget;
    final count = s.tasbihCount;
    final inRound = target > 0 ? count % target : count;
    final rounds = target > 0 ? count ~/ target : 0;
    final progress = target > 0 ? inRound / target : 0.0;

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kTasbihPresets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => ChoiceChip(
              label: Text(kTasbihPresets[i].tr),
              selected: s.tasbihPreset == i,
              onSelected: (_) => s.setTasbih(preset: i, count: 0),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(preset.ar, textDirection: TextDirection.rtl, style: arabicStyle(context, size: 30)),
        Text(preset.en, style: text.bodyMedium),
        const SizedBox(height: 20),
        Semantics(
          button: true,
          label: 'Count. $count so far.',
          child: GestureDetector(
            onTap: _tap,
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: target > 0 ? progress : 0,
                      strokeWidth: 10,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  Container(
                    width: 206,
                    height: 206,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.08),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(target > 0 ? '$inRound' : '$count',
                            style: text.displayLarge?.copyWith(
                                fontWeight: FontWeight.w800, color: scheme.primary)),
                        Text(target > 0 ? 'of $target' : 'tap to count', style: text.bodyMedium),
                        if (rounds > 0)
                          Text('$rounds ${rounds == 1 ? 'round' : 'rounds'} done',
                              style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final t in const [33, 99, 100, 0])
                ChoiceChip(
                  label: Text(t == 0 ? 'No target' : '$t'),
                  selected: target == t,
                  onSelected: (_) => s.setTasbih(target: t, count: 0),
                ),
              IconButton(
                tooltip: 'Reset the count',
                onPressed: count == 0 ? null : () => s.setTasbih(count: 0),
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
