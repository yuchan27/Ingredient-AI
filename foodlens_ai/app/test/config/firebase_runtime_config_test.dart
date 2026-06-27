import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/config/firebase_runtime_config.dart';

void main() {
  test('Spark configuration does not require a Storage bucket', () {
    const config = FirebaseRuntimeConfig(
      apiKey: 'api-key',
      appId: 'app-id',
      messagingSenderId: 'sender-id',
      projectId: 'project-id',
      storageBucket: '',
    );

    expect(config.isConfigured, isTrue);
    expect(config.options.storageBucket, isNull);
  });
}
