import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class FoodAnalysisResult {
  const FoodAnalysisResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.confidence,
    required this.notes,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) =>
      FoodAnalysisResult(
        foodName: '${json['foodName'] ?? ''}',
        calories: _number(json['calories']),
        protein: _number(json['protein']),
        fat: _number(json['fat']),
        carbs: _number(json['carbs']),
        confidence: _number(json['confidence']),
        notes: '${json['notes'] ?? ''}',
      );

  final String foodName;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double confidence;
  final String notes;
}

double _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

class FoodAnalysisException implements Exception {
  const FoodAnalysisException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FoodAnalysisApi {
  FoodAnalysisApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<FoodAnalysisResult> analyze({
    required XFile image,
    required String idToken,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/analyzeFoodImage'),
    )..headers['authorization'] = 'Bearer $idToken';
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        await image.readAsBytes(),
        filename: image.name.isEmpty ? 'food-image.jpg' : image.name,
        contentType: MediaType.parse(image.mimeType ?? 'image/jpeg'),
      ),
    );
    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 35));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw const FoodAnalysisException('食品分析失敗，請稍後再試。');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FoodAnalysisException('分析結果格式錯誤。');
    }
    return FoodAnalysisResult.fromJson(body);
  }
}
