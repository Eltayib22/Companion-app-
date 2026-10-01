import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../data/lessons.dart';
import 'lesson_screen.dart';
import 'tajweed.dart';
import 'theme.dart';

void openLesson(BuildContext context, String id) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lessonId: id)));
}

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn tajweed')),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final text = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;
          final done = kLessons.where((l) => s.lessonsDone.contains(l.id)).length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$done of ${kLessons.length} lessons complete',
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: done / kLessons.length,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Start with the foundations if you are new to reading Arabic. Each lesson uses examples from the surahs in the Qurʾān tab, so you can practise straight away. An app is a good start, but reading to a teacher is the surest way to learn.',
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SectionLabel('Tools'),
              Panel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Text('أ ب ت', style: arabicStyle(context, size: 18, color: scheme.primary)),
                      title: const Text('The alphabet'),
                      subtitle: const Text('Letters, sounds and their four forms'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AlphabetScreen())),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.record_voice_over_outlined, color: scheme.primary),
                      title: const Text('Where letters come from'),
                      subtitle: const Text('The five articulation areas (makhārij)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const MakharijScreen())),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.palette_outlined, color: scheme.primary),
                      title: const Text('Colour key'),
                      subtitle: const Text('What each tajweed colour means'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const ColourKeyScreen())),
                    ),
                  ],
                ),
              ),
              for (final group in kLessonGroups) ...[
                SectionLabel(group),
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final l in kLessons.where((l) => l.group == group))
                        ListTile(
                          leading: Icon(
                            s.lessonsDone.contains(l.id) ? Icons.check_circle : Icons.circle_outlined,
                            color: s.lessonsDone.contains(l.id) ? scheme.primary : null,
                          ),
                          title: Text(l.title),
                          subtitle: Text(l.summary),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => openLesson(context, l.id),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  static const _nonJoining = {'ا', 'د', 'ذ', 'ر', 'ز', 'و'};

  void _show(BuildContext context, ArabicLetter l) {
    const t = '\u0640'; // tatweel, to show joined forms
    final joins = !_nonJoining.contains(l.letter);
    final forms = <(String, String)>[
      ('Alone', l.letter),
      ('Start', joins ? '${l.letter}$t' : l.letter),
      ('Middle', joins ? '$t${l.letter}$t' : '$t${l.letter}'),
      ('End', '$t${l.letter}'),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l.letter, style: arabicStyle(ctx, size: 56)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.name, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text('Sound: ${l.sound}', style: text.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l.hint, style: text.bodyLarge),
                const SizedBox(height: 4),
                Text('From: ${kMakharij[l.zone].name}, ${kMakharij[l.zone].where.toLowerCase()}',
                    style: text.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final f in forms)
                      Column(
                        children: [
                          Text(f.$2, style: arabicStyle(ctx, size: 34)),
                          Text(f.$1, style: text.bodySmall),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('The alphabet')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 96,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: kAlphabet.length,
        itemBuilder: (context, i) {
          // Arabic order reads right to left; keep the grid in that direction.
          final l = kAlphabet[i];
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _show(context, l),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.letter, style: arabicStyle(context, size: 30)),
                  Text(l.name, style: text.bodySmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MakharijScreen extends StatelessWidget {
  const MakharijScreen({super.key});

  static const _zoneColours = [
    Color(0xFF8E7BB0),
    Color(0xFFB2465A),
    Color(0xFF2F78C4),
    Color(0xFF1F6F5C),
    Color(0xFFC77B12),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Where letters come from')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Every letter has a fixed point where the sound is made. Moving from the back of the throat to the lips:',
              style: text.bodyLarge,
            ),
          ),
          Panel(child: _PathDiagram(colours: _zoneColours)),
          for (var i = 0; i < kMakharij.length; i++)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: _zoneColours[i], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${kMakharij[i].name}: ${kMakharij[i].where}',
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text(kMakharij[i].arabic, style: arabicStyle(context, size: 18)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(kMakharij[i].letters,
                      textDirection: TextDirection.rtl,
                      style: arabicStyle(context, size: 24, color: _zoneColours[i])),
                  for (final d in kMakharij[i].details)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(d, style: text.bodyMedium),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A simple left-to-right path: throat, tongue (back to tip), lips, with the
/// nasal passage above and the open mouth space spanning underneath.
class _PathDiagram extends StatelessWidget {
  final List<Color> colours;
  const _PathDiagram({required this.colours});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget band(int zone, String label, String letters, int flex) => Expanded(
          flex: flex,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: colours[zone].withValues(alpha: 0.16),
              border: Border(top: BorderSide(color: colours[zone], width: 3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(label, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(letters,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: arabicStyle(context, size: 18, color: colours[zone])),
              ],
            ),
          ),
        );
    return Column(
      children: [
        Row(children: [
          const Spacer(flex: 5),
          band(4, 'Nose', 'غُنّة', 3),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          band(1, 'Throat', 'ء ه ع ح غ خ', 3),
          band(2, 'Tongue', 'ق ك ج ش ي ض ل ن ر ...', 4),
          band(3, 'Lips', 'ف ب م و', 2),
        ]),
        const SizedBox(height: 6),
        Row(children: [band(0, 'Open mouth space: the long vowels', 'ا و ي', 1)]),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Back', style: text.bodySmall),
            const Expanded(child: Divider(indent: 8, endIndent: 8)),
            const Icon(Icons.arrow_forward, size: 16),
            const SizedBox(width: 4),
            Text('Front', style: text.bodySmall),
          ],
        ),
      ],
    );
  }
}

class ColourKeyScreen extends StatelessWidget {
  const ColourKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Colour key')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'In the transliteration, coloured letters show where a tajweed rule applies. Tap any coloured letter while reading to see its rule.',
              style: text.bodyLarge,
            ),
          ),
          for (final r in kTajweedRules)
            Panel(
              onTap: () => openLesson(context, r.lessonId),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(color: r.colour(context), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text(r.counts, style: text.bodySmall?.copyWith(color: r.colour(context))),
                        const SizedBox(height: 4),
                        Text(r.description, style: text.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
