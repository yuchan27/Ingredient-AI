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

  testWidgets('login and registration present clearly different forms', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.text('登入食伴 AI'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('確認密碼'), findsNothing);

    await tester.tap(find.text('建立帳號'));
    await tester.pump();

    expect(find.text('建立食伴 AI 帳號'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('確認密碼'), findsOneWidget);
  });

  testWidgets('registration blocks mismatched password confirmation', (
    tester,
  ) async {
    var registrationAttempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onRegister: (_, __) async => registrationAttempts += 1,
        ),
      ),
    );

    await tester.tap(find.text('建立帳號'));
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'user@example.com');
    await tester.enterText(fields.at(1), 'secret1');
    await tester.enterText(fields.at(2), 'different1');
    await tester.tap(find.text('建立帳號並寄出驗證信'));
    await tester.pump();

    expect(find.text('兩次輸入的密碼不一致'), findsOneWidget);
    expect(registrationAttempts, 0);
  });

  testWidgets('registration sends the exact entered email address', (
    tester,
  ) async {
    String? submittedEmail;
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onRegister: (email, _) async => submittedEmail = email,
        ),
      ),
    );

    await tester.tap(find.text('建立帳號'));
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'C112151139@nkust.edu.tw');
    await tester.enterText(fields.at(1), 'secret1');
    await tester.enterText(fields.at(2), 'secret1');
    await tester.tap(find.text('建立帳號並寄出驗證信'));
    await tester.pumpAndSettle();

    expect(submittedEmail, 'C112151139@nkust.edu.tw');
  });

  testWidgets('configured Google sign-in shows progress and success feedback', (
    tester,
  ) async {
    final completer = Completer<void>();
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          googleSignInAvailable: true,
          onGoogleSignIn: () {
            attempts += 1;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('使用 Google 繼續'));
    await tester.pump();
    expect(attempts, 1);
    expect(find.text('正在連接 Google…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pump();
    expect(find.text('Google 登入成功。'), findsOneWidget);
  });

  testWidgets('registration shows loading and success feedback', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(onRegister: (_, __) => completer.future)),
    );

    await tester.tap(find.text('建立帳號'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
    await tester.tap(find.text('建立帳號並寄出驗證信'));
    await tester.pump();

    expect(find.text('正在建立帳號…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pump();
    expect(find.textContaining('Firebase 雲端已接受寄信請求'), findsOneWidget);
    expect(find.textContaining('不需要開發電腦開機'), findsOneWidget);
  });

  testWidgets('verification resend shows loading success and cooldown', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: VerifyEmailScreen(
          email: 'user@example.com',
          onRefresh: () async => false,
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

  testWidgets('verification refresh shows completed feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VerifyEmailScreen(
          email: 'user@example.com',
          onRefresh: () async => true,
          onResend: () async {},
          onSignOut: () async {},
        ),
      ),
    );

    await tester.tap(find.text('我已完成驗證'));
    await tester.pumpAndSettle();

    expect(find.text('Email 驗證已完成。'), findsNWidgets(2));
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('verification refresh shows pending feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VerifyEmailScreen(
          email: 'user@example.com',
          onRefresh: () async => false,
          onResend: () async {},
          onSignOut: () async {},
        ),
      ),
    );

    await tester.tap(find.text('我已完成驗證'));
    await tester.pumpAndSettle();

    expect(find.text('尚未完成驗證。信件可能仍在傳送，請稍候片刻，並檢查垃圾郵件後再試。'), findsNWidgets(2));
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('verification refresh shows failure feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VerifyEmailScreen(
          email: 'user@example.com',
          onRefresh: () => Future<bool>.error(StateError('network')),
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
