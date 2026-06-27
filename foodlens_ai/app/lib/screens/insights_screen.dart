import 'package:flutter/material.dart';

import '../models/food_record.dart';
import '../models/nutrition_summary.dart';
import '../repositories/food_repository.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.repository});
  final FoodRepository repository;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('飲食分析')),
    body: StreamBuilder<List<FoodRecord>>(
      stream: repository.watchRecords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        final today = NutritionSummary.forDay(records, DateTime.now());
        final weekStart = DateTime.now().subtract(const Duration(days: 6));
        final weekly = records
            .where((record) => record.eatenAt.isAfter(weekStart))
            .toList();
        final weeklyCalories = weekly.fold<double>(
          0,
          (sum, record) => sum + record.calories,
        );
        final weeklyCost = weekly.fold<double>(
          0,
          (sum, record) => sum + record.cost,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              '今日總分析',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProgressRow(
                      label: '熱量',
                      value: today.calories,
                      goal: 2000,
                      unit: 'kcal',
                    ),
                    const SizedBox(height: 14),
                    _ProgressRow(
                      label: '蛋白質',
                      value: today.protein,
                      goal: 90,
                      unit: 'g',
                    ),
                    const SizedBox(height: 14),
                    _ProgressRow(
                      label: '脂肪',
                      value: today.fat,
                      goal: 67,
                      unit: 'g',
                    ),
                    const SizedBox(height: 14),
                    _ProgressRow(
                      label: '碳水',
                      value: today.carbs,
                      goal: 250,
                      unit: 'g',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '下一餐吃什麼',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Card(
              color: Theme.of(
                context,
              ).colorScheme.tertiaryContainer.withValues(alpha: 0.48),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        today.nextMealSuggestion(),
                        style: const TextStyle(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '近 7 日概覽',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_outlined,
                    label: '平均熱量',
                    value:
                        '${weekly.isEmpty ? 0 : (weeklyCalories / 7).round()} kcal',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: '飲食花費',
                    value: 'NT\$${weeklyCost.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
  });
  final String label;
  final double value;
  final double goal;
  final String unit;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            '${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
          ),
        ],
      ),
      const SizedBox(height: 7),
      LinearProgressIndicator(
        value: (value / goal).clamp(0, 1).toDouble(),
        minHeight: 7,
        borderRadius: BorderRadius.circular(4),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
