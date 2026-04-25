import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/health_result.dart';

class ResultCard extends StatelessWidget {
  final String? imagePath;
  final HealthResult result;
  final VoidCallback onReset;

  const ResultCard({
    super.key,
    this.imagePath,
    required this.result,
    required this.onReset,
  });

  // 自動清洗字串，移除殘留的 Markdown 符號（用於不支援 Markdown 的純文字欄位）
  String _cleanText(String text) {
    return text.replaceAll('**', '').replaceAll('*', '').replaceAll('`', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final score = result.healthScore;
    final color = score > 75 ? Colors.greenAccent : (score > 50 ? Colors.orangeAccent : Colors.redAccent);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.notoSansTcTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.white),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 圖片顯示邏輯：如果路徑存在且檔案還在就顯示
            if (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(File(imagePath!), height: 220, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.white10),
                    SizedBox(height: 8),
                    Text("無照片或已被系統清除", style: TextStyle(color: Colors.white10, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            _buildMainInfo(score, color),
            const SizedBox(height: 24),
            
            _buildNutritionGrid(),
            const SizedBox(height: 24),

            _buildIngredientDetail("🌟 健康成分分析", result.healthyIngredients, result.healthyReason, Colors.greenAccent),
            const SizedBox(height: 20),
            _buildIngredientDetail("⚠️ 風險/加工成分分析", result.riskyIngredients, result.riskyReason, Colors.redAccent),
            
            const SizedBox(height: 24),
            _buildMarkdownCard("🔬 綜合健康評估", result.assessment, Icons.fact_check_outlined),
            
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("重新掃描"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo(int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildScoreCircle(score, color),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 自動清洗產品名稱中的符號
                Text(_cleanText(result.foodName), style: GoogleFonts.notoSansTc(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  // 自動清洗建議欄位
                  child: Text(_cleanText(result.recommendation), style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(int score, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 8,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text("$score", style: GoogleFonts.notoSansTc(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildNutritionGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutritionItem("熱量", "${result.calories}", "kcal"),
          _buildNutritionItem("糖分", "${result.sugar}", "g"),
          _buildNutritionItem("鈉", "${result.sodium}", "mg"),
          _buildNutritionItem("脂肪", "${result.fat}", "g"),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.notoSansTc(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF00B894))),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.white24)),
      ],
    );
  }

  Widget _buildIngredientDetail(String title, List<String> items, String reason, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.notoSansTc(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(_cleanText(e), style: TextStyle(color: color, fontSize: 13)),
          )).toList(),
        ),
        if (reason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
              ),
              child: MarkdownBody(
                data: reason,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.notoSansTc(fontSize: 14, color: Colors.white70, height: 1.8),
                  strong: const TextStyle(color: Color(0xFF00B894), fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: Color(0xFF00B894)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMarkdownCard(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00B894), size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.notoSansTc(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.notoSansTc(fontSize: 14, color: Colors.white70, height: 1.8),
              strong: const TextStyle(color: Color(0xFF00B894), fontWeight: FontWeight.bold),
              listBullet: const TextStyle(color: Color(0xFF00B894)),
            ),
          ),
        ],
      ),
    );
  }
}
