import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/health_result.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import '../widgets/result_card.dart';

class AnalyzerPage extends StatefulWidget {
  const AnalyzerPage({super.key});

  @override
  State<AnalyzerPage> createState() => _AnalyzerPageState();
}

class _AnalyzerPageState extends State<AnalyzerPage> {
  File? _image;
  HealthResult? _result;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final AIService _aiService = AIService();
  final DBService _dbService = DBService();
  final ImagePicker _picker = ImagePicker();

  // 智慧壓縮圖片並儲存到文件目錄（永不消失）
  Future<String?> _compressAndSaveImage(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = "img_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String targetPath = p.join(appDir.path, fileName);

      // 壓縮邏輯：最大寬度 1024，品質 75%，這能平衡容量與清晰度
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result?.path;
    } catch (e) {
      debugPrint("壓縮失敗: $e");
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 100);
    if (pickedFile == null) return;
    setState(() => _image = File(pickedFile.path));
  }

  Future<void> _startAnalysis() async {
    final String foodName = _nameController.text.trim();
    if (foodName.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請提供產品名稱或拍攝照片"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalSavedPath;
      if (_image != null) {
        // 使用高效壓縮並永久存儲
        finalSavedPath = await _compressAndSaveImage(_image!);
      }

      final result = await _aiService.analyzeIngredients(_image, foodName);
      
      if (!mounted) return;
      setState(() {
        _result = result;
      });

      await _dbService.insertHistory(finalSavedPath ?? "", result.toJson());

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("分析失敗: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 原材料分析', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: (_image != null || _result != null || _isLoading) 
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() { 
                  _image = null; 
                  _result = null; 
                  _nameController.clear();
                });
              },
            )
          : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isLoading 
          ? _buildLoadingUI() 
          : (_result != null ? ResultCard(imagePath: _image?.path, result: _result!, onReset: () {
              setState(() { _image = null; _result = null; _nameController.clear(); });
            }) : _buildHomeUI()),
      ),
    );
  }

  Widget _buildHomeUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_tou967.json',
            height: 180,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.center_focus_weak, size: 80, color: Color(0xFF00B894)),
          ),
          const SizedBox(height: 20),
          const Text("透明化你的飲食", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("輸入名稱或拍照，AI 2.5 為您揭開成分真相", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          
          const SizedBox(height: 30),
          
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "例：紅龍雞塊、義美全脂鮮乳...",
              labelText: "產品名稱",
              labelStyle: const TextStyle(color: Color(0xFF00B894)),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF00B894)),
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_image != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_image!, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                IconButton(
                  onPressed: () => setState(() => _image = null),
                  icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, size: 18, color: Colors.white)),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildSmallBtn(() => _pickImage(ImageSource.camera), "拍照", Icons.camera_alt_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildSmallBtn(() => _pickImage(ImageSource.gallery), "相簿", Icons.image_rounded)),
              ],
            ),
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _startAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text("開始 AI 分析", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBtn(VoidCallback onPressed, String text, IconData icon) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: Colors.white10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: Colors.white70,
      ),
      icon: Icon(icon, size: 20),
      label: Text(text),
    );
  }

  Widget _buildLoadingUI() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 24),
            Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }
}
