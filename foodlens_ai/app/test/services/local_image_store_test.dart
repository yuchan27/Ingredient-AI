import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/services/local_image_store.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('saves and deletes one selected image in the app documents area', () async {
    final root = await Directory.systemTemp.createTemp('foodlens-image-store-');
    final store = LocalImageStore(documentsDirectory: () async => root);
    final image = XFile.fromData(
      Uint8List.fromList([1, 2, 3, 4]),
      mimeType: 'image/jpeg',
      name: 'meal.jpg',
    );

    final savedPath = await store.save(
      uid: 'user-1',
      recordId: 'record-1',
      image: image,
    );

    final savedFile = File(savedPath);
    expect(savedPath, contains('foodlens_images'));
    expect(await savedFile.readAsBytes(), [1, 2, 3, 4]);

    await store.delete(savedPath);
    expect(await savedFile.exists(), isFalse);
  });
}
