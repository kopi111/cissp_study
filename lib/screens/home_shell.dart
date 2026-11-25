import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'domains_screen.dart';
import 'plan_screen.dart';
import 'quiz_home_screen.dart';

/// The four main tabs of the app.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  static const _tabs = [
    DashboardScreen(),
    DomainsScreen(),
    QuizHomeScreen(),
    PlanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keeps each tab's scroll position when switching tabs.
      body: SafeArea(child: IndexedStack(index: _tabIndex, children: _tabs)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), label: 'Quiz'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Plan'),
        ],
      ),
    );
  }
}
