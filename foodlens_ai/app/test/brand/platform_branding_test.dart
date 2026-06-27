import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platform metadata uses the approved brand', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="食伴 AI"'));

    final webManifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(webManifest['name'], '食伴 AI');
    expect(webManifest['short_name'], '食伴 AI');
    expect(webManifest['background_color'], '#1F7658');
    expect(webManifest['theme_color'], '#1F7658');

    final webIndex = File('web/index.html').readAsStringSync();
    expect(webIndex, contains('<title>食伴 AI</title>'));
    expect(
      webIndex,
      contains('name="apple-mobile-web-app-title" content="食伴 AI"'),
    );

    final windowsMain = File('windows/runner/main.cpp').readAsStringSync();
    expect(windowsMain, contains('window.Create(L"食伴 AI"'));
    final windowsResources = File(
      'windows/runner/Runner.rc',
    ).readAsStringSync();
    expect(
      windowsResources,
      contains('VALUE "ProductName", "食伴 AI"'),
    );
  });
}
