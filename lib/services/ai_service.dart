import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/health_result.dart';

class AIService {
  static const String _modelName = 'gemini-2.5-flash';

  Future<HealthResult> analyzeIngredients(File? imageFile, String inputFoodName) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    if (apiKey.isEmpty) throw Exception("API Key not found in .env");

    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );

    String promptText = """
你是一位專業的營養師。請分析這款產品。
產品名稱：'$inputFoodName'。

請執行分析並回傳 JSON。
注意：在 "healthy_reason", "risky_reason", "assessment" 欄位中：
1. 每一個要點必須以 "• " 開頭。
2. **重要：每一點之間必須使用「兩個換行符號 (\\n\\n)」分隔**，確保排版寬鬆易讀。
3. 對於關鍵詞請使用 **重點標記**。

回傳 JSON 格式如下：
{
  "food_name": "產品名稱",
  "healthy_ingredients": ["成分1", "成分2"],
  "risky_ingredients": ["成分1", "成分2"],
  "healthy_reason": "• 第一點\\n\\n• 第二點",
  "risky_reason": "• 第一點\\n\\n• 第二點",
  "health_score": 85,
  "calories": 數值,
  "sugar": 數值,
  "sodium": 數值,
  "fat": 數值,
  "assessment": "• 評估1\\n\\n• 評估2",
  "recommendation": "建議"
}
""";

    final List<Content> content = [];
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      content.add(Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', bytes),
      ]));
    } else {
      content.add(Content.text(promptText));
    }

    try {
      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null) throw Exception("AI 未能產生內容");
      
      String cleanedText = text.trim();
      if (cleanedText.startsWith("```json")) {
        cleanedText = cleanedText.substring(7).trim();
      }
      if (cleanedText.endsWith("```")) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3).trim();
      }

      return HealthResult.fromJson(jsonDecode(cleanedText));
    } catch (e) {
      if (e.toString().contains("503")) {
        throw Exception("伺服器繁忙，請稍後再試。");
      }
      rethrow;
    }
  }
}
