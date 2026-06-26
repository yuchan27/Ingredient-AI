import 'package:flutter/material.dart';

import '../services/cloud_sync_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late Future<CloudSyncState> _stateFuture;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _stateFuture = _cloudSyncService.initialize();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _stateFuture = _cloudSyncService.initialize();
    });
  }

  Future<void> _runAuth(Future<CloudSyncState> Function() action) async {
    setState(() => _isBusy = true);
    try {
      final state = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: const Color(0xFF00B894),
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("帳號操作失敗：$e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isBusy = true);
    try {
      final result = await _cloudSyncService.syncPending();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFF00B894),
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("同步失敗：$e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "帳號與雲端同步",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<CloudSyncState>(
        future: _stateFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final state = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _statusPanel(state),
              const SizedBox(height: 20),
              if (!state.isSignedIn) _authForm(state),
              if (state.isSignedIn) _signedInPanel(),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _syncNow,
                  icon: const Icon(Icons.cloud_sync_rounded),
                  label: const Text("立即同步本地資料"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B894),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusPanel(CloudSyncState state) {
    final color = state.isSignedIn ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            state.isSignedIn
                ? Icons.verified_user_rounded
                : Icons.person_off_rounded,
            color: color,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isSignedIn
                      ? "已登入"
                      : (state.isConfigured ? "尚未登入" : "本地模式"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.email ?? state.message,
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _authForm(CloudSyncState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          enabled: state.isConfigured && !_isBusy,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration("Email", Icons.email_rounded),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: state.isConfigured && !_isBusy,
          obscureText: true,
          decoration: _inputDecoration("密碼", Icons.lock_rounded),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !state.isConfigured || _isBusy
                    ? null
                    : () => _runAuth(
                        () => _cloudSyncService.signIn(
                          _emailController.text.trim(),
                          _passwordController.text,
                        ),
                      ),
                icon: const Icon(Icons.login_rounded),
                label: const Text("登入"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: !state.isConfigured || _isBusy
                    ? null
                    : () => _runAuth(
                        () => _cloudSyncService.signUp(
                          _emailController.text.trim(),
                          _passwordController.text,
                        ),
                      ),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text("註冊"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _signedInPanel() {
    return OutlinedButton.icon(
      onPressed: _isBusy ? null : () => _runAuth(_cloudSyncService.signOut),
      icon: const Icon(Icons.logout_rounded),
      label: const Text("登出"),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF00B894)),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF00B894)),
    );
  }
}
