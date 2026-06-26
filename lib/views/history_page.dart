import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../models/health_result.dart';
import '../services/db_service.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DBService();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '分析紀錄',
          style: GoogleFonts.notoSansTc(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbService.getHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data!;
          if (history.isEmpty) return _emptyHistory();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final resultJson =
                  jsonDecode(item['resultJson'].toString())
                      as Map<String, dynamic>;
              final result = HealthResult.fromJson(resultJson);
              final scoreColor = _scoreColor(result.healthScore);
              final syncStatus = (item['syncStatus'] ?? 'pending').toString();
              final dateText = _formatDate(item['date']);

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryDetailPage(
                      imagePath: item['imagePath']?.toString(),
                      result: result,
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      _thumbnail(item['imagePath']?.toString()),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.foodName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansTc(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${result.healthScore} 分',
                                  style: TextStyle(
                                    color: scoreColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _starRating(result.healthScore),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dateText,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                _syncChip(syncStatus),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white24,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _thumbnail(String? imagePath) {
    final hasImage =
        imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: hasImage
          ? Image.file(
              File(imagePath),
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            )
          : Container(
              width: 54,
              height: 54,
              color: Colors.white10,
              child: const Icon(
                Icons.fastfood,
                color: Colors.white24,
                size: 24,
              ),
            ),
    );
  }

  Widget _starRating(int score) {
    final starCount = score > 80
        ? 5
        : score > 60
        ? 4
        : score > 40
        ? 3
        : score > 20
        ? 2
        : 1;
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < starCount ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _syncChip(String status) {
    final synced = status == 'synced';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          synced ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
          size: 13,
          color: synced ? Colors.greenAccent : Colors.orangeAccent,
        ),
        const SizedBox(width: 4),
        Text(
          synced ? "已同步" : "待同步",
          style: TextStyle(
            color: synced ? Colors.greenAccent : Colors.orangeAccent,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _emptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://lottie.host/80287a2d-2228-4e14-8742-b0885e33d069/9B4H3R9RNo.json',
            height: 180,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.history_rounded,
              size: 72,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "目前沒有分析紀錄",
            style: GoogleFonts.notoSansTc(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score > 75) return Colors.greenAccent;
    if (score > 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _formatDate(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    return DateFormat('yyyy/MM/dd HH:mm').format(parsed);
  }
}
