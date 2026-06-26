import 'package:app_medium/services/cloud_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CloudSyncConfig', () {
    test('uses local-only mode when Neon API base URL is missing', () {
      final config = CloudSyncConfig.fromEnv(const {});

      expect(config.isConfigured, isFalse);
      expect(config.baseUrl, isNull);
    });

    test('normalizes Neon API base URL without trailing slash', () {
      final config = CloudSyncConfig.fromEnv(const {
        'NEON_API_BASE_URL': 'https://ingredient-ai-api.example.com/',
      });

      expect(config.isConfigured, isTrue);
      expect(config.baseUrl, 'https://ingredient-ai-api.example.com');
    });
  });
}
