import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'db_service.dart';

class CloudSyncConfig {
  final String? baseUrl;

  const CloudSyncConfig({this.baseUrl});

  bool get isConfigured => baseUrl != null && baseUrl!.isNotEmpty;

  factory CloudSyncConfig.fromEnv(Map<String, String> env) {
    final rawBaseUrl = env['NEON_API_BASE_URL']?.trim();
    if (rawBaseUrl == null || rawBaseUrl.isEmpty) {
      return const CloudSyncConfig();
    }
    return CloudSyncConfig(baseUrl: _stripTrailingSlash(rawBaseUrl));
  }

  static String _stripTrailingSlash(String value) {
    var normalized = value;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}

class CloudSyncState {
  final bool isConfigured;
  final bool isSignedIn;
  final String? email;
  final String message;

  const CloudSyncState({
    required this.isConfigured,
    required this.isSignedIn,
    this.email,
    required this.message,
  });

  const CloudSyncState.localOnly([
    String message = '尚未設定 Neon API，正在使用本地模式',
  ]) : this(
          isConfigured: false,
          isSignedIn: false,
          message: message,
        );
}

class CloudSyncResult {
  final bool attempted;
  final int uploadedHistoryCount;
  final int uploadedFoodEntryCount;
  final String message;

  const CloudSyncResult({
    required this.attempted,
    required this.uploadedHistoryCount,
    required this.uploadedFoodEntryCount,
    required this.message,
  });
}

class CloudSyncService {
  final DBService dbService;
  final http.Client _client;
  final CloudSyncConfig Function() _configProvider;

  CloudSyncService({
    DBService? dbService,
    http.Client? client,
    CloudSyncConfig Function()? configProvider,
  })  : dbService = dbService ?? DBService(),
        _client = client ?? http.Client(),
        _configProvider = configProvider ??
            (() => CloudSyncConfig.fromEnv(
                  dotenv.env.map((key, value) => MapEntry(key, value)),
                ));

  Future<CloudSyncState> initialize() async {
    final config = _configProvider();
    if (!config.isConfigured) {
      return const CloudSyncState.localOnly(
        '尚未設定 Neon API，資料會先保存在本地',
      );
    }

    final profile = await dbService.getUserProfile();
    final email = profile?['email']?.toString();
    final authToken = profile?['authToken']?.toString();
    final isSignedIn = authToken != null && authToken.isNotEmpty;

    return CloudSyncState(
      isConfigured: true,
      isSignedIn: isSignedIn,
      email: email,
      message: isSignedIn ? 'Neon 雲端同步已啟用' : 'Neon API 已設定，請登入帳號同步資料',
    );
  }

  Future<CloudSyncState> signUp(String email, String password) async {
    return _authenticate('/auth/signup', email, password);
  }

  Future<CloudSyncState> signIn(String email, String password) async {
    return _authenticate('/auth/login', email, password);
  }

  Future<CloudSyncState> signOut() async {
    final profile = await dbService.getUserProfile();
    await dbService.saveUserProfile(
      localUserId: profile?['localUserId']?.toString() ?? 'local',
      email: null,
      cloudUserId: null,
      authToken: null,
    );
    return initialize();
  }

  Future<CloudSyncResult> syncPending() async {
    final config = _configProvider();
    if (!config.isConfigured) {
      return const CloudSyncResult(
        attempted: false,
        uploadedHistoryCount: 0,
        uploadedFoodEntryCount: 0,
        message: '尚未設定 Neon API，資料已保存在本地',
      );
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.contains(ConnectivityResult.none)) {
      return const CloudSyncResult(
        attempted: false,
        uploadedHistoryCount: 0,
        uploadedFoodEntryCount: 0,
        message: '目前離線，資料已保留在本地，恢復網路後可同步',
      );
    }

    final profile = await dbService.getUserProfile();
    final authToken = profile?['authToken']?.toString();
    if (authToken == null || authToken.isEmpty) {
      return const CloudSyncResult(
        attempted: false,
        uploadedHistoryCount: 0,
        uploadedFoodEntryCount: 0,
        message: '請先登入 Neon 帳號再同步雲端',
      );
    }

    int historyCount = 0;
    int foodEntryCount = 0;

    final pendingHistory = await dbService.getPendingHistory();
    if (pendingHistory.isNotEmpty) {
      final response = await _postJson(
        config,
        '/sync/history',
        authToken,
        {
          'items': pendingHistory.map(_historyPayload).toList(),
        },
      );
      final synced = response['synced'] as List<dynamic>? ?? const [];
      for (final item in synced) {
        if (item is! Map<String, dynamic>) continue;
        final localDbId = item['localDbId'];
        final cloudId = item['cloudId']?.toString();
        if (localDbId is int && cloudId != null) {
          await dbService.markHistorySynced(localDbId, cloudId);
          historyCount++;
        }
      }
    }

    final pendingFoodEntries = await dbService.getPendingFoodEntries();
    if (pendingFoodEntries.isNotEmpty) {
      final response = await _postJson(
        config,
        '/sync/food-entries',
        authToken,
        {
          'items': pendingFoodEntries.map((entry) => entry.toJson()).toList(),
        },
      );
      final synced = response['synced'] as List<dynamic>? ?? const [];
      for (final item in synced) {
        if (item is! Map<String, dynamic>) continue;
        final localId = item['localId']?.toString();
        final cloudId = item['cloudId']?.toString();
        if (localId != null && cloudId != null) {
          await dbService.markFoodEntrySynced(localId, cloudId);
          foodEntryCount++;
        }
      }
    }

    return CloudSyncResult(
      attempted: true,
      uploadedHistoryCount: historyCount,
      uploadedFoodEntryCount: foodEntryCount,
      message: '已同步 $historyCount 筆分析紀錄、$foodEntryCount 筆飲食紀錄到 Neon',
    );
  }

  Future<CloudSyncState> _authenticate(
    String path,
    String email,
    String password,
  ) async {
    final config = _configProvider();
    if (!config.isConfigured) {
      return const CloudSyncState.localOnly(
        '尚未設定 Neon API，無法登入雲端帳號',
      );
    }

    final payload = await _postJson(config, path, null, {
      'email': email,
      'password': password,
    });

    final token = payload['token']?.toString();
    final user = payload['user'];
    if (token == null || token.isEmpty || user is! Map<String, dynamic>) {
      throw const FormatException('Neon API 登入回應缺少 token 或 user');
    }

    final cloudUserId = user['id']?.toString();
    final normalizedEmail = user['email']?.toString() ?? email;
    await dbService.saveUserProfile(
      localUserId: cloudUserId ?? 'local',
      email: normalizedEmail,
      cloudUserId: cloudUserId,
      authToken: token,
    );
    return initialize();
  }

  Future<Map<String, dynamic>> _postJson(
    CloudSyncConfig config,
    String path,
    String? authToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('${config.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(body),
    );

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] ?? 'Neon API request failed');
    }
    return decoded;
  }

  static Map<String, dynamic> _historyPayload(Map<String, dynamic> row) {
    return {
      'localDbId': row['id'],
      'localId': row['localId'] ?? 'history_${row['id']}',
      'date': row['date'],
      'imagePath': row['imagePath'],
      'result': _decodeResult(row['resultJson']),
    };
  }

  static Object? _decodeResult(Object? value) {
    if (value is! String) return value;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }
}
