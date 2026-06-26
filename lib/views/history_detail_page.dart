import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/food_entry.dart';
import '../models/health_result.dart';
import '../services/cloud_sync_service.dart';
import '../services/db_service.dart';
import '../widgets/result_card.dart';

class HistoryDetailPage extends StatelessWidget {
  final String? imagePath;
  final HealthResult result;
  final DBService _dbService = DBService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final Uuid _uuid = const Uuid();

  HistoryDetailPage({super.key, this.imagePath, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          result.foodName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ResultCard(
        imagePath: imagePath,
        result: result,
        onReset: () => Navigator.pop(context),
        onSaveToDiary: () => _saveToDiary(context),
      ),
    );
  }

  Future<void> _saveToDiary(BuildContext context) async {
    final now = DateTime.now();
    final entry = FoodEntry.fromHealthResult(
      result,
      localId: _uuid.v4(),
      consumedAt: now,
      mealType: 'snack',
    );
    await _dbService.insertFoodEntry(entry);
    try {
      await _cloudSyncService.syncPending();
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("已加入飲食紀錄"),
        backgroundColor: Color(0xFF00B894),
      ),
    );
  }
}
