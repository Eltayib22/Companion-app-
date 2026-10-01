import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../data/quran.dart';
import 'learn_screen.dart';
import 'tajweed.dart';
import 'theme.dart';

void openSurah(BuildContext context, int number, {int? ayah}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => SurahScreen(number: number, initialAyah: ayah),
  ));
}

(int, int)? _parseRef(String ref) {
  final parts = ref.split(':');
  if (parts.length != 2) return null;
  final s = int.tryParse(parts[0]);
  final a = int.tryParse(parts[1]);
  if (s == null || a == null) return null;
  return (s, a);
}

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qurʾān')),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final text = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;
          final last = s.lastRead == null ? null : _parseRef(s.lastRead!);
          final lastSurah = last == null ? null : surahByNumber(last.$1);
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (last != null && lastSurah != null)
                Panel(
                  onTap: () => openSurah(context, last.$1, ayah: last.$2),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_fill, size: 36, color: scheme.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Continue reading', style: text.bodySmall),
                            Text('${lastSurah.name}, ayah ${last.$2}',
                                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const _HowToRead(),
              if (s.bookmarks.isNotEmpty) ...[
                const SectionLabel('Bookmarks'),
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final b in s.bookmarks)
                        if (_parseRef(b) case final r?)
                          ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text('${surahByNumber(r.$1)?.name ?? 'Surah ${r.$1}'}, ayah ${r.$2}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => openSurah(context, r.$1, ayah: r.$2),
                          ),
                    ],
                  ),
                ),
              ],
              const SectionLabel('Surahs'),
              Panel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final surah in kSurahs) ...[
                      ListTile(
                        leading: _NumberBadge(surah.number),
                        title: Text(surah.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${surah.meaning}. ${surah.ayat.length} ayat'),
                        trailing: Text(surah.arabicName, style: arabicStyle(context, size: 20)),
                        onTap: () => openSurah(context, surah.number),
                      ),
                      if (surah != kSurahs.last) const Divider(indent: 72),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'This section covers Al-Fātiḥah and the last 20 surahs, the ones most often recited in prayer. Transliteration is a bridge to reading the Arabic, not a replacement for it. Please check against a printed muṣḥaf and, ideally, a teacher.',
                  style: text.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  const _NumberBadge(this.number);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$number',
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
    );
  }
}

class _HowToRead extends StatelessWidget {
  const _HowToRead();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Panel(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('How to read the transliteration'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A line over a vowel (ā, ī, ū) means it is long: two counts. ʿ is the letter ʿayn, ʾ is a hamzah (a catch in the throat). A dot under a letter (ḥ, ṣ, ḍ, ṭ, ẓ) marks the heavier Arabic sound. kh, gh, sh, th and dh are single Arabic letters. A doubled letter is held for its shaddah. Ayat are written as you would read them when stopping at the end.',
              style: text.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Text('Colours', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TajweedLegend(onOpenLesson: (id) => openLesson(context, id)),
          ],
        ),
      ),
    );
  }
}

class SurahScreen extends StatefulWidget {
  final int number;
  final int? initialAyah;
  const SurahScreen({super.key, required this.number, this.initialAyah});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  final Map<int, GlobalKey> _keys = {};
  final Set<int> _revealed = {};
  bool _memorise = false;

