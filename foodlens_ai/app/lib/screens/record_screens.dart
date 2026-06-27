import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/food_record.dart';
import '../repositories/food_repository.dart';
import '../services/food_analysis_api.dart';
import 'dashboard_shell.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({
    super.key,
    required this.repository,
    required this.api,
    required this.tokenProvider,
    required this.isDemo,
  });

  final FoodRepository repository;
  final FoodAnalysisApi api;
  final TokenProvider tokenProvider;
  final bool isDemo;

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final String _recordId;
  late final _EditorControllers _fields;
  XFile? _image;
  Uint8List? _preview;
  UploadedFoodImage? _uploadedImage;
  MealType _mealType = MealType.lunch;
  DateTime _eatenAt = DateTime.now();
  double _confidence = 0;
  bool _analyzing = false;
  bool _saving = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _recordId = widget.repository.createRecordId();
    _fields = _EditorControllers();
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = image;
      _preview = bytes;
      _uploadedImage = null;
      _status = null;
    });
  }

  Future<void> _analyze() async {
    if (_image == null) {
      setState(() => _status = '請先選擇或拍攝食物圖片。');
      return;
    }
    setState(() {
      _analyzing = true;
      _status = '正在上傳並分析圖片…';
    });
    try {
      FoodAnalysisResult result;
      if (widget.isDemo) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        _uploadedImage = await widget.repository.uploadImage(
          _recordId,
          _image!,
        );
        result = const FoodAnalysisResult(
          foodName: '台式點心與蔬菜拼盤',
          calories: 482,
          protein: 21,
          fat: 19,
          carbs: 58,
          confidence: 0.84,
          notes: '展示模式估算；實際熱量會受份量與烹調用油影響。',
        );
      } else {
        _uploadedImage = await widget.repository.uploadImage(
          _recordId,
          _image!,
        );
        result = await widget.api.analyze(
          imagePath: _uploadedImage!.path,
          idToken: await widget.tokenProvider(),
        );
      }
      _fields.applyAnalysis(result);
      if (mounted) {
        setState(() {
          _confidence = result.confidence;
          _status = '分析完成，儲存前可修改任何數值。';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _status = '分析失敗，你仍可手動輸入後儲存。');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_image != null && _uploadedImage == null) {
        _uploadedImage = await widget.repository.uploadImage(
          _recordId,
          _image!,
        );
      }
      final now = DateTime.now();
      await widget.repository.save(
        FoodRecord(
          id: _recordId,
          foodName: _fields.name.text.trim(),
          calories: _fields.value(_fields.calories),
          protein: _fields.value(_fields.protein),
          fat: _fields.value(_fields.fat),
          carbs: _fields.value(_fields.carbs),
          confidence: _confidence,
          notes: _fields.notes.text.trim(),
          imagePath: _uploadedImage?.path ?? '',
          imageUrl: _uploadedImage?.url ?? '',
          mealType: _mealType,
          cost: _fields.value(_fields.cost),
          eatenAt: _eatenAt,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _status = '儲存失敗，請檢查連線後再試。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('新增食物')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ImagePanel(
            bytes: _preview,
            onCamera: () => _pick(ImageSource.camera),
            onGallery: () => _pick(ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _analyzing ? null : _analyze,
            icon: _analyzing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(_analyzing ? '分析中' : 'AI 分析圖片'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 10),
            Text(_status!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 18),
          _RecordFields(
            fields: _fields,
            mealType: _mealType,
            eatenAt: _eatenAt,
            onMealChanged: (value) => setState(() => _mealType = value),
            onDateChanged: (value) => setState(() => _eatenAt = value),
          ),
          if (_confidence > 0) ...[
            const SizedBox(height: 12),
            Text(
              'AI 信心度 ${(_confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? '儲存中' : '儲存紀錄'),
          ),
        ],
      ),
    ),
  );
}

class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({
    super.key,
    required this.repository,
    required this.record,
  });
  final FoodRepository repository;
  final FoodRecord record;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _EditorControllers _fields;
  late MealType _mealType;
  late DateTime _eatenAt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fields = _EditorControllers.fromRecord(widget.record);
    _mealType = widget.record.mealType;
    _eatenAt = widget.record.eatenAt;
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    await widget.repository.save(
      widget.record.copyWith(
        foodName: _fields.name.text.trim(),
        calories: _fields.value(_fields.calories),
        protein: _fields.value(_fields.protein),
        fat: _fields.value(_fields.fat),
        carbs: _fields.value(_fields.carbs),
        cost: _fields.value(_fields.cost),
        notes: _fields.notes.text.trim(),
        mealType: _mealType,
        eatenAt: _eatenAt,
        updatedAt: DateTime.now(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除這筆紀錄？'),
        content: const Text('食品資料與雲端圖片將一併刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    await widget.repository.delete(widget.record);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('紀錄詳細'),
      actions: [
        IconButton(
          tooltip: '刪除',
          onPressed: _busy ? null : _delete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (widget.record.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.record.imageUrl,
                height: 210,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 12),
          _RecordFields(
            fields: _fields,
            mealType: _mealType,
            eatenAt: _eatenAt,
            onMealChanged: (value) => setState(() => _mealType = value),
            onDateChanged: (value) => setState(() => _eatenAt = value),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('儲存修改'),
          ),
        ],
      ),
    ),
  );
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.bytes,
    required this.onCamera,
    required this.onGallery,
  });
  final Uint8List? bytes;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: bytes == null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined, size: 42),
              const SizedBox(height: 12),
              const Text('拍攝或選擇食物圖片'),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: '相機',
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: '圖庫',
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
            ],
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes!, fit: BoxFit.cover),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: IconButton.filled(
                  tooltip: '更換圖片',
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                ),
              ),
            ],
          ),
  );
}

