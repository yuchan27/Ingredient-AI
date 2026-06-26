import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import '../models/food_entry.dart';
import '../models/health_result.dart';
import '../services/ai_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/db_service.dart';
import '../services/voice_input_service.dart';
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
  bool _isListening = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final AIService _aiService = AIService();
  final DBService _dbService = DBService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final VoiceInputService _voiceInputService = VoiceInputService();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  String _selectedMealType = 'snack';

  Future<String?> _compressAndSaveImage(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = "img_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final targetPath = p.join(appDir.path, fileName);
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 1024,
        minHeight: 1024,
      );
      return result?.path;
    } catch (e) {
      debugPrint("圖片壓縮失敗：$e");
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (pickedFile == null) return;
    final stableImage = await _persistPickedImage(pickedFile);
    setState(() => _image = stableImage);
  }

  Future<File> _persistPickedImage(XFile pickedFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extension = p.extension(pickedFile.path).isEmpty
        ? '.jpg'
        : p.extension(pickedFile.path);
    final targetPath = p.join(
      appDir.path,
      'picked_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    return File(pickedFile.path).copy(targetPath);
  }

  Future<void> _listenForFoodName() async {
    setState(() => _isListening = true);
    try {
      final text = await _voiceInputService.listenOnce();
      if (!mounted) return;
      if (text == null || text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("沒有辨識到語音內容。"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      _nameController.text = text;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("語音輸入失敗：$e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _startAnalysis() async {
    final foodName = _nameController.text.trim();
    if (foodName.isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("請輸入食物名稱，或選擇一張照片。"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? savedPath;
      if (_image != null) {
        savedPath = await _compressAndSaveImage(_image!);
      }

      final result = await _aiService.analyzeIngredients(_image, foodName);
      final diaryEntry = FoodEntry.fromHealthResult(
        result,
        localId: _uuid.v4(),
        consumedAt: DateTime.now(),
        mealType: _selectedMealType,
        cost: _parseDouble(_costController.text),
      );

      if (!mounted) return;
      setState(() => _result = result);

      await _dbService.insertHistory(savedPath ?? "", result.toJson());
      await _dbService.insertFoodEntry(diaryEntry);
      try {
        await _cloudSyncService.syncPending();
      } catch (syncError) {
        debugPrint("同步失敗，資料已保留在本機：$syncError");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("分析失敗：$e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _reset() {
    setState(() {
      _image = null;
      _result = null;
      _nameController.clear();
      _costController.clear();
      _selectedMealType = 'snack';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _voiceInputService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI 飲食分析',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: (_image != null || _result != null || _isLoading)
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _reset,
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading
            ? _loadingUi()
            : (_result != null
                  ? ResultCard(
                      imagePath: _image?.path,
                      result: _result!,
                      onReset: _reset,
                    )
                  : _homeUi()),
      ),
    );
  }

  Widget _homeUi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_tou967.json',
            height: 160,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.center_focus_weak,
              size: 80,
              color: Color(0xFF00B894),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '拍照分析餐點與營養標示',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '可輸入名稱、上傳包裝或營養標示照片，AI 會整理熱量、營養成分與飲食建議，並自動存入本地紀錄。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: '例如：雞排、便當、優格營養標示',
              labelText: '食物名稱',
              labelStyle: const TextStyle(color: Color(0xFF00B894)),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF00B894),
              ),
              suffixIcon: IconButton(
                tooltip: '語音輸入',
                onPressed: _isListening ? null : _listenForFoodName,
                icon: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: const Color(0xFF00B894),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMealType,
                  dropdownColor: const Color(0xFF1A1A1A),
                  decoration: _inputDecoration('餐別', Icons.restaurant_rounded),
                  items: const [
                    DropdownMenuItem(value: 'breakfast', child: Text('早餐')),
                    DropdownMenuItem(value: 'lunch', child: Text('午餐')),
                    DropdownMenuItem(value: 'dinner', child: Text('晚餐')),
                    DropdownMenuItem(value: 'snack', child: Text('點心')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedMealType = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    '餐費 TWD',
                    Icons.payments_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_image != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _image!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _image = null),
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _imageButton(
                    () => _pickImage(ImageSource.camera),
                    '拍照',
                    Icons.camera_alt_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _imageButton(
                    () => _pickImage(ImageSource.gallery),
                    '相簿',
                    Icons.image_rounded,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _startAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                '開始 AI 分析',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageButton(VoidCallback onPressed, String text, IconData icon) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: const BorderSide(color: Colors.white10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: Colors.white70,
      ),
      icon: Icon(icon, size: 20),
      label: Text(text),
    );
  }

  Widget _loadingUi() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ],
        ),
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

  double _parseDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }
}
