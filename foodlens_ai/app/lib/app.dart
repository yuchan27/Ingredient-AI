import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'config/api_endpoint_store.dart';
import 'repositories/food_repository.dart';
import 'screens/dashboard_shell.dart';
import 'services/food_analysis_api.dart';
import 'theme/app_theme.dart';

enum AppMode { firebase, demo, setupRequired }

class FoodLensApp extends StatelessWidget {
  const FoodLensApp.firebase({super.key})
    : mode = AppMode.firebase,
      initializationFailed = false;
  const FoodLensApp.demo({super.key})
    : mode = AppMode.demo,
      initializationFailed = false;
  const FoodLensApp.setupRequired({
    super.key,
    this.initializationFailed = false,
  }) : mode = AppMode.setupRequired;

  final AppMode mode;
  final bool initializationFailed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FoodLens AI',
      theme: buildAppTheme(),
      home: switch (mode) {
        AppMode.demo => DashboardShell(
          repository: MemoryFoodRepository.demo(),
          api: FoodAnalysisApi(baseUrl: apiBaseUrl),
          accountEmail: 'demo@foodlens.app',
          isDemo: true,
          tokenProvider: () async => 'demo-token',
        ),
        AppMode.firebase => const _AuthGate(),
        AppMode.setupRequired => _SetupRequiredScreen(
          failed: initializationFailed,
        ),
      },
    );
  }
}

class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen({required this.failed});
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FoodLens AI')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  failed ? Icons.cloud_off_outlined : Icons.settings_outlined,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  failed ? 'Firebase 初始化失敗' : '尚未連結 Firebase',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  '請依 docs/setup.md 建立 Firebase 專案，並以 --dart-define-from-file 載入設定。\n\n只要預覽介面，可使用 DEMO_MODE=true 執行。',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const _AuthScreen();
        if (!user.emailVerified) return _VerifyEmailScreen(user: user);
        return _AuthenticatedDashboard(user: user);
      },
    );
  }
}

class _AuthenticatedDashboard extends StatefulWidget {
  const _AuthenticatedDashboard({required this.user});
  final User user;

  @override
  State<_AuthenticatedDashboard> createState() =>
      _AuthenticatedDashboardState();
}

class _AuthenticatedDashboardState extends State<_AuthenticatedDashboard> {
  late final FirebaseFoodRepository repository;
  late FoodAnalysisApi api;
  final _endpointStore = ApiEndpointStore();

  @override
  void initState() {
    super.initState();
    repository = FirebaseFoodRepository(uid: widget.user.uid);
    api = FoodAnalysisApi(baseUrl: apiBaseUrl);
    unawaited(_loadApiEndpoint());
  }

  Future<void> _loadApiEndpoint() async {
    final savedUrl = await _endpointStore.load(fallback: apiBaseUrl);
    if (mounted && savedUrl != api.baseUrl) {
      setState(() => api = FoodAnalysisApi(baseUrl: savedUrl));
    }
  }

  Future<void> _updateApiEndpoint(String value) async {
    await _endpointStore.save(value);
    if (mounted) {
      setState(
        () => api = FoodAnalysisApi(baseUrl: normalizeApiEndpoint(value)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => DashboardShell(
    repository: repository,
    api: api,
    accountEmail: widget.user.email ?? '已登入帳號',
    isDemo: false,
    tokenProvider: () async => (await widget.user.getIdToken(true)) ?? '',
    onApiBaseUrlChanged: _updateApiEndpoint,
    onLogout: () => FirebaseAuth.instance.signOut(),
  );
}

class _AuthScreen extends StatefulWidget {
  const _AuthScreen();

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_registering) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
        await credential.user?.sendEmailVerification();
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _authMessage(error.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.food_bank_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FoodLens AI',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _registering ? '建立帳號並開始記錄飲食' : '登入你的飲食分析空間',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : '請輸入有效 Email',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: '密碼',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) =>
                          (value?.length ?? 0) >= 6 ? null : '密碼至少 6 個字元',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _registering
                                  ? Icons.person_add_alt_1
                                  : Icons.login,
                            ),
                      label: Text(_registering ? '註冊帳號' : '登入'),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _registering = !_registering),
                      child: Text(_registering ? '已有帳號？回登入' : '還沒有帳號？免費註冊'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _authMessage(String code) => switch (code) {
  'email-already-in-use' => '這個 Email 已經註冊。',
  'invalid-credential' => 'Email 或密碼錯誤。',
  'weak-password' => '密碼強度不足。',
  'network-request-failed' => '網路連線失敗，請稍後再試。',
  _ => '無法完成操作，請檢查資料後再試。',
};

class _VerifyEmailScreen extends StatefulWidget {
  const _VerifyEmailScreen({required this.user});
  final User user;

  @override
  State<_VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<_VerifyEmailScreen> {
  bool _busy = false;

  Future<void> _refresh() async {
    setState(() => _busy = true);
    await widget.user.reload();
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          tooltip: '登出',
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                '驗證你的 Email',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                '驗證信已寄到 ${widget.user.email ?? ''}。完成後回來更新狀態。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('我已完成驗證'),
              ),
              TextButton(
                onPressed: () => widget.user.sendEmailVerification(),
                child: const Text('重寄驗證信'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
