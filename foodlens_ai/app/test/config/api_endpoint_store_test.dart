import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodlens_ai_app/config/api_endpoint_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('normalizes and persists a physical-device API URL', () async {
    final store = ApiEndpointStore();

    await store.save('https://foodlens.example.com///');

    expect(
      await store.load(fallback: 'http://10.0.2.2:3000'),
      'https://foodlens.example.com',
    );
  });

  test('rejects invalid API URLs without replacing the saved value', () async {
    final store = ApiEndpointStore();
    await store.save('https://foodlens.example.com');

    expect(() => store.save('foodlens.example.com'), throwsFormatException);
    expect(
      await store.load(fallback: 'http://10.0.2.2:3000'),
      'https://foodlens.example.com',
    );
  });

  test('uses the normalized fallback when no override is saved', () async {
    final store = ApiEndpointStore();

    expect(
      await store.load(fallback: 'http://10.0.2.2:3000/'),
      'http://10.0.2.2:3000',
    );
  });
}
