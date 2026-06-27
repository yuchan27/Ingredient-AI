import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/models/food_record.dart';
import 'package:foodlens_ai_app/models/nutrition_summary.dart';

void main() {
  test('daily summary totals only records from the selected day', () {
    final records = [
      FoodRecord.empty('a').copyWith(
        calories: 500,
        protein: 25,
        cost: 90,
        eatenAt: DateTime(2026, 6, 27, 8),
      ),
      FoodRecord.empty('b').copyWith(
        calories: 700,
        protein: 30,
        cost: 120,
        eatenAt: DateTime(2026, 6, 27, 19),
      ),
      FoodRecord.empty('c').copyWith(
        calories: 300,
        protein: 10,
        cost: 50,
        eatenAt: DateTime(2026, 6, 26, 19),
      ),
    ];

    final summary = NutritionSummary.forDay(records, DateTime(2026, 6, 27));
    expect(summary.calories, 1200);
    expect(summary.protein, 55);
    expect(summary.cost, 210);
    expect(summary.remainingCalories(2000), 800);
  });

  test('recommendation responds to remaining calories and protein', () {
    const summary = NutritionSummary(
      calories: 1700,
      protein: 45,
      fat: 65,
      carbs: 180,
      cost: 200,
    );
    expect(summary.nextMealSuggestion(goalCalories: 2000), contains('高蛋白'));
  });
}
