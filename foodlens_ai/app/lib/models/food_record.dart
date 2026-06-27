enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
    MealType.breakfast => '早餐',
    MealType.lunch => '午餐',
    MealType.dinner => '晚餐',
    MealType.snack => '點心',
  };
}

DateTime _dateTimeFrom(dynamic value, DateTime fallback) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? fallback;
  try {
    final converted = value?.toDate();
    if (converted is DateTime) return converted;
  } catch (_) {
    // Firestore Timestamp is intentionally handled without coupling this model.
  }
  return fallback;
}

double _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

class FoodRecord {
  const FoodRecord({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.confidence,
    required this.notes,
    required this.imagePath,
    this.imageUrl = '',
    required this.mealType,
    required this.cost,
    required this.eatenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodRecord.empty(String id) {
    final now = DateTime.now();
    return FoodRecord(
      id: id,
      foodName: '',
      calories: 0,
      protein: 0,
      fat: 0,
      carbs: 0,
      confidence: 0,
      notes: '',
      imagePath: '',
      mealType: MealType.lunch,
      cost: 0,
      eatenAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory FoodRecord.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return FoodRecord(
      id: id,
      foodName: '${map['foodName'] ?? ''}',
      calories: _number(map['calories']),
      protein: _number(map['protein']),
      fat: _number(map['fat']),
      carbs: _number(map['carbs']),
      confidence: _number(map['confidence']),
      notes: '${map['notes'] ?? ''}',
      imagePath: '${map['imagePath'] ?? ''}',
      imageUrl: '${map['imageUrl'] ?? ''}',
      mealType: MealType.values.firstWhere(
        (type) => type.name == map['mealType'],
        orElse: () => MealType.lunch,
      ),
      cost: _number(map['cost']),
      eatenAt: _dateTimeFrom(map['eatenAt'], now),
      createdAt: _dateTimeFrom(map['createdAt'], now),
      updatedAt: _dateTimeFrom(map['updatedAt'], now),
    );
  }

  final String id;
  final String foodName;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double confidence;
  final String notes;
  final String imagePath;
  final String imageUrl;
  final MealType mealType;
  final double cost;
  final DateTime eatenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
    'foodName': foodName,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'confidence': confidence,
    'notes': notes,
    'imagePath': imagePath,
    'imageUrl': imageUrl,
    'mealType': mealType.name,
    'cost': cost,
    'eatenAt': eatenAt,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  FoodRecord copyWith({
    String? foodName,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? confidence,
    String? notes,
    String? imagePath,
    String? imageUrl,
    MealType? mealType,
    double? cost,
    DateTime? eatenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FoodRecord(
    id: id,
    foodName: foodName ?? this.foodName,
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    fat: fat ?? this.fat,
    carbs: carbs ?? this.carbs,
    confidence: confidence ?? this.confidence,
    notes: notes ?? this.notes,
    imagePath: imagePath ?? this.imagePath,
    imageUrl: imageUrl ?? this.imageUrl,
    mealType: mealType ?? this.mealType,
    cost: cost ?? this.cost,
    eatenAt: eatenAt ?? this.eatenAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
