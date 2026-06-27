import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/app.dart';

void main() {
  testWidgets('shows actionable Firebase setup state', (tester) async {
    await tester.pumpWidget(const FoodLensApp.setupRequired());
    expect(find.text('食伴 AI'), findsOneWidget);
    expect(find.text('尚未連結 Firebase'), findsOneWidget);
    expect(find.textContaining('DEMO_MODE=true'), findsOneWidget);
  });
}
