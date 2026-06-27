import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../brand/brand_identity.dart';
import '../models/food_record.dart';
import '../models/nutrition_summary.dart';
import '../repositories/food_repository.dart';
import '../services/food_analysis_api.dart';
import 'dashboard_shell.dart';
import 'record_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.api,
    required this.tokenProvider,
    required this.isDemo,
  });

  final FoodRepository repository;
  final FoodAnalysisApi api;
  final TokenProvider tokenProvider;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BrandIdentity.name,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '今日飲食',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              final offline =
                  snapshot.data?.contains(ConnectivityResult.none) ?? false;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: offline ? '離線，變更將等待同步' : '已連線',
                  child: Icon(
                    offline
                        ? Icons.cloud_off_outlined
                        : Icons.cloud_done_outlined,
                    color: offline
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<FoodRecord>>(
        stream: repository.watchRecords(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final today = DateTime.now();
          final todayRecords = records
              .where(
                (record) =>
                    record.eatenAt.year == today.year &&
                    record.eatenAt.month == today.month &&
                    record.eatenAt.day == today.day,
              )
              .toList();
          final summary = NutritionSummary.forDay(records, today);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _DailySummary(summary: summary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        '飲食紀錄',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${todayRecords.length} 筆',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (todayRecords.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyRecords(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: todayRecords.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _RecordTile(
                      record: todayRecords[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecordDetailScreen(
                            repository: repository,
                            record: todayRecords[index],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddRecordScreen(
              repository: repository,
              api: api,
              tokenProvider: tokenProvider,
              isDemo: isDemo,
            ),
          ),
        ),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('新增食物'),
      ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.summary});
  final NutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    const goal = 2000.0;
    final progress = (summary.calories / goal).clamp(0, 1).toDouble();
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.42),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '今日熱量',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.calories.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kcal',
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Metric(
                  label: '蛋白質',
                  value: '${summary.protein.toStringAsFixed(0)} g',
                ),
                _Metric(
                  label: '脂肪',
                  value: '${summary.fat.toStringAsFixed(0)} g',
                ),
                _Metric(
                  label: '碳水',
                  value: '${summary.carbs.toStringAsFixed(0)} g',
                ),
                _Metric(
                  label: '花費',
                  value: '\$${summary.cost.toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.onTap});
  final FoodRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.foodName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.mealType.label}  ${DateFormat('HH:mm').format(record.eatenAt)}  ·  \$${record.cost.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.no_meals_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('今天還沒有飲食紀錄'),
        ],
      ),
    ),
  );
}
