import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apiBaseUrlKey = 'api_base_url';

bool apiEndpointOverridesEnabled({bool? isDebugMode}) =>
    isDebugMode ?? kDebugMode;

String normalizeApiEndpoint(String value) {
  final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw const FormatException('API URL must use http or https.');
  }
  return uri.toString();
}

class ApiEndpointStore {
  Future<String> load({required String fallback}) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_apiBaseUrlKey);
    if (saved != null) {
      try {
        return normalizeApiEndpoint(saved);
      } on FormatException {
        await preferences.remove(_apiBaseUrlKey);
      }
    }
    return normalizeApiEndpoint(fallback);
  }

  Future<void> save(String value) async {
    final normalized = normalizeApiEndpoint(value);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_apiBaseUrlKey, normalized);
    if (!saved) throw StateError('Could not save API URL.');
  }
}
