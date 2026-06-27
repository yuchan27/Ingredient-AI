import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/config/api_config.dart';

void main() {
  test('Android defaults to the emulator host bridge', () {
    expect(
      resolveApiBaseUrl(platform: TargetPlatform.android, isWeb: false),
      'http://10.0.2.2:3000',
    );
  });

  test('web and desktop default to localhost', () {
    expect(
      resolveApiBaseUrl(platform: TargetPlatform.windows, isWeb: false),
      'http://localhost:3000',
    );
    expect(
      resolveApiBaseUrl(platform: TargetPlatform.android, isWeb: true),
      'http://localhost:3000',
    );
  });

  test('explicit API URL wins and trailing slashes are removed', () {
    expect(
      resolveApiBaseUrl(
        configured: 'https://foodlens.example.run.app/',
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      'https://foodlens.example.run.app',
    );
  });
}
