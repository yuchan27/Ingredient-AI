import 'package:app_medium/models/food_entry.dart';
import 'package:app_medium/services/nutrition_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NutritionAnalyticsService', () {
    test('groups entries by day and totals nutrition metrics', () {
      final entries = [
        _entry(
          localId: 'breakfast',
          consumedAt: DateTime.utc(2026, 6, 26, 8),
          calories: 250,
          protein: 12,
          carbs: 30,
          fat: 7,
          sugar: 8,
          sodium: 220,
          fiber: 4,
          cost: 75,
          healthScore: 80,
        ),
        _entry(
          localId: 'lunch',
          consumedAt: DateTime.utc(2026, 6, 26, 12),
          calories: 550,
          protein: 35,
          carbs: 58,
          fat: 18,
          sugar: 11,
          sodium: 710,
          fiber: 7,
          cost: 130,
          healthScore: 70,
        ),
        _entry(
          localId: 'yesterday',
          consumedAt: DateTime.utc(2026, 6, 25, 18),
          calories: 400,
          protein: 20,
          carbs: 45,
          fat: 12,
          sugar: 9,
          sodium: 500,
          fiber: 6,
          cost: 90,
          healthScore: 90,
        ),
      ];

      final summaries = NutritionAnalyticsService.dailySummaries(entries);
      final today = summaries.firstWhere(
        (summary) => summary.date == DateTime.utc(2026, 6, 26),
      );

      expect(summaries.length, 2);
      expect(today.entryCount, 2);
      expect(today.totalCalories, 800);
      expect(today.totalProtein, 47);
      expect(today.totalCarbs, 88);
      expect(today.totalFat, 25);
      expect(today.totalSugar, 19);
      expect(today.totalSodium, 930);
      expect(today.totalFiber, 11);
      expect(today.totalCost, 205);
      expect(today.averageHealthScore, 75);
    });
  });
}

FoodEntry _entry({
  required String localId,
  required DateTime consumedAt,
  required int calories,
  required double protein,
  required double carbs,
  required double fat,
  required double sugar,
  required double sodium,
  required double fiber,
  double cost = 0,
  required int healthScore,
}) {
  return FoodEntry(
    localId: localId,
    foodName: localId,
    consumedAt: consumedAt,
    mealType: 'meal',
    servingSize: 1,
    servingUnit: 'serving',
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    sugar: sugar,
    sodium: sodium,
    fiber: fiber,
    cost: cost,
    healthScore: healthScore,
    source: FoodEntrySource.manual,
    isPendingSync: true,
    createdAt: consumedAt,
    updatedAt: consumedAt,
  );
}
