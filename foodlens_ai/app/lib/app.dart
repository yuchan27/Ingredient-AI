import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth/auth_action_state.dart';
import 'brand/brand_identity.dart';
import 'brand/brand_mark.dart';
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
      title: BrandIdentity.name,
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
      appBar: AppBar(title: const Text(BrandIdentity.name)),
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
        if (user == null) return const AuthScreen();
        if (user.isAnonymous) return _LocalDashboard(user: user);
        if (!user.emailVerified) {
          return VerifyEmailScreen(
            email: user.email ?? '',
            onRefresh: () async {
              await user.reload();
              await FirebaseAuth.instance.currentUser?.getIdToken(true);
            },
            onResend: user.sendEmailVerification,
            onSignOut: FirebaseAuth.instance.signOut,
          );
        }
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

class _LocalDashboard extends StatefulWidget {
  const _LocalDashboard({required this.user});
  final User user;

  @override
  State<_LocalDashboard> createState() => _LocalDashboardState();
}

class _LocalDashboardState extends State<_LocalDashboard> {
  late final LocalFoodRepository repository;
  late FoodAnalysisApi api;
  final _endpointStore = ApiEndpointStore();

  @override
  void initState() {
    super.initState();
    repository = LocalFoodRepository();
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
    accountEmail: '本機模式',
    isDemo: false,
    isLocalOnly: true,
    tokenProvider: () async => (await widget.user.getIdToken(true)) ?? '',
    onApiBaseUrlChanged: _updateApiEndpoint,
    onLogout: () => FirebaseAuth.instance.signOut(),
  );
}

typedef AuthCredentialAction =
    Future<void> Function(String email, String password);

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.onSignIn,
    this.onRegister,
    this.onContinueLocally,
  });

  final AuthCredentialAction? onSignIn;
  final AuthCredentialAction? onRegister;
  final Future<void> Function()? onContinueLocally;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  AuthActionState _action = const AuthActionState.idle();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _action = AuthActionState.loading(_registering ? '正在建立帳號…' : '正在登入…');
    });
    try {
      if (_registering) {
        if (widget.onRegister != null) {
          await widget.onRegister!(_email.text.trim(), _password.text);
        } else {
          final credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: _email.text.trim(),
                password: _password.text,
              );
          if (mounted) {
            setState(
              () => _action = const AuthActionState.loading('帳號已建立，正在寄送驗證信…'),
            );
          }
          await credential.user?.sendEmailVerification();
        }
        if (mounted) {
          setState(
            () =>
                _action = const AuthActionState.success('帳號已建立，請完成 Email 驗證。'),
          );
        }
      } else {
        if (widget.onSignIn != null) {
          await widget.onSignIn!(_email.text.trim(), _password.text);
        } else {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
        }
        if (mounted) {
          setState(() => _action = const AuthActionState.success('登入成功。'));
        }
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _action = AuthActionState.error(_authMessage(error.code)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _action = const AuthActionState.error('無法完成操作，請稍後再試。'));
      }
    }
  }

  Future<void> _continueLocally() async {
    setState(() {
      _action = const AuthActionState.loading('正在啟用本機模式…');
    });
    try {
      if (widget.onContinueLocally != null) {
        await widget.onContinueLocally!();
      } else {
        await FirebaseAuth.instance.signInAnonymously();
      }
      if (mounted) {
        setState(() => _action = const AuthActionState.success('本機模式已啟用。'));
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _action = AuthActionState.error(_authMessage(error.code)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _action = const AuthActionState.error('無法啟用本機模式，請稍後再試。'),
        );
      }
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
                    const Center(child: BrandMark()),
                    const SizedBox(height: 16),
                    Text(
                      BrandIdentity.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _registering ? '建立帳號並開始記錄飲食' : BrandIdentity.tagline,
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
                    if (_action.isError) ...[
                      const SizedBox(height: 12),
                      Text(
                        _action.message!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_action.message != null && !_action.isError) ...[
                      const SizedBox(height: 12),
                      Text(
                        _action.message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _action.isLoading ? null : _submit,
                      icon: _action.isLoading && _action.message != '正在啟用本機模式…'
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
                      onPressed: _action.isLoading
                          ? null
                          : () => setState(() => _registering = !_registering),
                      child: Text(_registering ? '已有帳號？回登入' : '還沒有帳號？免費註冊'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _action.isLoading ? null : _continueLocally,
                      icon: _action.isLoading && _action.message == '正在啟用本機模式…'
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.phone_android_outlined),
                      label: const Text('先用本機模式'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '不需要帳號，紀錄只保存在這台裝置，不跨裝置同步。AI 圖片分析每日 5 次。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
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
  'operation-not-allowed' => '此登入方式尚未啟用，請稍後再試。',
  'too-many-requests' => '操作過於頻繁，請稍後再試。',
  _ => '無法完成操作，請檢查資料後再試。',
};

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.onRefresh,
    required this.onResend,
    required this.onSignOut,
    this.resendCooldown = const Duration(seconds: 30),
  });

  final String email;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onResend;
  final Future<void> Function() onSignOut;
  final Duration resendCooldown;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

enum _VerificationAction { refresh, resend }

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  AuthActionState _action = const AuthActionState.idle();
  _VerificationAction? _activeAction;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<bool> _runAction({
    required _VerificationAction action,
    required String loadingMessage,
    required String successMessage,
    required String failureMessage,
    required Future<void> Function() operation,
  }) async {
    setState(() {
      _activeAction = action;
      _action = AuthActionState.loading(loadingMessage);
    });
    try {
      await operation();
      if (!mounted) return false;
      setState(() => _action = AuthActionState.success(successMessage));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      return true;
    } on FirebaseAuthException catch (error) {
      if (!mounted) return false;
      final message = _authMessage(error.code);
      setState(() => _action = AuthActionState.error(message));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _action = AuthActionState.error(failureMessage));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
      return false;
    }
  }

  Future<void> _refresh() async {
    await _runAction(
      action: _VerificationAction.refresh,
      loadingMessage: '正在更新驗證狀態…',
      successMessage: '驗證狀態已更新。',
      failureMessage: '無法更新驗證狀態，請稍後再試。',
      operation: widget.onRefresh,
    );
  }

  Future<void> _resend() async {
    final succeeded = await _runAction(
      action: _VerificationAction.resend,
      loadingMessage: '正在重寄驗證信…',
      successMessage: '驗證信已重新寄出，請檢查收件匣。',
      failureMessage: '無法重寄驗證信，請稍後再試。',
      operation: widget.onResend,
    );
    if (succeeded) _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = widget.resendCooldown.inSeconds);
    if (_cooldownSeconds <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          tooltip: '登出',
          onPressed: _action.isLoading ? null : widget.onSignOut,
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
                '驗證信已寄到 ${widget.email}。完成後回來更新狀態。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _action.isLoading ? null : _refresh,
                icon:
                    _action.isLoading &&
                        _activeAction == _VerificationAction.refresh
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('我已完成驗證'),
              ),
              TextButton(
                onPressed: _action.isLoading || _cooldownSeconds > 0
                    ? null
                    : _resend,
                child:
                    _action.isLoading &&
                        _activeAction == _VerificationAction.resend
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _cooldownSeconds > 0
                            ? '請等候 $_cooldownSeconds 秒再重寄'
                            : '重寄驗證信',
                      ),
              ),
              if (_action.message != null) ...[
                const SizedBox(height: 10),
                Text(
                  _action.message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _action.isError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
