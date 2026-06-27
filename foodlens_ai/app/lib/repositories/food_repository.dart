import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/food_record.dart';

class UploadedFoodImage {
  const UploadedFoodImage({required this.path, required this.url});
  final String path;
  final String url;
}

abstract class FoodRepository {
  Stream<List<FoodRecord>> watchRecords();
  String createRecordId();
  Future<UploadedFoodImage> uploadImage(String recordId, XFile image);
  Future<void> save(FoodRecord record);
  Future<void> delete(FoodRecord record);
  Future<void> submitFeedback({
    required String category,
    required String message,
  });
}

class FirebaseFoodRepository implements FoodRepository {
  FirebaseFoodRepository({
    required this.uid,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final String uid;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('users').doc(uid).collection('food_records');

  @override
  Stream<List<FoodRecord>> watchRecords() => _records
      .orderBy('eatenAt', descending: true)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => snapshot.docs
            .map((document) => FoodRecord.fromMap(document.id, document.data()))
            .toList(),
      );

  @override
  String createRecordId() => _uuid.v4();

  @override
  Future<UploadedFoodImage> uploadImage(String recordId, XFile image) async {
    final path = 'users/$uid/food_images/$recordId.jpg';
    final reference = _storage.ref(path);
    final bytes = await image.readAsBytes();
    await reference.putData(
      bytes,
      SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
    );
    return UploadedFoodImage(path: path, url: await reference.getDownloadURL());
  }

  @override
  Future<void> save(FoodRecord record) =>
      _records.doc(record.id).set(record.toMap(), SetOptions(merge: true));

  @override
  Future<void> delete(FoodRecord record) async {
    await _records.doc(record.id).delete();
    if (record.imagePath.isNotEmpty) {
      try {
        await _storage.ref(record.imagePath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }
  }

  @override
  Future<void> submitFeedback({
    required String category,
    required String message,
  }) => _firestore.collection('users').doc(uid).collection('feedback').add({
    'category': category,
    'message': message,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

class MemoryFoodRepository implements FoodRepository {
  MemoryFoodRepository({List<FoodRecord>? seed}) : _records = [...?seed];

  factory MemoryFoodRepository.demo() {
    final now = DateTime.now();
    return MemoryFoodRepository(
      seed: [
        FoodRecord.empty('demo-lunch').copyWith(
          foodName: '鮮蔬雞胸便當',
          calories: 568,
          protein: 42,
          fat: 16,
          carbs: 61,
          confidence: 0.92,
          cost: 125,
          mealType: MealType.lunch,
          notes: '雞胸、糙米、花椰菜與水煮蛋。',
          eatenAt: DateTime(now.year, now.month, now.day, 12, 20),
        ),
        FoodRecord.empty('demo-breakfast').copyWith(
          foodName: '無糖優格燕麥杯',
          calories: 326,
          protein: 18,
          fat: 9,
          carbs: 46,
          confidence: 0.87,
          cost: 75,
          mealType: MealType.breakfast,
          notes: '優格、燕麥、藍莓與堅果。',
          eatenAt: DateTime(now.year, now.month, now.day, 8, 10),
        ),
        FoodRecord.empty('demo-yesterday').copyWith(
          foodName: '烤鮭魚定食',
          calories: 645,
          protein: 39,
          fat: 24,
          carbs: 68,
          confidence: 0.9,
          cost: 190,
          mealType: MealType.dinner,
          eatenAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    );
  }

  final List<FoodRecord> _records;
  final _changes = StreamController<List<FoodRecord>>.broadcast();
  final _uuid = const Uuid();

  @override
  Stream<List<FoodRecord>> watchRecords() async* {
    yield List.unmodifiable(_sorted());
    yield* _changes.stream;
  }

  List<FoodRecord> _sorted() =>
      [..._records]..sort((a, b) => b.eatenAt.compareTo(a.eatenAt));
  void _emit() => _changes.add(List.unmodifiable(_sorted()));

  @override
  String createRecordId() => _uuid.v4();

  @override
  Future<UploadedFoodImage> uploadImage(String recordId, XFile image) async =>
      UploadedFoodImage(path: 'demo/$recordId.jpg', url: image.path);

  @override
  Future<void> save(FoodRecord record) async {
    _records.removeWhere((item) => item.id == record.id);
    _records.add(record);
    _emit();
  }

  @override
  Future<void> delete(FoodRecord record) async {
    _records.removeWhere((item) => item.id == record.id);
    _emit();
  }

  @override
  Future<void> submitFeedback({
    required String category,
    required String message,
  }) async {}
}
