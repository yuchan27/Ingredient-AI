class HealthResult {
  final String foodName;
  final List<String> healthyIngredients;
  final List<String> riskyIngredients;
  final String healthyReason;
  final String riskyReason;
  final int healthScore;
  final int calories;
  final double sugar;
  final double sodium;
  final double fat;
  final double protein;
  final double carbs;
  final double fiber;
  final String assessment;
  final String recommendation;

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
    this.protein = 0,
    this.carbs = 0,
    this.fiber = 0,
    required this.assessment,
    required this.recommendation,
  });

  factory HealthResult.fromJson(Map<String, dynamic> json) {
    return HealthResult(
      foodName: _asString(json['food_name'] ?? json['foodName'], '未命名產品'),
      healthyIngredients: _asStringList(
        json['healthy_ingredients'] ?? json['healthyIngredients'],
      ),
      riskyIngredients: _asStringList(
        json['risky_ingredients'] ?? json['riskyIngredients'],
      ),
      healthyReason: _asString(
        json['healthy_reason'] ?? json['healthyReason'],
        '',
      ),
      riskyReason: _asString(json['risky_reason'] ?? json['riskyReason'], ''),
      healthScore: _asInt(json['health_score'] ?? json['healthScore']),
      calories: _asInt(json['calories']),
      sugar: _asDouble(json['sugar']),
      sodium: _asDouble(json['sodium']),
      fat: _asDouble(json['fat']),
      protein: _asDouble(json['protein']),
      carbs: _asDouble(json['carbs']),
      fiber: _asDouble(json['fiber']),
      assessment: _asString(json['assessment'], ''),
      recommendation: _asString(json['recommendation'], ''),
    );
  }

  String get nutritionGrade {
    if (healthScore >= 85) return 'A';
    if (healthScore >= 70) return 'B';
    if (healthScore >= 55) return 'C';
    if (healthScore >= 40) return 'D';
    return 'E';
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
      'protein': protein,
      'carbs': carbs,
      'fiber': fiber,
      'assessment': assessment,
      'recommendation': recommendation,
    };
  }

  static String _asString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return (double.tryParse(value.trim()) ?? 0).round();
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
