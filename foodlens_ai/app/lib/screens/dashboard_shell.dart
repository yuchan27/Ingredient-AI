import 'package:flutter/material.dart';

import '../repositories/food_repository.dart';
import '../services/food_analysis_api.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

typedef TokenProvider = Future<String> Function();

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.repository,
    required this.api,
    required this.accountEmail,
    required this.isDemo,
    required this.tokenProvider,
    this.onApiBaseUrlChanged,
    this.onLogout,
  });

  final FoodRepository repository;
  final FoodAnalysisApi api;
  final String accountEmail;
  final bool isDemo;
  final TokenProvider tokenProvider;
  final Future<void> Function(String value)? onApiBaseUrlChanged;
  final Future<void> Function()? onLogout;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        repository: widget.repository,
        api: widget.api,
        tokenProvider: widget.tokenProvider,
        isDemo: widget.isDemo,
      ),
      InsightsScreen(repository: widget.repository),
      SettingsScreen(
        repository: widget.repository,
        accountEmail: widget.accountEmail,
        isDemo: widget.isDemo,
        apiBaseUrl: widget.api.baseUrl,
        onApiBaseUrlChanged: widget.onApiBaseUrlChanged,
        onLogout: widget.onLogout,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '分析',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
