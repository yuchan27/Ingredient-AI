import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/food_entry.dart';
import '../services/cloud_sync_service.dart';
import '../services/db_service.dart';
import '../services/diet_planning_service.dart';
import '../services/nutrition_analytics_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DBService _dbService = DBService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final DietPlanningService _dietPlanningService = const DietPlanningService();
  final Uuid _uuid = const Uuid();
  late Future<_DashboardData> _future;
  DateTime _selectedDate = NutritionAnalyticsService.dateOnly(DateTime.now());

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
    try {
      final result = await _cloudSyncService.syncPending();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFF00B894),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同步失敗：$e'), backgroundColor: Colors.redAccent),
      );
    }
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
    final costController = TextEditingController();
    String mealType = 'snack';
    DateTime consumedAt = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: consumedAt,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked == null) return;
              setModalState(() {
                consumedAt = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  consumedAt.hour,
                  consumedAt.minute,
                );
              });
            }

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
                      '新增飲食與記帳',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _input(foodController, '食物名稱', Icons.fastfood_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: pickDate,
                            icon: const Icon(Icons.calendar_today_rounded),
                            label: Text(
                              DateFormat('yyyy/MM/dd').format(consumedAt),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: mealType,
                            dropdownColor: const Color(0xFF1A1A1A),
                            decoration: _inputDecoration(
                              '餐別',
                              Icons.restaurant_rounded,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'breakfast',
                                child: Text('早餐'),
                              ),
                              DropdownMenuItem(
                                value: 'lunch',
                                child: Text('午餐'),
                              ),
                              DropdownMenuItem(
                                value: 'dinner',
                                child: Text('晚餐'),
                              ),
                              DropdownMenuItem(
                                value: 'snack',
                                child: Text('點心'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() => mealType = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _numberInput(caloriesController, '熱量 kcal'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _numberInput(costController, '餐費 TWD')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _numberInput(proteinController, '蛋白質 g'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _numberInput(carbsController, '碳水 g')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _numberInput(fatController, '脂肪 g')),
                        const SizedBox(width: 12),
                        Expanded(child: _numberInput(sugarController, '糖 g')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _numberInput(sodiumController, '鈉 mg')),
                        const SizedBox(width: 12),
                        Expanded(child: _numberInput(fiberController, '纖維 g')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final foodName = foodController.text.trim();
                          if (foodName.isEmpty) return;
                          final now = DateTime.now().toUtc();
                          final entry = FoodEntry(
                            localId: _uuid.v4(),
                            foodName: foodName,
                            consumedAt: consumedAt,
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
                            cost: _parseDouble(costController.text),
                            healthScore: 0,
                            source: FoodEntrySource.manual,
                            isPendingSync: true,
                            createdAt: now,
                            updatedAt: now,
                          );
                          await _dbService.insertFoodEntry(entry);
                          try {
                            await _cloudSyncService.syncPending();
                          } catch (_) {}
                          if (!mounted) return;
                          navigator.pop();
                          setState(() {
                            _selectedDate = NutritionAnalyticsService.dateOnly(
                              consumedAt,
                            );
                          });
                          await _reload();
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('儲存紀錄'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B894),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
        title: const Text(
          '飲食總分析',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '同步',
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
          final summaries = NutritionAnalyticsService.dailySummaries(
            data.entries,
          );
          final selectedEntries = data.entries.where((entry) {
            return NutritionAnalyticsService.dateOnly(entry.consumedAt) ==
                _selectedDate;
          }).toList();
          final selectedPlan = _dietPlanningService.buildTodayPlan(
            data.entries,
            now: DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              DateTime.now().hour,
            ),
          );

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _syncBanner(data),
                const SizedBox(height: 14),
                _dateSwitcher(),
                const SizedBox(height: 14),
                _todayHero(selectedPlan),
                const SizedBox(height: 14),
                _planningPanel(selectedPlan),
                const SizedBox(height: 14),
                _metricsGrid(selectedPlan.summary),
                const SizedBox(height: 22),
                const Text(
                  '當日紀錄',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (selectedEntries.isEmpty)
                  _emptyState('這一天還沒有飲食紀錄。')
                else
                  ...selectedEntries.map(_entryRow),
                const SizedBox(height: 22),
                const Text(
                  '近 7 日趨勢',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (summaries.isEmpty)
                  _emptyState('目前沒有可分析的資料。')
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
    final color = data.cloudState.isSignedIn
        ? Colors.greenAccent
        : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            data.cloudState.isSignedIn
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${data.cloudState.message} 待同步 ${data.pendingSyncCount} 筆',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateSwitcher() {
    final isToday =
        _selectedDate == NutritionAnalyticsService.dateOnly(DateTime.now());
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: '前一天',
          onPressed: () {
            setState(
              () => _selectedDate = _selectedDate.subtract(
                const Duration(days: 1),
              ),
            );
          },
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked == null) return;
              setState(
                () =>
                    _selectedDate = NutritionAnalyticsService.dateOnly(picked),
              );
            },
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(DateFormat('yyyy/MM/dd').format(_selectedDate)),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: '後一天',
          onPressed: () {
            setState(
              () => _selectedDate = _selectedDate.add(const Duration(days: 1)),
            );
          },
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: isToday
              ? null
              : () => setState(() {
                  _selectedDate = NutritionAnalyticsService.dateOnly(
                    DateTime.now(),
                  );
                }),
          child: const Text('今天'),
        ),
      ],
    );
  }

  Widget _todayHero(DailyDietPlan plan) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF00B894).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00B894).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('今日熱量分析', style: TextStyle(color: Colors.white70)),
              ),
              Text(
                '剩餘 ${plan.remainingCalories} kcal',
                style: const TextStyle(
                  color: Color(0xFF00B894),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${plan.summary.totalCalories} / ${plan.calorieGoal} kcal',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: plan.calorieProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF00B894)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${plan.summary.entryCount} 筆紀錄',
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
              Text(
                '餐費 TWD ${_formatMoney(plan.summary.totalCost)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planningPanel(DailyDietPlan plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                color: Color(0xFF00B894),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plan.nextMeal.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_mealTypeLabel(plan.nextMeal.suggestedMealType)} | ${plan.nextMeal.calorieRangeLabel}',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.nextMeal.foodIdeas
                .map((idea) => _chip(idea, Colors.greenAccent))
                .toList(),
          ),
          if (plan.alerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...plan.alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amberAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...plan.nextMeal.keyReasons
              .take(2)
              .map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• $reason',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _metricsGrid(DailyNutritionSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricTile('蛋白質', _format(summary.totalProtein), 'g'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile('碳水', _format(summary.totalCarbs), 'g'),
            ),
            const SizedBox(width: 10),
            Expanded(child: _metricTile('脂肪', _format(summary.totalFat), 'g')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _metricTile('糖', _format(summary.totalSugar), 'g')),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile('鈉', _format(summary.totalSodium), 'mg'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile('纖維', _format(summary.totalFiber), 'g'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$value $unit',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryRow(FoodEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(_mealTypeIcon(entry.mealType), color: const Color(0xFF00B894)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_mealTypeLabel(entry.mealType)} | ${entry.calories} kcal | 餐費 ${_formatMoney(entry.cost)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            entry.isPendingSync
                ? Icons.cloud_upload_outlined
                : Icons.cloud_done_rounded,
            color: entry.isPendingSync
                ? Colors.orangeAccent
                : Colors.greenAccent,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(DailyNutritionSummary summary) {
    final date = DateFormat('M/d').format(summary.date);
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = summary.date),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                date,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value:
                    (summary.totalCalories /
                            DietPlanningService.defaultCalorieGoal)
                        .clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00B894)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${summary.totalCalories} kcal',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'TWD ${_formatMoney(summary.totalCost)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white24,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF00B894)),
    );
  }

  IconData _mealTypeIcon(String mealType) {
    return switch (mealType) {
      'breakfast' => Icons.free_breakfast_rounded,
      'lunch' => Icons.lunch_dining_rounded,
      'dinner' => Icons.dinner_dining_rounded,
      _ => Icons.cookie_rounded,
    };
  }

  String _mealTypeLabel(String mealType) {
    return switch (mealType) {
      'breakfast' => '早餐',
      'lunch' => '午餐',
      'dinner' => '晚餐',
      _ => '點心',
    };
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

  String _formatMoney(double value) {
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
