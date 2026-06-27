import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/brand/brand_mark.dart';

void main() {
  testWidgets('renders the approved app icon at the requested size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandMark(size: 72))),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 72);
    expect(image.height, 72);
  });
}
