import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/services/food_analysis_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test(
    'analyze sends the Firebase token and image as multipart data',
    () async {
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
            'quota': {'limit': 5, 'used': 2, 'remaining': 3},
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
        image: XFile.fromData(
          Uint8List.fromList('fake-image'.codeUnits),
          mimeType: 'image/jpeg',
          name: 'meal.jpg',
        ),
        idToken: 'token-1',
      );

      expect(captured.url.toString(), 'http://10.0.2.2:3000/analyzeFoodImage');
      expect(captured.headers['authorization'], 'Bearer token-1');
      expect(
        captured.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(captured.body, contains('name="image"'));
      expect(captured.body, contains('filename="food-image.jpg"'));
      expect(captured.body, contains('fake-image'));
      expect(result.foodName, '鮮蔬雞胸');
      expect(result.protein, 38);
      expect(result.quota?.limit, 5);
      expect(result.quota?.remaining, 3);
    },
  );

  test('analyze surfaces a safe error for non-success responses', () async {
    final client = MockClient(
      (_) async => http.Response('{"error":"failed"}', 500),
    );
    final api = FoodAnalysisApi(
      baseUrl: 'http://localhost:3000',
      client: client,
    );
    await expectLater(
      api.analyze(
        image: XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
          name: 'meal.jpg',
        ),
        idToken: 'token',
      ),
      throwsA(isA<FoodAnalysisException>()),
    );
  });

  test('analyze surfaces the server quota message for HTTP 429', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': '今天的 AI 次數已用完，請明天再試。',
          'quota': {'limit': 5, 'used': 5, 'remaining': 0},
        }),
        429,
        headers: {'content-type': 'application/json'},
      ),
    );
    final api = FoodAnalysisApi(
      baseUrl: 'https://food.example.run.app',
      client: client,
    );

    await expectLater(
      api.analyze(
        image: XFile.fromData(Uint8List.fromList([1, 2, 3])),
        idToken: 'guest-token',
      ),
      throwsA(
        isA<FoodAnalysisException>()
            .having((error) => error.message, 'message', contains('明天再試'))
            .having((error) => error.quota?.remaining, 'remaining', 0),
      ),
    );
  });
}
