import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/notifications.dart';
import '../core/prayer_calc.dart';
import 'location.dart';
import 'settings_screen.dart';
import 'theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;
  bool _locating = false;
  String? _locationError;
  bool? _notificationsAllowed;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    _pages.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _useLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    final err = await useDeviceLocation(suggest: true);
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locationError = err;
    });
  }

  Future<void> _pickCity() async {
    final c = await showCityPicker(context);
    if (c != null) {
      applyLocation(c.lat, c.lng, c.name, suggest: true);
      setState(() => _locationError = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcome(context),
                  ListenableBuilder(
                    listenable: AppState.instance,
                    builder: (context, _) => _location(context),
                  ),
                  _alerts(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageShell({required List<Widget> children, required Widget action}) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(width: double.infinity, child: action),
        ),
      ],
    );
  }

  Widget _welcome(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(body, style: text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        );
    return _pageShell(
      children: [
        Text('السلام عليكم', style: arabicStyle(context, size: 30)),
        Text('Salah Companion',
            style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Pray on time, remember Allah through the day, and learn to recite with tajweed.',
            style: text.titleMedium),
        const SizedBox(height: 32),
        point(Icons.notifications_active_outlined, 'Alerts that keep reminding you',
            'At each prayer time you get an alert. It repeats until you tap “I’ve prayed”.'),
        point(Icons.blur_circular_outlined, 'Dhikr and adhkar',
            'A tasbih counter, and guided morning, evening and after-prayer adhkar.'),
        point(Icons.school_outlined, 'Tajweed lessons',
            'Short lessons with quizzes, and colour-coded transliteration of the surahs most recited in prayer.'),
      ],
      action: FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: () => _go(1),
        child: const Text('Get started'),
      ),
    );
  }

  Widget _location(BuildContext context) {
    final app = AppState.instance;
    final s = app.settings;
    final text = Theme.of(context).textTheme;
    final t = app.timesFor(DateTime.now());
    return _pageShell(
      children: [
        Text('Where are you?', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Prayer times are calculated on your phone from your location. It is never sent anywhere.',
            style: text.bodyLarge),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _locating ? null : _useLocation,
          icon: _locating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: Text(_locating ? 'Finding you…' : 'Use my location'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _pickCity,
          child: const Text('Choose a city'),
        ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_locationError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (app.hasLocation && t != null) ...[
          const SizedBox(height: 24),
          Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.place, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  Prayer.values.map((p) => '${p.label} ${clock(t.start(p), h24: app.use24h)}').join('   '),
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Calculation method'),
            subtitle: Text('${kMethods[s.method]!.name}. Check that these times match your mosque; you can fine-tune them later in Settings.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final v = await pickOne<CalcMethod>(
                context,
                'Calculation method',
                [for (final e in kMethods.entries) Choice(e.key, e.value.name, e.value.usedIn)],
                s.method,
              );
              if (v != null) app.update((x) => x.method = v, times: true);
            },
          ),
          const SizedBox(height: 8),
          SegmentedButton<AsrMethod>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: AsrMethod.standard, label: Text('Standard ʿAṣr')),
              ButtonSegment(value: AsrMethod.hanafi, label: Text('Ḥanafī ʿAṣr')),
            ],
            selected: {s.asr},
            onSelectionChanged: (v) => app.update((x) => x.asr = v.first, times: true),
          ),
        ],
      ],
      action: FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: app.hasLocation ? () => _go(2) : null,
        child: const Text('Continue'),
      ),
    );
  }

  Widget _alerts(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _pageShell(
      children: [
        Text('Prayer alerts', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'At each prayer time you will get an alert with an “I’ve prayed” button. If you don’t tap it, the alert repeats every 10 minutes until the time for that prayer ends, with a final warning 20 minutes before. You can change all of this in Settings.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () async {
            final ok = await NotificationService.instance.requestPermissions();
            if (mounted) setState(() => _notificationsAllowed = ok);
          },
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Allow notifications'),
        ),
        if (_notificationsAllowed != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _notificationsAllowed!
                  ? 'Notifications are on.'
                  : 'Notifications are blocked. You can allow them later in your phone’s settings.',
              style: text.bodyMedium,
            ),
          ),
      ],
      action: FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: () async {
          if (_notificationsAllowed == null) {
            await NotificationService.instance.requestPermissions();
          }
          AppState.instance.completeOnboarding();
        },
        child: const Text('Start'),
      ),
    );
  }
}
