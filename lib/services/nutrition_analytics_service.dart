import '../models/food_entry.dart';

class DailyNutritionSummary {
  final DateTime date;
  final int entryCount;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalSugar;
  final double totalSodium;
  final double totalFiber;
  final double totalCost;
  final double averageHealthScore;

  const DailyNutritionSummary({
    required this.date,
    required this.entryCount,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalSugar,
    required this.totalSodium,
    required this.totalFiber,
    required this.totalCost,
    required this.averageHealthScore,
  });

  static DailyNutritionSummary empty(DateTime date) {
    return DailyNutritionSummary(
      date: NutritionAnalyticsService.dateOnly(date),
      entryCount: 0,
      totalCalories: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      totalSugar: 0,
      totalSodium: 0,
      totalFiber: 0,
      totalCost: 0,
      averageHealthScore: 0,
    );
  }
}

class NutritionAnalyticsService {
  const NutritionAnalyticsService();

  static DateTime dateOnly(DateTime value) {
    if (value.isUtc) {
      return DateTime.utc(value.year, value.month, value.day);
    }
    return DateTime(value.year, value.month, value.day);
  }

  static List<DailyNutritionSummary> dailySummaries(List<FoodEntry> entries) {
    final grouped = <DateTime, List<FoodEntry>>{};
    for (final entry in entries.where((entry) => entry.deletedAt == null)) {
      final date = dateOnly(entry.consumedAt);
      grouped.putIfAbsent(date, () => []).add(entry);
    }

    final summaries = grouped.entries.map((entry) {
      final dayEntries = entry.value;
      final totalScore = dayEntries.fold<int>(
        0,
        (sum, item) => sum + item.healthScore,
      );

      return DailyNutritionSummary(
        date: entry.key,
        entryCount: dayEntries.length,
        totalCalories: dayEntries.fold<int>(
          0,
          (sum, item) => sum + item.calories,
        ),
        totalProtein: _sum(dayEntries, (item) => item.protein),
        totalCarbs: _sum(dayEntries, (item) => item.carbs),
        totalFat: _sum(dayEntries, (item) => item.fat),
        totalSugar: _sum(dayEntries, (item) => item.sugar),
        totalSodium: _sum(dayEntries, (item) => item.sodium),
        totalFiber: _sum(dayEntries, (item) => item.fiber),
        totalCost: _sum(dayEntries, (item) => item.cost),
        averageHealthScore: dayEntries.isEmpty
            ? 0
            : totalScore / dayEntries.length,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return summaries;
  }

  static DailyNutritionSummary summaryForDate(
    List<FoodEntry> entries,
    DateTime date,
  ) {
    final target = dateOnly(date);
    for (final summary in dailySummaries(entries)) {
      if (summary.date == target) return summary;
    }
    return DailyNutritionSummary.empty(target);
  }

  static double _sum(
    List<FoodEntry> entries,
    double Function(FoodEntry entry) selector,
  ) {
    return entries.fold<double>(0, (sum, entry) => sum + selector(entry));
  }
}
