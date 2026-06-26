import 'package:app_medium/models/food_entry.dart';
import 'package:app_medium/services/diet_planning_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DietPlanningService', () {
    test('recommends a low sodium fiber meal when lunch is high sodium', () {
      final entries = [
        _entry(
          localId: 'chicken-cutlet',
          foodName: '雞排營養標示',
          consumedAt: DateTime.utc(2026, 6, 27, 12),
          mealType: 'lunch',
          calories: 282,
          protein: 16.9,
          carbs: 27.6,
          fat: 11.6,
          sugar: 3.8,
          sodium: 664,
          fiber: 1.2,
          cost: 89,
          healthScore: 62,
        ),
      ];

      final plan = const DietPlanningService().buildTodayPlan(
        entries,
        now: DateTime.utc(2026, 6, 27, 15),
      );

      expect(plan.summary.totalCalories, 282);
      expect(plan.summary.totalCost, 89);
      expect(plan.calorieGoal, 2000);
      expect(plan.remainingCalories, 1718);
      expect(plan.nextMeal.title, '下一餐建議：低鈉高纖餐');
      expect(plan.nextMeal.suggestedMealType, 'dinner');
      expect(plan.nextMeal.calorieRangeLabel, '450-650 kcal');
      expect(plan.nextMeal.keyReasons, contains('午餐鈉含量偏高，晚餐建議避開炸物與重鹹醬料。'));
      expect(plan.alerts, contains('鈉攝取已達 664 mg，今天剩下餐點請優先低鈉。'));
    });
  });
}

FoodEntry _entry({
  required String localId,
  required String foodName,
  required DateTime consumedAt,
  required String mealType,
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
    foodName: foodName,
    consumedAt: consumedAt,
    mealType: mealType,
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
