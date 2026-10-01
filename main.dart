import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/notifications.dart';
import 'ui/home_shell.dart';
import 'ui/onboarding.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.load();
  await NotificationService.instance.init();
  runApp(const SalahApp());
}

class SalahApp extends StatefulWidget {
  const SalahApp({super.key});

  @override
  State<SalahApp> createState() => _SalahAppState();
}

class _SalahAppState extends State<SalahApp> with WidgetsBindingObserver {
  final ThemeData _light = AppTheme.light();
  final ThemeData _dark = AppTheme.dark();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
    if (state == AppLifecycleState.paused) AppState.instance.flush();
  }

  /// Every time the app comes to the front: record prayers whose time ended,
  /// act on the notification that opened the app, and re-plan alerts.
  Future<void> _refresh() async {
    AppState.instance.reconcile();
    await NotificationService.instance.handleLaunch();
    await NotificationService.instance.reschedule();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance.settings;
        final mode = switch (s.theme) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return MaterialApp(
          title: 'Salah Companion',
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: mode,
          home: s.onboarded ? const HomeShell() : const OnboardingScreen(),
        );
      },
    );
  }
}
