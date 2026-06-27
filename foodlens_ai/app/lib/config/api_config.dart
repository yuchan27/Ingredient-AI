import 'package:flutter/foundation.dart';

String resolveApiBaseUrl({
  String configured = const String.fromEnvironment('API_BASE_URL'),
  TargetPlatform? platform,
  bool? isWeb,
}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  final resolvedIsWeb = isWeb ?? kIsWeb;
  final trimmed = configured.trim();
  if (trimmed.isNotEmpty) return trimmed.replaceFirst(RegExp(r'/+$'), '');
  if (!resolvedIsWeb && resolvedPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

final String apiBaseUrl = resolveApiBaseUrl();
