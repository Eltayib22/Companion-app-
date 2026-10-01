import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/notifications.dart';
import '../core/prayer_calc.dart';
import 'location.dart';
import 'theme.dart';

class Choice<T> {
  final T value;
  final String label;
  final String? subtitle;
  const Choice(this.value, this.label, [this.subtitle]);
}

Future<T?> pickOne<T>(BuildContext context, String title, List<Choice<T>> choices, T selected) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final c in choices)
              ListTile(
                title: Text(c.label),
                subtitle: c.subtitle == null ? null : Text(c.subtitle!),
                trailing: c.value == selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, c.value),
              ),
          ],
        ),
      ),
    ),
  );
}

String _minutes(int m, {String zero = 'Off'}) => m == 0 ? zero : '$m minutes';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) => const _SettingsBody(),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final s = app.settings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final suggested = app.hasLocation ? suggestMethod(s.lat!, s.lng!) : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // ------------------------------------------------------- location
        const SectionLabel('Location'),
        Panel(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(app.hasLocation ? (s.place.isEmpty ? 'Custom location' : s.place) : 'Not set'),
                subtitle: app.hasLocation
                    ? Text('${s.lat!.toStringAsFixed(4)}, ${s.lng!.toStringAsFixed(4)}. Times are calculated on this phone; your location is not sent anywhere.')
                    : const Text('Prayer times need your location.'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final err = await useDeviceLocation();
                        if (context.mounted) _snack(context, err ?? 'Location updated.');
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use my location'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final c = await showCityPicker(context);
                        if (c != null) applyLocation(c.lat, c.lng, c.name);
                      },
                      child: const Text('Choose a city'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final r = await showCoordinateDialog(context);
                        if (r != null) applyLocation(r.$1, r.$2, nameForCoordinates(r.$1, r.$2));
                      },
                      child: const Text('Coordinates'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ---------------------------------------------------- calculation
        const SectionLabel('Prayer times'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                title: const Text('Calculation method'),
                subtitle: Text(kMethods[s.method]!.name +
                    (suggested != null && suggested != s.method
                        ? '\nOften used here: ${kMethods[suggested]!.name}'
                        : '')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final v = await pickOne<CalcMethod>(
                    context,
                    'Calculation method',
                    [
                      for (final e in kMethods.entries)
                        Choice(e.key, e.value.name,
                            '${e.value.usedIn}. ${e.value.ishaMinutes > 0 ? 'Fajr ${e.value.fajrAngle}°, ʿIshāʾ ${e.value.ishaMinutes} min after Maghrib' : e.key == CalcMethod.moonsighting ? 'Fajr and ʿIshāʾ follow the seasons' : 'Fajr ${e.value.fajrAngle}°, ʿIshāʾ ${e.value.ishaAngle}°'}'),
                    ],
                    s.method,
                  );
                  if (v != null) app.update((x) => x.method = v, times: true);
                },
              ),
              if (s.method == CalcMethod.custom) ...[
                _AngleSlider(
                  label: 'Fajr angle',
                  value: s.customFajr,
                  onChanged: (v) => app.update((x) => x.customFajr = v, times: true),
                ),
                _AngleSlider(
                  label: 'ʿIshāʾ angle',
                  value: s.customIsha,
                  onChanged: (v) => app.update((x) => x.customIsha = v, times: true),
                ),
              ],
              const Divider(),
              ListTile(
                title: const Text('ʿAṣr time'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ḥanafī ʿAṣr starts later in the afternoon'),
                    const SizedBox(height: 8),
                    SegmentedButton<AsrMethod>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: AsrMethod.standard, label: Text('Standard')),
                        ButtonSegment(value: AsrMethod.hanafi, label: Text('Ḥanafī')),
                      ],
                      selected: {s.asr},
                      onSelectionChanged: (v) => app.update((x) => x.asr = v.first, times: true),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Far north and south'),
                subtitle: Text(_highLatLabel(s.highLat)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final v = await pickOne<HighLatRule>(
                    context,
                    'When twilight lasts all night',
                    const [
                      Choice(HighLatRule.angleBased, 'Angle-based',
                          'Recommended. Uses a share of the night based on the Fajr and ʿIshāʾ angles.'),
                      Choice(HighLatRule.seventhOfNight, 'One seventh of the night',
                          'Fajr is no earlier than the last seventh of the night.'),
                      Choice(HighLatRule.middleOfNight, 'Middle of the night',
                          'Fajr and ʿIshāʾ are no further than halfway through the night.'),
                    ],
                    s.highLat,
                  );
                  if (v != null) app.update((x) => x.highLat = v, times: true);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('The time for ʿIshāʾ ends at'),
                subtitle: Text(s.ishaEnd == IshaEnd.midnight
                    ? 'Islamic midnight (halfway between sunset and Fajr)'
                    : 'Fajr'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final v = await pickOne<IshaEnd>(
                    context,
                    'When should ʿIshāʾ reminders stop?',
                    const [
                      Choice(IshaEnd.midnight, 'Islamic midnight',
                          'The preferred end of ʿIshāʾ. Avoids reminders through the night.'),
                      Choice(IshaEnd.fajr, 'Fajr', 'The latest permissible time.'),
                    ],
                    s.ishaEnd,
                  );
                  if (v != null) app.update((x) => x.ishaEnd = v, times: true);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Adjust by minutes'),
                subtitle: Text(Prayer.values.every((p) => (s.offsets[p] ?? 0) == 0)
                    ? 'Match your mosque’s timetable'
                    : Prayer.values
                        .where((p) => (s.offsets[p] ?? 0) != 0)
                        .map((p) => '${p.label} ${(s.offsets[p]! > 0 ? '+' : '')}${s.offsets[p]}')
                        .join(', ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _offsetsSheet(context),
              ),
            ],
          ),
        ),

        // --------------------------------------------------------- alerts
        const SectionLabel('Alerts'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Prayer alerts'),
                subtitle: const Text('An alert at each prayer time that repeats until you check the prayer off'),
                value: s.alertsOn,
                onChanged: (v) => app.update((x) => x.alertsOn = v),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final p in Prayer.values)
                      FilterChip(
                        label: Text(p.label),
                        selected: s.prayerAlerts[p] ?? true,
                        onSelected: s.alertsOn
                            ? (v) => app.update((x) => x.prayerAlerts[p] = v)
                            : null,
                      ),
                  ],
                ),
              ),
              const Divider(),
              _PickTile<int>(
                title: 'Repeat every',
                value: s.repeatEvery,
                display: (v) => '$v minutes',
                choices: const [
                  Choice(5, '5 minutes'),
                  Choice(10, '10 minutes'),
                  Choice(15, '15 minutes'),
                  Choice(20, '20 minutes'),
                  Choice(30, '30 minutes'),
                ],
                onChanged: (v) => app.update((x) => x.repeatEvery = v),
              ),
              _PickTile<int>(
                title: 'Keep repeating',
                value: s.maxRepeats,
                display: (v) => v == 0 ? 'Until the time for the prayer ends' : 'Up to $v times',
                choices: const [
                  Choice(0, 'Until the time for the prayer ends', 'Recommended'),
                  Choice(3, 'Up to 3 times'),
                  Choice(6, 'Up to 6 times'),
                  Choice(12, 'Up to 12 times'),
                ],
                onChanged: (v) => app.update((x) => x.maxRepeats = v),
              ),
              _PickTile<int>(
                title: 'Final warning',
                value: s.closingWarning,
                display: (v) => v == 0 ? 'Off' : '$v minutes before the time ends',
                choices: const [
                  Choice(0, 'Off'),
                  Choice(10, '10 minutes before'),
                  Choice(15, '15 minutes before'),
                  Choice(20, '20 minutes before'),
                  Choice(30, '30 minutes before'),
                ],
                onChanged: (v) => app.update((x) => x.closingWarning = v),
              ),
              _PickTile<int>(
                title: 'Heads-up before the prayer',
                value: s.preReminder,
                display: (v) => _minutes(v),
                choices: const [
                  Choice(0, 'Off'),
                  Choice(5, '5 minutes'),
                  Choice(10, '10 minutes'),
                  Choice(15, '15 minutes'),
                  Choice(20, '20 minutes'),
                  Choice(30, '30 minutes'),
                ],
                onChanged: (v) => app.update((x) => x.preReminder = v),
              ),
              SwitchListTile(
                title: const Text('Use my adhan recording'),
                subtitle: const Text('Plays your own adhan file at the start of each prayer. The file has to be added when building the app; see the setup guide.'),
                value: s.customSound,
                onChanged: (v) => app.update((x) => x.customSound = v),
              ),
              SwitchListTile(
                title: const Text('Morning adhkar reminder'),
                subtitle: const Text('Shortly after Fajr, unless you have already done them'),
                value: s.morningAdhkarReminder,
                onChanged: (v) => app.update((x) => x.morningAdhkarReminder = v),
              ),
              SwitchListTile(
                title: const Text('Evening adhkar reminder'),
                subtitle: const Text('After ʿAṣr, unless you have already done them'),
                value: s.eveningAdhkarReminder,
                onChanged: (v) => app.update((x) => x.eveningAdhkarReminder = v),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: ValueListenableBuilder<String>(
                  valueListenable: NotificationService.instance.status,
                  builder: (context, v, _) => Text(v, style: text.bodySmall),
                ),
              ),
              _ExactAlarmTile(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final ok = await NotificationService.instance.requestPermissions();
                        await NotificationService.instance.reschedule();
                        if (context.mounted) {
                          _snack(context, ok ? 'Notifications are allowed.' : 'Notifications are blocked. Allow them in your phone’s settings.');
                        }
                      },
                      child: const Text('Allow notifications'),
                    ),
                    OutlinedButton(
                      onPressed: () => NotificationService.instance.showTest(),
                      child: const Text('Send a test alert'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            'Alerts are planned a few days ahead and refreshed whenever you open the app. On Android, if alerts stop arriving, turn off battery optimisation for this app. On iPhone, allow this app through any Focus or Sleep mode you use at prayer times.',
            style: text.bodySmall,
          ),
        ),

        // ---------------------------------------------------------- modes
        const SectionLabel('Modes'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Excused'),
                subtitle: const Text('For example, during menstruation or after childbirth. Pauses alerts and records prayers as excused, not missed.'),
                value: s.exempt,
                onChanged: (v) => app.update((x) => x.exempt = v),
              ),
              SwitchListTile(
                title: const Text('Travelling'),
                subtitle: const Text('Lets you check off ʿAṣr from Dhuhr time and ʿIshāʾ from Maghrib time when combining.'),
                value: s.travel,
                onChanged: (v) => app.update((x) => x.travel = v),
              ),
              _PickTile<String>(
                title: 'Ramaḍān mode',
                value: s.ramadanMode,
                display: (v) => v == 'auto'
                    ? 'Automatic, from the Hijri date'
                    : v == 'on'
                        ? 'On'
                        : 'Off',
                choices: const [
                  Choice('auto', 'Automatic', 'Turns on during Ramaḍān by the Hijri date'),
                  Choice('on', 'On'),
                  Choice('off', 'Off'),
                ],
                onChanged: (v) => app.update((x) => x.ramadanMode = v, times: true),
              ),
              SwitchListTile(
                title: const Text('Track sunnah prayers'),
                subtitle: const Text('Adds sunnah, witr, ḍuḥā and tahajjud to the Today screen'),
                value: s.trackSunnah,
                onChanged: (v) => app.update((x) => x.trackSunnah = v, alerts: false),
              ),
            ],
          ),
        ),

        // -------------------------------------------------------- display
        const SectionLabel('Display'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _PickTile<String>(
                title: 'Theme',
                value: s.theme,
                display: (v) => v == 'system' ? 'Match the phone' : v == 'dark' ? 'Dark' : 'Light',
                choices: const [
                  Choice('system', 'Match the phone'),
                  Choice('light', 'Light'),
                  Choice('dark', 'Dark'),
                ],
                onChanged: (v) => app.update((x) => x.theme = v, alerts: false),
              ),
              ListTile(
                title: const Text('Arabic text size'),
                subtitle: Slider(
                  value: s.arabicScale,
                  min: 0.8,
                  max: 1.8,
                  divisions: 10,
                  label: '${(s.arabicScale * 100).round()}%',
                  onChanged: (v) => app.update((x) => x.arabicScale = v, alerts: false),
                ),
              ),
              SwitchListTile(
                title: const Text('Tajweed colours'),
                value: s.tajweedColours,
                onChanged: (v) => app.update((x) => x.tajweedColours = v, alerts: false),
              ),
              ListTile(
                title: const Text('Hijri date adjustment'),
                subtitle: Text('Today: ${app.hijri(DateTime.now())}. Adjust to match local moon sighting.'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: s.hijriAdjust > -2 ? () => app.update((x) => x.hijriAdjust--, times: true) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${s.hijriAdjust > 0 ? '+' : ''}${s.hijriAdjust}'),
                    IconButton(
                      onPressed: s.hijriAdjust < 2 ? () => app.update((x) => x.hijriAdjust++, times: true) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('34 takbīr after prayer'),
                subtitle: const Text('Say Allāhu akbar 34 times instead of 33 followed by lā ilāha illallāh. Both are authentic.'),
                value: s.takbir34,
                onChanged: (v) => app.update((x) => x.takbir34 = v, alerts: false),
              ),
            ],
          ),
        ),

        // --------------------------------------------------------- backup
        const SectionLabel('Your data'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Copy a backup'),
                subtitle: const Text('Copies all your settings and history as text. Paste it into a note or email to keep it safe.'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: app.exportJson()));
                  if (context.mounted) _snack(context, 'Backup copied.');
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Restore from a backup'),
                onTap: () => _importDialog(context),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text('Erase everything', style: TextStyle(color: scheme.error)),
                onTap: () => _resetDialog(context),
              ),
            ],
          ),
        ),

        const SectionLabel('About'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Prayer times are calculated astronomically and can differ by a few minutes from your local mosque. Use “Adjust by minutes” to match it. The tajweed transliteration follows the reading of Ḥafṣ ʿan ʿĀṣim; please check it against a printed muṣḥaf and a qualified teacher, and report anything that looks wrong.',
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }

  String _highLatLabel(HighLatRule r) {
    switch (r) {
      case HighLatRule.angleBased:
        return 'Angle-based';
      case HighLatRule.seventhOfNight:
        return 'One seventh of the night';
      case HighLatRule.middleOfNight:
        return 'Middle of the night';
    }
  }

  void _offsetsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: AppState.instance,
        builder: (ctx, _) {
          final app = AppState.instance;
          final t = app.timesFor(DateTime.now());
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in Prayer.values)
                  ListTile(
                    title: Text(p.label),
                    subtitle: t == null ? null : Text('Today: ${clock(t.start(p), h24: app.use24h)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => app.update((x) => x.offsets[p] = (x.offsets[p] ?? 0) - 1, times: true),
                          icon: const Icon(Icons.remove),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${(app.settings.offsets[p] ?? 0) > 0 ? '+' : ''}${app.settings.offsets[p] ?? 0}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: () => app.update((x) => x.offsets[p] = (x.offsets[p] ?? 0) + 1, times: true),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: () => app.update((x) {
                    for (final p in Prayer.values) {
                      x.offsets[p] = 0;
                    }
                  }, times: true),
                  child: const Text('Reset all to 0'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _importDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from a backup'),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste your backup text here',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final ok = AppState.instance.importJson(ctrl.text);
              Navigator.pop(ctx);
              _snack(context, ok ? 'Backup restored.' : 'That text is not a valid backup.');
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _resetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase everything?'),
        content: const Text('This removes your settings, prayer history, make-up counts and progress from this phone. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              AppState.instance.resetAll();
            },
            child: const Text('Erase'),
          ),
        ],
      ),
    );
  }
}

