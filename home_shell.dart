import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/notifications.dart';
import '../core/prayer_calc.dart';
import 'adhkar_session.dart';
import 'dhikr_screen.dart';
import 'learn_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.openRequest.addListener(_onOpenRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onOpenRequest());
  }

  @override
  void dispose() {
    NotificationService.instance.openRequest.removeListener(_onOpenRequest);
    super.dispose();
  }

  void _onOpenRequest() {
    final req = NotificationService.instance.openRequest.value;
    if (req == null || !mounted) return;
    NotificationService.instance.openRequest.value = null;
    if (req.startsWith('adhkar:')) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => AdhkarSessionScreen(setId: req.substring(7)),
      ));
      return;
    }
    setState(() => _index = 0);
    if (req.startsWith('prayed:')) {
      final name = req.substring(7);
      for (final p in Prayer.values) {
        if (p.name == name) {
          showCheckedOffSnack(context, p, PrayerStatus.onTime);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppState.instance.use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          DhikrScreen(),
          LearnScreen(),
          QuranScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_twilight_outlined),
            selectedIcon: Icon(Icons.wb_twilight),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.blur_circular_outlined),
            selectedIcon: Icon(Icons.blur_circular),
            label: 'Dhikr',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Qurʾān',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
