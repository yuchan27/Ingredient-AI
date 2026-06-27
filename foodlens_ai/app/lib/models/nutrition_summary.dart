import 'food_record.dart';

class NutritionSummary {
  const NutritionSummary({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.cost,
  });

  factory NutritionSummary.forDay(List<FoodRecord> records, DateTime day) {
    final selected = records.where(
      (record) =>
          record.eatenAt.year == day.year &&
          record.eatenAt.month == day.month &&
          record.eatenAt.day == day.day,
    );
    return selected.fold(
      const NutritionSummary(
        calories: 0,
        protein: 0,
        fat: 0,
        carbs: 0,
        cost: 0,
      ),
      (sum, record) => NutritionSummary(
        calories: sum.calories + record.calories,
        protein: sum.protein + record.protein,
        fat: sum.fat + record.fat,
        carbs: sum.carbs + record.carbs,
        cost: sum.cost + record.cost,
      ),
    );
  }

  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double cost;

  double remainingCalories(double goal) =>
      (goal - calories).clamp(0, goal).toDouble();

  String nextMealSuggestion({double goalCalories = 2000}) {
    final remaining = remainingCalories(goalCalories);
    if (remaining <= 150) return '今日接近目標，可選擇無糖茶或低熱量水果。';
    if (protein < 60) return '下一餐建議高蛋白低油脂：雞胸、豆腐與兩份蔬菜。';
    if (fat > 70) return '下一餐建議清淡蒸煮，主食控制為半碗。';
    return '下一餐建議均衡份量：全穀主食、優質蛋白質與蔬菜。';
  }
}