class _RecordFields extends StatelessWidget {
  const _RecordFields({
    required this.fields,
    required this.mealType,
    required this.eatenAt,
    required this.onMealChanged,
    required this.onDateChanged,
  });

  final _EditorControllers fields;
  final MealType mealType;
  final DateTime eatenAt;
  final ValueChanged<MealType> onMealChanged;
  final ValueChanged<DateTime> onDateChanged;

  Future<void> _chooseDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: eatenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(eatenAt),
    );
    onDateChanged(
      DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? eatenAt.hour,
        time?.minute ?? eatenAt.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '基本資料',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: fields.name,
        decoration: const InputDecoration(
          labelText: '食品名稱',
          prefixIcon: Icon(Icons.restaurant_menu),
        ),
        validator: (value) =>
            (value?.trim().isNotEmpty ?? false) ? null : '請輸入食品名稱',
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<MealType>(
              initialValue: mealType,
              decoration: const InputDecoration(labelText: '餐別'),
              items: MealType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onMealChanged(value);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _chooseDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '日期時間',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(DateFormat('MM/dd HH:mm').format(eatenAt)),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: fields.cost,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: '餐點花費',
          prefixIcon: Icon(Icons.payments_outlined),
          suffixText: 'NT\$',
        ),
        validator: fields.numberValidator,
      ),
      const SizedBox(height: 20),
      Text(
        '營養成分',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      _NutritionGrid(fields: fields),
      const SizedBox(height: 12),
      TextFormField(
        controller: fields.notes,
        minLines: 3,
        maxLines: 5,
        maxLength: 500,
        decoration: const InputDecoration(
          labelText: '備註',
          alignLabelWithHint: true,
        ),
      ),
    ],
  );
}

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.fields});
  final _EditorControllers fields;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(child: _numberField(fields.calories, '熱量', 'kcal')),
          const SizedBox(width: 10),
          Expanded(child: _numberField(fields.protein, '蛋白質', 'g')),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _numberField(fields.fat, '脂肪', 'g')),
          const SizedBox(width: 10),
          Expanded(child: _numberField(fields.carbs, '碳水', 'g')),
        ],
      ),
    ],
  );

  Widget _numberField(
    TextEditingController controller,
    String label,
    String unit,
  ) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: unit),
    validator: fields.numberValidator,
  );
}

class _EditorControllers {
  _EditorControllers()
    : name = TextEditingController(),
      calories = TextEditingController(text: '0'),
      protein = TextEditingController(text: '0'),
      fat = TextEditingController(text: '0'),
      carbs = TextEditingController(text: '0'),
      cost = TextEditingController(text: '0'),
      notes = TextEditingController();

  factory _EditorControllers.fromRecord(FoodRecord record) {
    final fields = _EditorControllers();
    fields.name.text = record.foodName;
    fields.calories.text = record.calories.toStringAsFixed(0);
    fields.protein.text = record.protein.toStringAsFixed(1);
    fields.fat.text = record.fat.toStringAsFixed(1);
    fields.carbs.text = record.carbs.toStringAsFixed(1);
    fields.cost.text = record.cost.toStringAsFixed(0);
    fields.notes.text = record.notes;
    return fields;
  }

  final TextEditingController name;
  final TextEditingController calories;
  final TextEditingController protein;
  final TextEditingController fat;
  final TextEditingController carbs;
  final TextEditingController cost;
  final TextEditingController notes;

  double value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;
  String? numberValidator(String? value) {
    final number = double.tryParse(value ?? '');
    return number != null && number >= 0 ? null : '請輸入 0 以上的數值';
  }

  void applyAnalysis(FoodAnalysisResult result) {
    name.text = result.foodName;
    calories.text = result.calories.toStringAsFixed(0);
    protein.text = result.protein.toStringAsFixed(1);
    fat.text = result.fat.toStringAsFixed(1);
    carbs.text = result.carbs.toStringAsFixed(1);
    notes.text = result.notes;
  }

  void dispose() {
    name.dispose();
    calories.dispose();
    protein.dispose();
    fat.dispose();
    carbs.dispose();
    cost.dispose();
    notes.dispose();
  }
}
