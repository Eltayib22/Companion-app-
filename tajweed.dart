import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';

/// Transliteration markup: plain text with rule spans like `{Q:d}`.
/// Example: `qul huwal-lāhu aḥa{Q:d}` colours the final d as qalqalah.
class TajweedRule {
  final String code;
  final String name;
  final String arabic;
  final String counts;
  final String description;
  final String lessonId;
  final Color light;
  final Color dark;
  const TajweedRule({
    required this.code,
    required this.name,
    required this.arabic,
    required this.counts,
    required this.description,
    required this.lessonId,
    required this.light,
    required this.dark,
  });

  Color colour(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

const List<TajweedRule> kTajweedRules = [
  TajweedRule(
    code: 'Ml',
    name: 'Madd lāzim (necessary lengthening)',
    arabic: 'مد لازم',
    counts: '6 counts',
    description:
        'A long vowel followed, in the same word, by a letter that carries a permanent sukūn or shaddah. Always held for six counts, as in aḍ-ḍāāllīn.',
    lessonId: 'madd',
    light: Color(0xFF9E1C1C),
    dark: Color(0xFFFF7A7A),
  ),
  TajweedRule(
    code: 'Mw',
    name: 'Madd muttaṣil (joined lengthening)',
    arabic: 'مد واجب متصل',
    counts: '4 or 5 counts',
    description:
        'A long vowel followed by a hamzah in the same word, as in jāʾa and as-samāʾ. Lengthening it is required.',
    lessonId: 'madd',
    light: Color(0xFFD1352B),
    dark: Color(0xFFFF9C8A),
  ),
  TajweedRule(
    code: 'Mj',
    name: 'Madd munfaṣil (separated lengthening)',
    arabic: 'مد جائز منفصل',
    counts: 'usually 4 or 5 counts',
    description:
        'A long vowel at the end of a word, followed by a hamzah at the start of the next word, as in innā anzalnāhu. The same applies to the pronoun hū before a hamzah, as in mālahū akhladah.',
    lessonId: 'madd',
    light: Color(0xFFE0701B),
    dark: Color(0xFFFFB266),
  ),
  TajweedRule(
    code: 'Ma',
    name: 'Madd ʿāriḍ lis-sukūn (lengthening when stopping)',
    arabic: 'مد عارض للسكون',
    counts: '2, 4 or 6 counts',
    description:
        'When you stop on a word, its last letter loses its vowel. A long vowel just before it may then be stretched, as in al-ʿālamīn.',
    lessonId: 'madd',
    light: Color(0xFFA07310),
    dark: Color(0xFFE8C45A),
  ),
  TajweedRule(
    code: 'Mn',
    name: 'Madd līn (soft lengthening)',
    arabic: 'مد لين',
    counts: '2, 4 or 6 counts when stopping',
    description:
        'The soft sounds ay and aw, when you stop on the letter after them, may be stretched, as in quraysh and khawf.',
    lessonId: 'madd',
    light: Color(0xFFA07310),
    dark: Color(0xFFE8C45A),
  ),
  TajweedRule(
    code: 'G',
    name: 'Ghunnah (nasal sound)',
    arabic: 'غنة',
    counts: '2 counts',
    description:
        'A nūn or mīm carrying a shaddah is held with a humming sound through the nose, as in inna and thumma.',
    lessonId: 'ghunnah',
    light: Color(0xFF2E8B3E),
    dark: Color(0xFF79D98A),
  ),
  TajweedRule(
    code: 'I',
    name: 'Ikhfāʾ (hiding)',
    arabic: 'إخفاء',
    counts: '2 counts',
    description:
        'A nūn sākinah or tanwīn before one of 15 letters is not pronounced fully. The tongue does not touch for the n; the sound is hidden with a nasal hum, as in min sharri.',
    lessonId: 'ikhfa',
    light: Color(0xFF0E7C86),
    dark: Color(0xFF5CD0DA),
  ),
  TajweedRule(
    code: 'Is',
    name: 'Ikhfāʾ shafawī (hiding with the lips)',
    arabic: 'إخفاء شفوي',
    counts: '2 counts',
    description:
        'A mīm sākinah before bāʾ is lightly closed with a nasal hum, as in tarmīhim bi-ḥijārah.',
    lessonId: 'meem',
    light: Color(0xFF0E7C86),
    dark: Color(0xFF5CD0DA),
  ),
  TajweedRule(
    code: 'Dg',
    name: 'Idghām with ghunnah (merging with a hum)',
    arabic: 'إدغام بغنة',
    counts: '2 counts',
    description:
        'A nūn sākinah or tanwīn merges into a following ي ن م و with a nasal hum; a mīm sākinah merges into a following mīm the same way. Example: khayrun min becomes khayrum-min.',
    lessonId: 'idgham',
    light: Color(0xFF6B45B0),
    dark: Color(0xFFB79CF0),
  ),
  TajweedRule(
    code: 'Dn',
    name: 'Idghām without ghunnah (full merging)',
    arabic: 'إدغام بلا غنة',
    counts: 'no hum',
    description:
        'A nūn sākinah or tanwīn merges completely into a following ل or ر with no nasal sound, as in waylul-likulli.',
    lessonId: 'idgham',
    light: Color(0xFF5B6B80),
    dark: Color(0xFFA9B8CB),
  ),
  TajweedRule(
    code: 'Dx',
    name: 'Idghām of similar letters',
    arabic: 'إدغام متجانسين',
    counts: 'no hum',
    description:
        'Two letters made in the same place merge into one, as in ʿabadtum, read ʿabattum.',
    lessonId: 'idgham',
    light: Color(0xFF5B6B80),
    dark: Color(0xFFA9B8CB),
  ),
  TajweedRule(
    code: 'B',
    name: 'Iqlāb (changing)',
    arabic: 'إقلاب',
    counts: '2 counts',
    description:
        'A nūn sākinah or tanwīn before bāʾ turns into a lightly closed mīm with a nasal hum, as in min baʿdi, read mim-baʿdi.',
    lessonId: 'iqlab',
    light: Color(0xFFB5245C),
    dark: Color(0xFFF58AB2),
  ),
  TajweedRule(
    code: 'Q',
    name: 'Qalqalah (echo)',
    arabic: 'قلقلة',
    counts: 'a short bounce',
    description:
        'The letters ق ط ب ج د, when they carry a sukūn, are released with a slight bounce. It is strongest when you stop on them, as in al-falaq.',
    lessonId: 'qalqalah',
    light: Color(0xFF1C63C2),
    dark: Color(0xFF7FB2F5),
  ),
];

final Map<String, TajweedRule> kRuleByCode = {
  for (final r in kTajweedRules) r.code: r,
};

class TajweedSegment {
  final String text;
  final String? rule;
  const TajweedSegment(this.text, this.rule);
}

final RegExp _span = RegExp(r'\{([A-Za-z]+):([^}]*)\}');

List<TajweedSegment> parseTajweed(String markup) {
  final out = <TajweedSegment>[];
  var i = 0;
  for (final m in _span.allMatches(markup)) {
    if (m.start > i) out.add(TajweedSegment(markup.substring(i, m.start), null));
    out.add(TajweedSegment(m.group(2)!, m.group(1)));
    i = m.end;
  }
  if (i < markup.length) out.add(TajweedSegment(markup.substring(i), null));
  return out;
}

/// Removes the markup, leaving readable transliteration.
String plainTransliteration(String markup) =>
    parseTajweed(markup).map((s) => s.text).join();

/// Colour-coded transliteration. Tap a coloured part to see its rule.
class TajweedText extends StatefulWidget {
  final String markup;
  final TextStyle? style;
  final void Function(String lessonId)? onOpenLesson;
  const TajweedText(this.markup, {super.key, this.style, this.onOpenLesson});

  @override
  State<TajweedText> createState() => _TajweedTextState();
}

class _TajweedTextState extends State<TajweedText> {
  late List<TajweedSegment> _segments;
  final List<TapGestureRecognizer?> _taps = [];

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(TajweedText old) {
    super.didUpdateWidget(old);
    if (old.markup != widget.markup) {
      _dispose();
      _prepare();
    }
  }

  void _prepare() {
    _segments = parseTajweed(widget.markup);
    for (final s in _segments) {
      final code = s.rule;
      if (code == null || !kRuleByCode.containsKey(code)) {
        _taps.add(null);
      } else {
        _taps.add(TapGestureRecognizer()
          ..onTap = () => showRuleSheet(context, code,
              onOpenLesson: widget.onOpenLesson));
      }
    }
  }

  void _dispose() {
    for (final t in _taps) {
      t?.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coloured = AppState.instance.settings.tajweedColours;
    final base = widget.style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6) ??
        const TextStyle(fontSize: 16, height: 1.6);
    final spans = <InlineSpan>[];
    for (var i = 0; i < _segments.length; i++) {
      final s = _segments[i];
      final rule = s.rule == null ? null : kRuleByCode[s.rule];
      if (rule == null || !coloured) {
        spans.add(TextSpan(text: s.text));
      } else {
        spans.add(TextSpan(
          text: s.text,
          style: TextStyle(
            color: rule.colour(context),
            fontWeight: FontWeight.w800,
          ),
          recognizer: _taps[i],
        ));
      }
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

Future<void> showRuleSheet(BuildContext context, String code,
    {void Function(String lessonId)? onOpenLesson}) {
  final rule = kRuleByCode[code];
  if (rule == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: rule.colour(ctx),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(rule.name,
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${rule.arabic}  ·  ${rule.counts}',
                  style: t.bodyMedium?.copyWith(color: rule.colour(ctx))),
              const SizedBox(height: 12),
              Text(rule.description, style: t.bodyLarge?.copyWith(height: 1.5)),
              if (onOpenLesson != null) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onOpenLesson(rule.lessonId);
                  },
                  child: const Text('Open the lesson'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// A compact legend of all rule colours.
class TajweedLegend extends StatelessWidget {
  final void Function(String lessonId)? onOpenLesson;
  const TajweedLegend({super.key, this.onOpenLesson});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final rules = kTajweedRules.where((r) {
      final key = '${r.light.toARGB32()}';
      return seen.add(key);
    }).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final r in rules)
          ActionChip(
            avatar: CircleAvatar(backgroundColor: r.colour(context), radius: 6),
            label: Text(_shortName(r)),
            onPressed: () => showRuleSheet(context, r.code, onOpenLesson: onOpenLesson),
          ),
      ],
    );
  }

  String _shortName(TajweedRule r) {
    switch (r.code) {
      case 'Ml':
        return 'Madd 6';
      case 'Mw':
        return 'Madd 4–5 (joined)';
      case 'Mj':
        return 'Madd 4–5 (separated)';
      case 'Ma':
        return 'Madd when stopping';
      case 'G':
        return 'Ghunnah';
      case 'I':
        return 'Ikhfāʾ';
      case 'Dg':
        return 'Idghām with hum';
      case 'Dn':
        return 'Idghām, no hum';
      case 'B':
        return 'Iqlāb';
      case 'Q':
        return 'Qalqalah';
      default:
        return r.name;
    }
  }
}
