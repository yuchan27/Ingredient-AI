import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/health_result.dart';

class ResultCard extends StatelessWidget {
  final String? imagePath;
  final HealthResult result;
  final VoidCallback onReset;
  final Future<void> Function()? onSaveToDiary;

  const ResultCard({
    super.key,
    this.imagePath,
    required this.result,
    required this.onReset,
    this.onSaveToDiary,
  });

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('`', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final score = result.healthScore;
    final color = score >= 75
        ? Colors.greenAccent
        : score >= 55
        ? Colors.amberAccent
        : Colors.redAccent;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.notoSansTcTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imagePreview(),
            const SizedBox(height: 20),
            _mainInfo(score, color),
            const SizedBox(height: 18),
            _nutritionGrid(),
            const SizedBox(height: 22),
            _ingredientSection(
              title: '可保留的成分',
              items: result.healthyIngredients,
              reason: result.healthyReason,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 18),
            _ingredientSection(
              title: '需要留意的成分',
              items: result.riskyIngredients,
              reason: result.riskyReason,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 22),
            _markdownPanel(
              '整體評估',
              result.assessment,
              Icons.fact_check_outlined,
            ),
            const SizedBox(height: 28),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (onSaveToDiary != null)
                    ElevatedButton.icon(
                      onPressed: onSaveToDiary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.restaurant_menu_rounded),
                      label: const Text('加入飲食紀錄'),
                    ),
                  ElevatedButton.icon(
                    onPressed: onReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('重新分析'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview() {
    final path = imagePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          File(path),
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.white24,
          ),
          SizedBox(height: 8),
          Text('沒有附加圖片', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _mainInfo(int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _scoreCircle(score, color),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cleanText(result.foodName),
                  style: GoogleFonts.notoSansTc(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _cleanText(result.recommendation),
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCircle(int score, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(
            value: (score / 100).clamp(0, 1),
            strokeWidth: 8,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          '$score',
          style: GoogleFonts.notoSansTc(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _nutritionGrid() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 18,
        alignment: WrapAlignment.spaceAround,
        children: [
          _nutritionItem('等級', result.nutritionGrade, ''),
          _nutritionItem('熱量', '${result.calories}', 'kcal'),
          _nutritionItem('蛋白質', _formatNumber(result.protein), 'g'),
          _nutritionItem('碳水', _formatNumber(result.carbs), 'g'),
          _nutritionItem('糖', _formatNumber(result.sugar), 'g'),
          _nutritionItem('鈉', _formatNumber(result.sodium), 'mg'),
          _nutritionItem('脂肪', _formatNumber(result.fat), 'g'),
          _nutritionItem('纖維', _formatNumber(result.fiber), 'g'),
        ],
      ),
    );
  }

  Widget _nutritionItem(String label, String value, String unit) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.notoSansTc(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00B894),
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 10, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _ingredientSection({
    required String title,
    required List<String> items,
    required String reason,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansTc(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            'AI 未列出此類成分。',
            style: TextStyle(color: color.withValues(alpha: 0.75)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _cleanText(item),
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                  ),
                )
                .toList(),
          ),
        if (reason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _markdownBody(reason),
          ),
      ],
    );
  }

  Widget _markdownPanel(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00B894), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.notoSansTc(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Colors.white10),
          MarkdownBody(data: content, styleSheet: _markdownStyle()),
        ],
      ),
    );
  }

  Widget _markdownBody(String content) {
    return Container(
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: MarkdownBody(data: content, styleSheet: _markdownStyle()),
    );
  }

  MarkdownStyleSheet _markdownStyle() {
    return MarkdownStyleSheet(
      p: GoogleFonts.notoSansTc(
        fontSize: 14,
        color: Colors.white70,
        height: 1.7,
      ),
      strong: const TextStyle(
        color: Color(0xFF00B894),
        fontWeight: FontWeight.bold,
      ),
      listBullet: const TextStyle(color: Color(0xFF00B894)),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
