import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/services/food_analysis_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('analyze sends the Firebase token and image path', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'foodName': '鮮蔬雞胸',
          'calories': 420,
          'protein': 38,
          'fat': 12,
          'carbs': 42,
          'confidence': 0.9,
          'notes': '估算',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = FoodAnalysisApi(
      baseUrl: 'http://10.0.2.2:3000',
      client: client,
    );

    final result = await api.analyze(
      imagePath: 'users/u1/food_images/r1.jpg',
      idToken: 'token-1',
    );

    expect(captured.url.toString(), 'http://10.0.2.2:3000/analyzeFoodImage');
    expect(captured.headers['authorization'], 'Bearer token-1');
    expect(
      jsonDecode(captured.body)['imagePath'],
      'users/u1/food_images/r1.jpg',
    );
    expect(result.foodName, '鮮蔬雞胸');
    expect(result.protein, 38);
  });

  test('analyze surfaces a safe error for non-success responses', () async {
    final client = MockClient(
      (_) async => http.Response('{"error":"failed"}', 500),
    );
    final api = FoodAnalysisApi(
      baseUrl: 'http://localhost:3000',
      client: client,
    );
    await expectLater(
      api.analyze(imagePath: 'path', idToken: 'token'),
      throwsA(isA<FoodAnalysisException>()),
    );
  });
}
