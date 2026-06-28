import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/screens/record_screens.dart';
import 'package:foodlens_ai_app/services/food_analysis_api.dart';

void main() {
  testWidgets('quota status shows the server message and remaining allowance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnalysisStatusMessage(
            message: '今天的 AI 次數已用完，請明天再試。',
            quota: AiQuota(limit: 5, used: 5, remaining: 0),
            isError: true,
          ),
        ),
      ),
    );

    expect(find.textContaining('今天的 AI 次數已用完'), findsOneWidget);
    expect(find.textContaining('每日上限 5 次，今日剩餘 0 次'), findsOneWidget);
  });
}
