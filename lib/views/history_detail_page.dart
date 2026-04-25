import 'package:flutter/material.dart';
import '../models/health_result.dart';
import '../widgets/result_card.dart';

class HistoryDetailPage extends StatelessWidget {
  final String? imagePath;
  final HealthResult result;

  const HistoryDetailPage({super.key, this.imagePath, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(result.foodName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ResultCard(
        imagePath: imagePath,
        result: result,
        onReset: () => Navigator.pop(context), // 在詳情頁，重新掃描就是回到紀錄列表
      ),
    );
  }
}
