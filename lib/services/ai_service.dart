import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/health_result.dart';

class AIService {
  static const String _modelName = 'gemini-2.5-flash';

  Future<HealthResult> analyzeIngredients(
    File? imageFile,
    String inputFoodName,
  ) async {
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

    final promptText =
        """
你是一位營養標示與飲食紀錄分析助手。請根據使用者輸入的食物名稱與圖片，回傳繁體中文 JSON。

使用者輸入食物名稱：$inputFoodName

分析規則：
1. 如果圖片是營養標示，優先讀取每份營養數字，例如熱量、蛋白質、脂肪、糖、鈉、碳水化合物。
2. 如果圖片是食物照片但沒有標示，請用常見份量估算，並在 assessment 說明是估算。
3. health_score 使用 0 到 100 分，分數越高代表越適合日常攝取。
4. sodium 單位是 mg，其餘 protein、carbs、fat、sugar、fiber 單位是 g，calories 單位是 kcal。
5. healthy_reason、risky_reason、assessment 請用 2 到 4 句可讀中文，不要使用 Markdown 標題。
6. recommendation 請是一句很短的建議，例如「可作為午餐，但晚餐請低鈉」。

請只回傳以下 JSON 物件，不要加任何其他文字：
{
  "food_name": "食物名稱",
  "healthy_ingredients": ["可保留或正向成分"],
  "risky_ingredients": ["需要留意的成分"],
  "healthy_reason": "可保留成分的原因",
  "risky_reason": "需要留意的原因",
  "health_score": 65,
  "calories": 282,
  "sugar": 3.8,
  "sodium": 664,
  "fat": 11.6,
  "protein": 16.9,
  "carbs": 27.6,
  "fiber": 0,
  "assessment": "整體營養分析",
  "recommendation": "下一餐建議"
}
""";

    final List<Content> content = [];
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      content.add(
        Content.multi([TextPart(promptText), DataPart('image/jpeg', bytes)]),
      );
    } else {
      content.add(Content.text(promptText));
    }

    try {
      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null) throw Exception("AI 沒有回傳分析內容。");

      var cleanedText = text.trim();
      if (cleanedText.startsWith("```json")) {
        cleanedText = cleanedText.substring(7).trim();
      }
      if (cleanedText.endsWith("```")) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3).trim();
      }

      return HealthResult.fromJson(
        jsonDecode(cleanedText) as Map<String, dynamic>,
      );
    } catch (e) {
      if (e.toString().contains("503")) {
        throw Exception("AI 服務目前忙碌，請稍後再試。");
      }
      rethrow;
    }
  }
}