  @override
  void initState() {
    super.initState();
    final target = widget.initialAyah;
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[target]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 400), alignment: 0.1);
        }
      });
    }
  }

  void _options() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: AppState.instance,
        builder: (ctx, _) {
          final s = AppState.instance;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Arabic'),
                    value: s.showArabic,
                    onChanged: (v) => s.setQuranView(arabic: v),
                  ),
                  SwitchListTile(
                    title: const Text('Transliteration'),
                    value: s.showTranslit,
                    onChanged: (v) => s.setQuranView(translit: v),
                  ),
                  SwitchListTile(
                    title: const Text('Meaning in English'),
                    value: s.showMeaning,
                    onChanged: (v) => s.setQuranView(meaning: v),
                  ),
                  SwitchListTile(
                    title: const Text('Tajweed colours'),
                    value: s.settings.tajweedColours,
                    onChanged: (v) => s.update((x) => x.tajweedColours = v, alerts: false),
                  ),
                  SwitchListTile(
                    title: const Text('Memorise mode'),
                    subtitle: const Text('Hide each ayah until you tap it'),
                    value: _memorise,
                    onChanged: (v) {
                      setState(() {
                        _memorise = v;
                        _revealed.clear();
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    title: const Text('Arabic text size'),
                    subtitle: Slider(
                      value: s.settings.arabicScale,
                      min: 0.8,
                      max: 1.8,
                      divisions: 10,
                      label: '${(s.settings.arabicScale * 100).round()}%',
                      onChanged: (v) => s.update((x) => x.arabicScale = v, alerts: false),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _listen() async {
    final uri = Uri.parse('https://quran.com/${widget.number}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surah = surahByNumber(widget.number);
    if (surah == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Surah not found.')));
    }
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(surah.name),
            actions: [
              IconButton(
                tooltip: 'Listen to a recitation on quran.com',
                onPressed: _listen,
                icon: const Icon(Icons.headphones_outlined),
              ),
              IconButton(
                tooltip: 'Display options',
                onPressed: _options,
                icon: const Icon(Icons.text_fields),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            'Surah ${surah.number}. ${surah.meaning}. ${surah.ayat.length} ayat.',
                            style: text.bodyMedium),
                      ),
                      Text(surah.arabicName, style: arabicStyle(context, size: 26, color: scheme.primary)),
                    ],
                  ),
                ),
                if (!surah.basmalahIsAyah)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      children: [
                        if (s.showArabic)
                          Text(kBasmalah.ar,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: arabicStyle(context, size: 26)),
                        if (s.showTranslit)
                          TajweedText(kBasmalah.tr,
                              style: text.titleMedium?.copyWith(height: 1.5),
                              onOpenLesson: (id) => openLesson(context, id)),
                      ],
                    ),
                  ),
                for (var i = 0; i < surah.ayat.length; i++)
                  _AyahTile(
                    key: _keys.putIfAbsent(i + 1, () => GlobalKey()),
                    surah: surah,
                    number: i + 1,
                    ayah: surah.ayat[i],
                    hidden: _memorise && !_revealed.contains(i + 1),
                    onReveal: () => setState(() => _revealed.add(i + 1)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AyahTile extends StatelessWidget {
  final Surah surah;
  final int number;
  final Ayah ayah;
  final bool hidden;
  final VoidCallback onReveal;
  const _AyahTile({
    super.key,
    required this.surah,
    required this.number,
    required this.ayah,
    required this.hidden,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final ref = '${surah.number}:$number';
    final bookmarked = s.isBookmarked(ref);
    final isLast = s.lastRead == ref;
    return Panel(
      onTap: () {
        s.setLastRead(ref);
        if (hidden) onReveal();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _NumberBadge(number),
              const SizedBox(width: 8),
              if (isLast) Text('Last read', style: text.labelSmall?.copyWith(color: scheme.primary)),
              const Spacer(),
              IconButton(
                tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
                onPressed: () => s.toggleBookmark(ref),
                icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              ),
            ],
          ),
          if (hidden)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Recite from memory, then tap to check',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
            )
          else ...[
            if (s.showArabic)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(ayah.ar,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: arabicStyle(context, size: 28)),
              ),
            if (s.showTranslit)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TajweedText(ayah.tr,
                    style: text.titleMedium?.copyWith(height: 1.6),
                    onOpenLesson: (id) => openLesson(context, id)),
              ),
            if (s.showMeaning)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(ayah.en,
                    style: text.bodyMedium?.copyWith(
                        height: 1.5, color: scheme.onSurface.withValues(alpha: 0.75))),
              ),
          ],
        ],
      ),
    );
  }
}
