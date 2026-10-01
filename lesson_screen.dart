import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../data/lessons.dart';
import 'tajweed.dart';
import 'theme.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final Map<int, int> _answers = {};

  void _openLesson(String id) {
    if (id == widget.lessonId) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => LessonScreen(lessonId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final lesson = lessonById(widget.lessonId);
    if (lesson == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Lesson not found.')));
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final correct = _answers.entries.where((e) => lesson.quiz[e.key].answer == e.value).length;
    final allAnswered = _answers.length == lesson.quiz.length;
    final passed = allAnswered && correct >= (lesson.quiz.length * 2 / 3).ceil();
    final index = kLessons.indexWhere((l) => l.id == lesson.id);
    final nextLesson = index >= 0 && index < kLessons.length - 1 ? kLessons[index + 1] : null;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(lesson.summary,
                style: text.titleMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
          ),
          for (final p in lesson.paragraphs)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(p, style: text.bodyLarge?.copyWith(height: 1.55)),
            ),
          if (lesson.letters != null)
            Panel(
              child: Center(
                child: Text(lesson.letters!,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: arabicStyle(context, size: 32, color: scheme.primary)),
              ),
            ),
          const SectionLabel('Examples'),
          for (final e in lesson.examples)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(e.ar,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: arabicStyle(context, size: 28)),
                  TajweedText(e.tr,
                      style: text.titleMedium?.copyWith(height: 1.5),
                      onOpenLesson: _openLesson),
                  const SizedBox(height: 4),
                  Text('${e.note} ${e.ref}.', style: text.bodySmall),
                ],
              ),
            ),
          const SectionLabel('Check your understanding'),
          for (var q = 0; q < lesson.quiz.length; q++)
            _QuizCard(
              number: q + 1,
              question: lesson.quiz[q],
              chosen: _answers[q],
              onChoose: (i) => setState(() {
                _answers[q] = i;
                final c = _answers.entries.where((e) => lesson.quiz[e.key].answer == e.value).length;
                if (_answers.length == lesson.quiz.length &&
                    c >= (lesson.quiz.length * 2 / 3).ceil()) {
                  AppState.instance.markLessonDone(lesson.id);
                }
              }),
            ),
          if (allAnswered)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passed
                        ? 'Lesson complete: $correct of ${lesson.quiz.length} correct.'
                        : '$correct of ${lesson.quiz.length} correct. Read the lesson again and have another go.',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(_answers.clear),
                        child: const Text('Try again'),
                      ),
                      if (passed && nextLesson != null)
                        FilledButton(
                          onPressed: () => _openLesson(nextLesson.id),
                          child: Text('Next: ${nextLesson.title}'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final int number;
  final QuizQuestion question;
  final int? chosen;
  final ValueChanged<int> onChoose;
  const _QuizCard({required this.number, required this.question, required this.chosen, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final answered = chosen != null;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ${question.question}',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  backgroundColor: !answered
                      ? null
                      : i == question.answer
                          ? scheme.primary.withValues(alpha: 0.14)
                          : i == chosen
                              ? AppColors.missed.withValues(alpha: 0.12)
                              : null,
                  side: BorderSide(
                    color: answered && i == question.answer
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
                onPressed: answered ? null : () => onChoose(i),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(question.options[i],
                          style: text.bodyLarge?.copyWith(color: scheme.onSurface)),
                    ),
                    if (answered && i == question.answer) Icon(Icons.check, color: scheme.primary),
                    if (answered && i == chosen && i != question.answer)
                      const Icon(Icons.close, color: AppColors.missed),
                  ],
                ),
              ),
            ),
          if (answered)
            Text(
              '${chosen == question.answer ? 'Correct.' : 'Not quite.'} ${question.explain}',
              style: text.bodyMedium,
            ),
        ],
      ),
    );
  }
}
