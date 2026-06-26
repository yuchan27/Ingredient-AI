import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/food_entry.dart';
import '../services/cloud_sync_service.dart';
import '../services/db_service.dart';
import '../services/nutrition_analytics_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DBService _dbService = DBService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final Uuid _uuid = const Uuid();
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final entries = await _dbService.getFoodEntries();
    final cloudState = await _cloudSyncService.initialize();
    final pendingHistory = await _dbService.getPendingHistory();
    final pendingEntries = await _dbService.getPendingFoodEntries();
    return _DashboardData(
      entries: entries,
      cloudState: cloudState,
      pendingSyncCount: pendingHistory.length + pendingEntries.length,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _syncNow() async {
    final result = await _cloudSyncService.syncPending();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message), backgroundColor: const Color(0xFF00B894)),
    );
    await _reload();
  }

  Future<void> _showManualEntrySheet() async {
    final foodController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    final sugarController = TextEditingController();
    final sodiumController = TextEditingController();
    final fiberController = TextEditingController();
    String mealType = 'snack';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "手動新增飲食",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _input(foodController, "食物名稱", Icons.fastfood_rounded),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: mealType,
                      dropdownColor: const Color(0xFF1A1A1A),
                      decoration: _inputDecoration("餐別", Icons.restaurant_rounded),
                      items: const [
                        DropdownMenuItem(value: 'breakfast', child: Text("早餐")),
                        DropdownMenuItem(value: 'lunch', child: Text("午餐")),
                        DropdownMenuItem(value: 'dinner', child: Text("晚餐")),
                        DropdownMenuItem(value: 'snack', child: Text("點心")),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => mealType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _numberInput(caloriesController, "熱量 kcal")),
                        const SizedBox(width: 12),
                        Expanded(child: _numberInput(proteinController, "蛋白質 g")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _numberInput(carbsController, "碳水 g")),
                        const SizedBox(width: 12),
                        Expanded(child: _numberInput(fatController, "脂肪 g")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _numberInput(sugarController, "糖 g")),
                        const SizedBox(width: 12),
                        Expanded(child: _numberInput(sodiumController, "鈉 mg")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _numberInput(fiberController, "纖維 g"),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final foodName = foodController.text.trim();
                          if (foodName.isEmpty) return;
                          final now = DateTime.now();
                          final entry = FoodEntry(
                            localId: _uuid.v4(),
                            foodName: foodName,
                            consumedAt: now,
                            mealType: mealType,
                            servingSize: 1,
                            servingUnit: 'serving',
                            calories: _parseInt(caloriesController.text),
                            protein: _parseDouble(proteinController.text),
                            carbs: _parseDouble(carbsController.text),
                            fat: _parseDouble(fatController.text),
                            sugar: _parseDouble(sugarController.text),
                            sodium: _parseDouble(sodiumController.text),
                            fiber: _parseDouble(fiberController.text),
                            healthScore: 0,
                            source: FoodEntrySource.manual,
                            isPendingSync: true,
                            createdAt: now.toUtc(),
                            updatedAt: now.toUtc(),
                          );
                          await _dbService.insertFoodEntry(entry);
                          try {
                            await _cloudSyncService.syncPending();
                          } catch (_) {}
                          if (!mounted) return;
                          navigator.pop();
                          await _reload();
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("新增"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B894),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("營養分析", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: "同步",
            onPressed: _syncNow,
            icon: const Icon(Icons.cloud_sync_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showManualEntrySheet,
        backgroundColor: const Color(0xFF00B894),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final today = NutritionAnalyticsService.summaryForDate(
            data.entries,
            DateTime.now(),
          );
          final summaries = NutritionAnalyticsService.dailySummaries(data.entries);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _syncBanner(data),
                const SizedBox(height: 16),
                _todayHero(today),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _metricTile("蛋白質", _format(today.totalProtein), "g")),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile("碳水", _format(today.totalCarbs), "g")),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile("脂肪", _format(today.totalFat), "g")),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _metricTile("糖", _format(today.totalSugar), "g")),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile("鈉", _format(today.totalSodium), "mg")),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile("纖維", _format(today.totalFiber), "g")),
                  ],
                ),
                const SizedBox(height: 24),
                const Text("近期紀錄", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (summaries.isEmpty)
                  _emptyState()
                else
                  ...summaries.take(7).map(_summaryRow),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _syncBanner(_DashboardData data) {
    final color = data.cloudState.isSignedIn ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(data.cloudState.isSignedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${data.cloudState.message}｜待同步 ${data.pendingSyncCount} 筆",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayHero(DailyNutritionSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00B894).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00B894).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("今日攝取", style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 8),
                Text(
                  "${summary.totalCalories} kcal",
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "${summary.entryCount} 筆紀錄｜平均分 ${summary.averageHealthScore.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          const Icon(Icons.monitor_heart_rounded, color: Color(0xFF00B894), size: 44),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              "$value $unit",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(DailyNutritionSummary summary) {
    final date = "${summary.date.month}/${summary.date.day}";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: LinearProgressIndicator(
              value: (summary.averageHealthScore / 100).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00B894)),
            ),
          ),
          const SizedBox(width: 12),
          Text("${summary.totalCalories} kcal", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.restaurant_menu_rounded, color: Colors.white24, size: 40),
          SizedBox(height: 12),
          Text("尚無飲食紀錄", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
    );
  }

  Widget _numberInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label, Icons.numbers_rounded),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF00B894)),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      prefixIcon: Icon(icon, color: const Color(0xFF00B894)),
    );
  }

  int _parseInt(String value) {
    return (double.tryParse(value.trim()) ?? 0).round();
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _DashboardData {
  final List<FoodEntry> entries;
  final CloudSyncState cloudState;
  final int pendingSyncCount;

  const _DashboardData({
    required this.entries,
    required this.cloudState,
    required this.pendingSyncCount,
  });
}
