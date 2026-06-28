import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/brand/brand_identity.dart';

void main() {
  test('defines the approved user-facing brand', () {
    expect(BrandIdentity.name, '食伴 AI');
    expect(BrandIdentity.tagline, '懂你每一餐');
    expect(BrandIdentity.versionLabel, '食伴 AI 1.0.1');
  });
}
