class HealthResult {
  String foodName;
  List<String> healthyIngredients;
  List<String> riskyIngredients;
  String healthyReason;
  String riskyReason;
  int healthScore;
  int calories;
  double sugar;
  double sodium;
  double fat;
  String assessment;
  String recommendation;

  HealthResult({
    required this.foodName,
    required this.healthyIngredients,
    required this.riskyIngredients,
    required this.healthyReason,
    required this.riskyReason,
    required this.healthScore,
    required this.calories,
    required this.sugar,
    required this.sodium,
    required this.fat,
    required this.assessment,
    required this.recommendation,
  });

  factory HealthResult.fromJson(Map<String, dynamic> json) {
    return HealthResult(
      foodName: json['food_name'] ?? '未命名產品',
      healthyIngredients: List<String>.from(json['healthy_ingredients'] ?? []),
      riskyIngredients: List<String>.from(json['risky_ingredients'] ?? []),
      healthyReason: json['healthy_reason'] ?? '',
      riskyReason: json['risky_reason'] ?? '',
      healthScore: json['health_score'] ?? 0,
      calories: json['calories'] ?? 0,
      sugar: (json['sugar'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      assessment: json['assessment'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'healthy_ingredients': healthyIngredients,
      'risky_ingredients': riskyIngredients,
      'healthy_reason': healthyReason,
      'risky_reason': riskyReason,
      'health_score': healthScore,
      'calories': calories,
      'sugar': sugar,
      'sodium': sodium,
      'fat': fat,
      'assessment': assessment,
      'recommendation': recommendation,
    };
  }
}
