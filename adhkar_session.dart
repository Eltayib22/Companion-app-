import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../data/adhkar.dart';
import 'theme.dart';

class AdhkarSessionScreen extends StatefulWidget {
  final String setId;
  const AdhkarSessionScreen({super.key, required this.setId});

  @override
  State<AdhkarSessionScreen> createState() => _AdhkarSessionScreenState();
}

class _AdhkarSessionScreenState extends State<AdhkarSessionScreen> {
  late final AdhkarSet _set;
  late final List<int> _counts;
  final PageController _pages = PageController();
  int _page = 0;
  bool _finished = false;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _set = adhkarById(widget.setId, takbir34: AppState.instance.settings.takbir34);
    _counts = List<int>.filled(_set.items.length, 0);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  int get _done => _counts.fold(0, (a, b) => a + b);

  void _tap() {
    if (_advancing || _finished) return;
    final item = _set.items[_page];
    if (_counts[_page] >= item.count) {
      _next();
      return;
    }
    setState(() => _counts[_page]++);
    AppState.instance.addDhikr(1);
    if (_counts[_page] >= item.count) {
      HapticFeedback.heavyImpact();
      _advancing = true;
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        _advancing = false;
        _next();
      });
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _next() {
    if (_page < _set.items.length - 1) {
      _pages.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      AppState.instance.markAdhkarDone(_set.id);
      setState(() => _finished = true);
    }
  }

  void _showList() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, controller) => ListView.builder(
          controller: controller,
          itemCount: _set.items.length,
          itemBuilder: (ctx, i) {
            final d = _set.items[i];
            final complete = _counts[i] >= d.count;
            return ListTile(
              leading: Icon(complete ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: complete ? Theme.of(ctx).colorScheme.primary : null),
              title: Text(d.tr, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${_counts[i]} of ${d.count}'),
              onTap: () {
                Navigator.pop(ctx);
                _pages.jumpToPage(i);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (_finished) {
      return Scaffold(
        appBar: AppBar(title: Text(_set.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 64, color: scheme.primary),
                const SizedBox(height: 16),
                Text('${_set.title} complete',
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('May Allah accept it from you.', style: text.bodyLarge),
                const SizedBox(height: 24),
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
              ],
            ),
          ),
        ),
      );
    }

    final item = _set.items[_page];
    return Scaffold(
      appBar: AppBar(
        title: Text(_set.title),
        actions: [
          IconButton(
            tooltip: 'All adhkar in this set',
            onPressed: _showList,
            icon: const Icon(Icons.format_list_bulleted),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _set.totalCount == 0 ? 0 : _done / _set.totalCount,
            minHeight: 4,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _set.items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final d = _set.items[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _tap,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${i + 1} of ${_set.items.length}',
                            style: text.labelLarge?.copyWith(color: scheme.primary)),
                        const SizedBox(height: 12),
                        Text(d.ar,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: arabicStyle(context, size: 26)),
                        const SizedBox(height: 16),
                        Text(d.tr, style: text.titleMedium?.copyWith(height: 1.5, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 12),
                        Text(d.en, style: text.bodyLarge?.copyWith(height: 1.5)),
                        const SizedBox(height: 12),
                        Text(d.source,
                            style: text.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous',
                    onPressed: _page == 0
                        ? null
                        : () => _pages.previousPage(
                            duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(64),
                        textStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _tap,
                      child: Text(_counts[_page] >= item.count
                          ? 'Done. Next'
                          : 'Count  ${_counts[_page]} / ${item.count}'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Skip',
                    onPressed: _page >= _set.items.length - 1
                        ? null
                        : () => _pages.nextPage(
                            duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
