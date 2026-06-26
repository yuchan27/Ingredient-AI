import 'health_result.dart';

enum FoodEntrySource { ai, manual, import }

class FoodEntry {
  final int? id;
  final String localId;
  final String? cloudId;
  final String foodName;
  final DateTime consumedAt;
  final String mealType;
  final double servingSize;
  final String servingUnit;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double sodium;
  final double fiber;
  final int healthScore;
  final String notes;
  final FoodEntrySource source;
  final bool isPendingSync;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FoodEntry({
    this.id,
    required this.localId,
    this.cloudId,
    required this.foodName,
    required this.consumedAt,
    required this.mealType,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.sodium,
    required this.fiber,
    required this.healthScore,
    this.notes = '',
    required this.source,
    required this.isPendingSync,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory FoodEntry.fromHealthResult(
    HealthResult result, {
    required String localId,
    DateTime? consumedAt,
    String mealType = 'meal',
    double servingSize = 1,
    String servingUnit = 'serving',
    String notes = '',
  }) {
    final now = DateTime.now().toUtc();
    return FoodEntry(
      localId: localId,
      foodName: result.foodName,
      consumedAt: consumedAt ?? now,
      mealType: mealType,
      servingSize: servingSize,
      servingUnit: servingUnit,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
      sugar: result.sugar,
      sodium: result.sodium,
      fiber: result.fiber,
      healthScore: result.healthScore,
      notes: notes,
      source: FoodEntrySource.ai,
      isPendingSync: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: _asNullableInt(json['id']),
      localId: _asString(json['localId'] ?? json['local_id'], ''),
      cloudId: _asNullableString(json['cloudId'] ?? json['cloud_id']),
      foodName: _asString(json['foodName'] ?? json['food_name'], '未命名食物'),
      consumedAt: _asDateTime(json['consumedAt'] ?? json['consumed_at']),
      mealType: _asString(json['mealType'] ?? json['meal_type'], 'meal'),
      servingSize: _asDouble(json['servingSize'] ?? json['serving_size'], 1),
      servingUnit: _asString(json['servingUnit'] ?? json['serving_unit'], 'serving'),
      calories: _asInt(json['calories']),
      protein: _asDouble(json['protein']),
      carbs: _asDouble(json['carbs']),
      fat: _asDouble(json['fat']),
      sugar: _asDouble(json['sugar']),
      sodium: _asDouble(json['sodium']),
      fiber: _asDouble(json['fiber']),
      healthScore: _asInt(json['healthScore'] ?? json['health_score']),
      notes: _asString(json['notes'], ''),
      source: _asSource(json['source']),
      isPendingSync: _asBool(
        json['isPendingSync'] ?? json['is_pending_sync'] ?? json['syncStatus'],
        fallback: true,
      ),
      createdAt: _asDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _asDateTime(json['updatedAt'] ?? json['updated_at']),
      deletedAt: _asNullableDateTime(json['deletedAt'] ?? json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localId': localId,
      'cloudId': cloudId,
      'foodName': foodName,
      'consumedAt': consumedAt.toIso8601String(),
      'mealType': mealType,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'sodium': sodium,
      'fiber': fiber,
      'healthScore': healthScore,
      'notes': notes,
      'source': source.name,
      'isPendingSync': isPendingSync,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'localId': localId,
      'cloudId': cloudId,
      'foodName': foodName,
      'consumedAt': consumedAt.toIso8601String(),
      'mealType': mealType,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'sodium': sodium,
      'fiber': fiber,
      'healthScore': healthScore,
      'notes': notes,
      'source': source.name,
      'syncStatus': isPendingSync ? 'pending' : 'synced',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  FoodEntry copyWith({
    int? id,
    String? localId,
    String? cloudId,
    String? foodName,
    DateTime? consumedAt,
    String? mealType,
    double? servingSize,
    String? servingUnit,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sugar,
    double? sodium,
    double? fiber,
    int? healthScore,
    String? notes,
    FoodEntrySource? source,
    bool? isPendingSync,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      cloudId: cloudId ?? this.cloudId,
      foodName: foodName ?? this.foodName,
      consumedAt: consumedAt ?? this.consumedAt,
      mealType: mealType ?? this.mealType,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      fiber: fiber ?? this.fiber,
      healthScore: healthScore ?? this.healthScore,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  FoodEntry markSynced(String cloudId) {
    return copyWith(cloudId: cloudId, isPendingSync: false, updatedAt: DateTime.now().toUtc());
  }

  static String _asString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return (double.tryParse(value.trim()) ?? fallback).round();
    return fallback;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    return _asInt(value);
  }

  static double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'pending') return true;
      if (normalized == 'synced') return false;
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return fallback;
  }

  static DateTime _asDateTime(dynamic value) {
    return _asNullableDateTime(value) ?? DateTime.now().toUtc();
  }

  static DateTime? _asNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static FoodEntrySource _asSource(dynamic value) {
    final normalized = _asString(value, FoodEntrySource.manual.name);
    return FoodEntrySource.values.firstWhere(
      (source) => source.name == normalized,
      orElse: () => FoodEntrySource.manual,
    );
  }
}
