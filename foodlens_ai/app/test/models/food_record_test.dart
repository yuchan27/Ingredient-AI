import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/models/food_record.dart';

void main() {
  test('FoodRecord round trips Firestore-compatible data', () {
    final eatenAt = DateTime.utc(2026, 6, 27, 12, 30);
    final record = FoodRecord(
      id: 'r1',
      foodName: '雞排便當',
      calories: 780,
      protein: 35,
      fat: 28,
      carbs: 92,
      confidence: 0.88,
      notes: '估算值',
      imagePath: 'users/u1/food_images/r1.jpg',
      mealType: MealType.lunch,
      cost: 110,
      eatenAt: eatenAt,
      createdAt: eatenAt,
      updatedAt: eatenAt,
    );

    final restored = FoodRecord.fromMap('r1', record.toMap());
    expect(restored.foodName, '雞排便當');
    expect(restored.mealType, MealType.lunch);
    expect(restored.cost, 110);
    expect(restored.eatenAt, eatenAt);
  });

  test('copyWith changes editable nutrition fields', () {
    final record = FoodRecord.empty('r1');
    final changed = record.copyWith(foodName: '水果沙拉', calories: 180, cost: 65);
    expect(changed.foodName, '水果沙拉');
    expect(changed.calories, 180);
    expect(changed.cost, 65);
  });
}
