import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/db_service.dart';
import '../models/health_result.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // 簡潔的星等顯示
  Widget _buildStarRating(int score) {
    int starCount = 0;
    if (score > 80) starCount = 5;
    else if (score > 60) starCount = 4;
    else if (score > 40) starCount = 3;
    else if (score > 20) starCount = 2;
    else starCount = 1;

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

  @override
  Widget build(BuildContext context) {
    final dbService = DBService();
    return Scaffold(
      appBar: AppBar(
        title: Text('掃描紀錄', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbService.getHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final history = snapshot.data!;
          if (history.isEmpty) return _buildEmptyHistory();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final Map<String, dynamic> resultJson = jsonDecode(item['resultJson']);
              final result = HealthResult.fromJson(resultJson);
              final score = result.healthScore;
              
              Color scoreColor = score > 75 ? Colors.greenAccent : (score > 50 ? Colors.orangeAccent : Colors.redAccent);
              
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryDetailPage(
                      imagePath: item['imagePath'],
                      result: result,
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      // 圖片預覽 (固定尺寸)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item['imagePath'] != null && item['imagePath'].toString().isNotEmpty && File(item['imagePath']).existsSync()
                            ? Image.file(File(item['imagePath']), width: 50, height: 50, fit: BoxFit.cover)
                            : Container(
                                width: 50, 
                                height: 50, 
                                color: Colors.white10, 
                                child: const Icon(Icons.fastfood, color: Colors.white24, size: 24)
                              ),
                      ),
                      const SizedBox(width: 16),
                      // 核心資訊區 (只留名稱、分數、星級)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.foodName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansTc(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "$score分 ",
                                  style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                _buildStarRating(score),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 查看詳細按鈕
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
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

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network('https://lottie.host/80287a2d-2228-4e14-8742-b0885e33d069/9B4H3R9RNo.json', height: 180),
          const SizedBox(height: 16),
          Text("尚無掃描紀錄", style: GoogleFonts.notoSansTc(color: Colors.white24, fontSize: 15)),
        ],
      ),
    );
  }
}
