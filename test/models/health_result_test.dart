import 'package:app_medium/models/health_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthResult', () {
    test('parses richer nutrition values from mixed JSON types', () {
      final result = HealthResult.fromJson({
        'food_name': 'Greek yogurt',
        'healthy_ingredients': ['milk cultures'],
        'risky_ingredients': ['added sugar'],
        'healthy_reason': 'Good protein source',
        'risky_reason': 'Contains sugar',
        'health_score': '78',
        'calories': '240',
        'sugar': '15.5',
        'sodium': 90,
        'fat': 4,
        'protein': '18.2',
        'carbs': 26,
        'fiber': '1.5',
        'assessment': 'Balanced snack',
        'recommendation': 'Moderate',
      });

      expect(result.foodName, 'Greek yogurt');
      expect(result.healthScore, 78);
      expect(result.calories, 240);
      expect(result.sugar, 15.5);
      expect(result.sodium, 90);
      expect(result.fat, 4);
      expect(result.protein, 18.2);
      expect(result.carbs, 26);
      expect(result.fiber, 1.5);
      expect(result.nutritionGrade, 'B');
      expect(result.toJson()['protein'], 18.2);
      expect(result.toJson()['carbs'], 26);
      expect(result.toJson()['fiber'], 1.5);
    });
  });
}
