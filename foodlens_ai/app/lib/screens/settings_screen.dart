import 'package:flutter/material.dart';

import '../config/api_endpoint_store.dart';
import '../repositories/food_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.accountEmail,
    required this.isDemo,
    required this.apiBaseUrl,
    this.onApiBaseUrlChanged,
    this.onLogout,
  });

  final FoodRepository repository;
  final String accountEmail;
  final bool isDemo;
  final String apiBaseUrl;
  final Future<void> Function(String value)? onApiBaseUrlChanged;
  final Future<void> Function()? onLogout;

  Future<void> _editApiHost(BuildContext context) async {
    final controller = TextEditingController(text: apiBaseUrl);
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 主機'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: '後端網址',
              hintText: 'https://example.run.app',
            ),
            validator: (input) {
              try {
                normalizeApiEndpoint(input ?? '');
                return null;
              } on FormatException {
                return '請輸入 http:// 或 https:// 開頭的完整網址';
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  normalizeApiEndpoint(controller.text),
                );
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || onApiBaseUrlChanged == null) return;
    await onApiBaseUrlChanged!(value);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 主機已更新。')),
      );
    }
  }

  Future<void> _feedback(BuildContext context) async {
    final controller = TextEditingController();
    String category = '功能建議';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('意見回饋'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: '類別'),
                items: const ['功能建議', '辨識結果', '異常問題', '其他']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => category = value ?? category),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 6,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: '請描述你的意見',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('送出'),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && controller.text.trim().isNotEmpty) {
      await repository.submitFeedback(
        category: category,
        message: controller.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('感謝你的意見。')));
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('設定')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(
          '帳號',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(accountEmail),
                subtitle: Text(isDemo ? '展示模式，資料只在本次執行中' : 'Email 已驗證'),
              ),
              if (onLogout != null)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('登出'),
                  onTap: onLogout,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '同步與服務',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.offline_bolt_outlined),
                title: Text('離線可用'),
                subtitle: Text('Firestore 會快取資料，連線後自動同步待上傳變更。'),
              ),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('API 主機'),
                subtitle: Text(
                  apiBaseUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: onApiBaseUrlChanged == null
                    ? null
                    : const Icon(Icons.edit_outlined),
                onTap: onApiBaseUrlChanged == null
                    ? null
                    : () => _editApiHost(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '支援',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('意見回饋'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _feedback(context),
              ),
              const ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('隱私與資料'),
                subtitle: Text('圖片與紀錄只能由對應帳號存取。'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'FoodLens AI 1.0.0',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