class _PickTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final String Function(T) display;
  final List<Choice<T>> choices;
  final ValueChanged<T> onChanged;
  const _PickTile({
    required this.title,
    required this.value,
    required this.display,
    required this.choices,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(display(value)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final v = await pickOne<T>(context, title, choices, value);
        if (v != null) onChanged(v);
      },
    );
  }
}

class _AngleSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _AngleSlider({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('$label: ${value.toStringAsFixed(1)}°'),
      subtitle: Slider(
        value: value.clamp(10.0, 22.0).toDouble(),
        min: 10,
        max: 22,
        divisions: 24,
        onChanged: onChanged,
      ),
    );
  }
}

class _ExactAlarmTile extends StatefulWidget {
  @override
  State<_ExactAlarmTile> createState() => _ExactAlarmTileState();
}

class _ExactAlarmTileState extends State<_ExactAlarmTile> {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await NotificationService.instance.exactAlarmsAllowed();
    if (mounted) setState(() => _allowed = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed != false) return const SizedBox.shrink();
    return ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
      title: const Text('Allow exact alarms'),
      subtitle: const Text('Without this, Android may deliver prayer alerts several minutes late.'),
      onTap: () async {
        await NotificationService.instance.openExactAlarmSettings();
        await _check();
        await NotificationService.instance.reschedule();
      },
    );
  }
}
