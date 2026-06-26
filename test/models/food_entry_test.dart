import 'package:app_medium/models/food_entry.dart';
import 'package:app_medium/models/health_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodEntry', () {
    test('round trips nutrition values and pending sync metadata', () {
      final createdAt = DateTime.utc(2026, 6, 26, 8);
      final entry = FoodEntry(
        id: 7,
        localId: 'local-entry-1',
        foodName: 'Oat bowl',
        consumedAt: DateTime.utc(2026, 6, 26, 7, 30),
        mealType: 'breakfast',
        servingSize: 1.5,
        servingUnit: 'bowl',
        calories: 360,
        protein: 14,
        carbs: 52,
        fat: 9,
        sugar: 11,
        sodium: 180,
        fiber: 8,
        healthScore: 82,
        notes: 'Added banana',
        source: FoodEntrySource.ai,
        isPendingSync: true,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final roundTrip = FoodEntry.fromJson(entry.toJson());

      expect(roundTrip.id, 7);
      expect(roundTrip.localId, 'local-entry-1');
      expect(roundTrip.cloudId, isNull);
      expect(roundTrip.foodName, 'Oat bowl');
      expect(roundTrip.mealType, 'breakfast');
      expect(roundTrip.servingSize, 1.5);
      expect(roundTrip.calories, 360);
      expect(roundTrip.protein, 14);
      expect(roundTrip.carbs, 52);
      expect(roundTrip.fat, 9);
      expect(roundTrip.sugar, 11);
      expect(roundTrip.sodium, 180);
      expect(roundTrip.fiber, 8);
      expect(roundTrip.healthScore, 82);
      expect(roundTrip.source, FoodEntrySource.ai);
      expect(roundTrip.isPendingSync, isTrue);
      expect(roundTrip.deletedAt, isNull);
    });

    test('creates diary entry from AI health result', () {
      final consumedAt = DateTime.utc(2026, 6, 26, 12);
      final result = HealthResult.fromJson({
        'food_name': 'Chicken salad',
        'health_score': 88,
        'calories': 430,
        'protein': 35,
        'carbs': 18,
        'fat': 20,
        'sugar': 5,
        'sodium': 620,
        'fiber': 6,
      });

      final entry = FoodEntry.fromHealthResult(
        result,
        localId: 'generated-local-id',
        consumedAt: consumedAt,
        mealType: 'lunch',
      );

      expect(entry.localId, 'generated-local-id');
      expect(entry.foodName, 'Chicken salad');
      expect(entry.consumedAt, consumedAt);
      expect(entry.mealType, 'lunch');
      expect(entry.calories, 430);
      expect(entry.protein, 35);
      expect(entry.source, FoodEntrySource.ai);
      expect(entry.isPendingSync, isTrue);
    });
  });
}
