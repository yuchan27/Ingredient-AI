import '../models/food_entry.dart';
import 'nutrition_analytics_service.dart';

class MealRecommendation {
  final String title;
  final String suggestedMealType;
  final String calorieRangeLabel;
  final List<String> foodIdeas;
  final List<String> keyReasons;

  const MealRecommendation({
    required this.title,
    required this.suggestedMealType,
    required this.calorieRangeLabel,
    required this.foodIdeas,
    required this.keyReasons,
  });
}

class DailyDietPlan {
  final DailyNutritionSummary summary;
  final int calorieGoal;
  final double sodiumGoal;
  final double fiberGoal;
  final int remainingCalories;
  final MealRecommendation nextMeal;
  final List<String> alerts;

  const DailyDietPlan({
    required this.summary,
    required this.calorieGoal,
    required this.sodiumGoal,
    required this.fiberGoal,
    required this.remainingCalories,
    required this.nextMeal,
    required this.alerts,
  });

  double get calorieProgress {
    if (calorieGoal <= 0) return 0;
    return (summary.totalCalories / calorieGoal).clamp(0, 1);
  }
}

class DietPlanningService {
  static const defaultCalorieGoal = 2000;
  static const defaultSodiumGoal = 2000.0;
  static const defaultFiberGoal = 25.0;

  const DietPlanningService();

  DailyDietPlan buildTodayPlan(
    List<FoodEntry> entries, {
    DateTime? now,
    int calorieGoal = defaultCalorieGoal,
    double sodiumGoal = defaultSodiumGoal,
    double fiberGoal = defaultFiberGoal,
  }) {
    final referenceTime = now ?? DateTime.now();
    final summary = NutritionAnalyticsService.summaryForDate(
      entries,
      referenceTime,
    );
    final remainingCalories = (calorieGoal - summary.totalCalories)
        .clamp(0, calorieGoal)
        .toInt();
    final alerts = _buildAlerts(summary, sodiumGoal, fiberGoal);
    final recommendation = _recommendNextMeal(
      summary,
      referenceTime,
      remainingCalories,
      sodiumGoal,
      fiberGoal,
    );

    return DailyDietPlan(
      summary: summary,
      calorieGoal: calorieGoal,
      sodiumGoal: sodiumGoal,
      fiberGoal: fiberGoal,
      remainingCalories: remainingCalories,
      nextMeal: recommendation,
      alerts: alerts,
    );
  }

  List<String> _buildAlerts(
    DailyNutritionSummary summary,
    double sodiumGoal,
    double fiberGoal,
  ) {
    final alerts = <String>[];
    if (summary.totalSodium >= sodiumGoal * 0.3) {
      alerts.add('鈉攝取已達 ${summary.totalSodium.round()} mg，今天剩下餐點請優先低鈉。');
    }
    if (summary.totalFiber < fiberGoal * 0.35 && summary.entryCount > 0) {
      alerts.add('膳食纖維偏低，下一餐建議加入蔬菜、豆類或全穀。');
    }
    if (summary.totalCalories >= defaultCalorieGoal * 0.8) {
      alerts.add('今日熱量接近上限，下一餐份量請放輕。');
    }
    return alerts;
  }

  MealRecommendation _recommendNextMeal(
    DailyNutritionSummary summary,
    DateTime now,
    int remainingCalories,
    double sodiumGoal,
    double fiberGoal,
  ) {
    final mealType = _nextMealType(now);
    final highSodium = summary.totalSodium >= sodiumGoal * 0.3;
    final lowFiber = summary.totalFiber < fiberGoal * 0.35;
    final title = highSodium || lowFiber ? '下一餐建議：低鈉高纖餐' : '下一餐建議：均衡補足餐';
    final maxCalories = remainingCalories >= 650
        ? 650
        : remainingCalories.clamp(350, 650).toInt();
    final minCalories = maxCalories <= 450 ? 300 : 450;

    final reasons = <String>[];
    if (highSodium) {
      reasons.add('午餐鈉含量偏高，晚餐建議避開炸物與重鹹醬料。');
    }
    if (lowFiber) {
      reasons.add('目前纖維不足，可用蔬菜、菇類、燕麥或豆腐補足。');
    }
    if (summary.totalProtein < 55) {
      reasons.add('蛋白質仍可補強，優先選擇雞胸、魚、豆腐或蛋。');
    }
    if (reasons.isEmpty) {
      reasons.add('今日營養分布穩定，下一餐維持蛋白質、蔬菜、主食各一份。');
    }

    return MealRecommendation(
      title: title,
      suggestedMealType: mealType,
      calorieRangeLabel: '$minCalories-$maxCalories kcal',
      foodIdeas: const ['烤雞胸 + 燙青菜 + 半碗糙米飯', '豆腐蔬菜湯 + 地瓜', '鮭魚沙拉 + 無糖優格'],
      keyReasons: reasons,
    );
  }

  String _nextMealType(DateTime now) {
    if (now.hour < 10) return 'lunch';
    if (now.hour < 15) return 'snack';
    if (now.hour < 21) return 'dinner';
    return 'breakfast';
  }
}
