import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/app.dart';

void main() {
  testWidgets('shows actionable Firebase setup state', (tester) async {
    await tester.pumpWidget(const FoodLensApp.setupRequired());
    expect(find.text('食伴 AI'), findsOneWidget);
    expect(find.text('尚未連結 Firebase'), findsOneWidget);
    expect(find.textContaining('DEMO_MODE=true'), findsOneWidget);
  });

  testWidgets(
    'guest entry shows a busy state and explains local-only storage',
    (tester) async {
      final completer = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(onContinueLocally: () => completer.future),
        ),
      );

      expect(find.text('先用本機模式'), findsOneWidget);
      expect(find.textContaining('不跨裝置同步'), findsOneWidget);

      await tester.tap(find.text('先用本機模式'));
      await tester.pump();
      expect(find.text('正在啟用本機模式…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pump();
      expect(find.text('本機模式已啟用。'), findsOneWidget);
    },
  );

  testWidgets('registration shows loading and success feedback', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(onRegister: (_, __) => completer.future)),
    );

    await tester.tap(find.text('還沒有帳號？免費註冊'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.tap(find.text('註冊帳號'));
    await tester.pump();

    expect(find.text('正在建立帳號…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pump();
    expect(find.text('帳號已建立，請完成 Email 驗證。'), findsOneWidget);
  });

  testWidgets('verification resend shows loading success and cooldown', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: VerifyEmailScreen(
          email: 'user@example.com',
          onRefresh: () async {},
          onResend: () => completer.future,
          onSignOut: () async {},
          resendCooldown: const Duration(seconds: 2),
        ),
      ),
    );

    await tester.tap(find.text('重寄驗證信'));
    await tester.pump();
    expect(find.text('正在重寄驗證信…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pump();
    expect(find.text('驗證信已重新寄出，請檢查收件匣。'), findsNWidgets(2));
    expect(find.textContaining('2 秒'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('1 秒'), findsOneWidget);
  });

  testWidgets('verification refresh shows failure feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VerifyEmailScreen(
          email: 'user@example.com',
          onRefresh: () => Future<void>.error(StateError('network')),
          onResend: () async {},
          onSignOut: () async {},
        ),
      ),
    );

    await tester.tap(find.text('我已完成驗證'));
    await tester.pumpAndSettle();

    expect(find.text('無法更新驗證狀態，請稍後再試。'), findsNWidgets(2));
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
