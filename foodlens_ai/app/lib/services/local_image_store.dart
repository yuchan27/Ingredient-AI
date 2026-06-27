import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

typedef DocumentsDirectoryProvider = Future<Directory> Function();

class LocalImageStore {
  LocalImageStore({DocumentsDirectoryProvider? documentsDirectory})
    : _documentsDirectory = documentsDirectory ?? getApplicationDocumentsDirectory;

  final DocumentsDirectoryProvider _documentsDirectory;

  Future<String> save({
    required String uid,
    required String recordId,
    required XFile image,
  }) async {
    final root = await _documentsDirectory();
    final directory = Directory(
      _join(root.path, 'foodlens_images', _safeSegment(uid)),
    );
    await directory.create(recursive: true);
    final file = File(
      _join(directory.path, '${_safeSegment(recordId)}${_extension(image)}'),
    );
    await file.writeAsBytes(await image.readAsBytes(), flush: true);
    return file.path;
  }

  Future<void> delete(String path) async {
    if (path.isEmpty) return;
    final root = await _documentsDirectory();
    final imagesRoot = Directory(_join(root.path, 'foodlens_images')).absolute.path;
    final file = File(path).absolute;
    if (!file.path.startsWith('$imagesRoot${Platform.pathSeparator}')) return;
    if (await file.exists()) await file.delete();
  }
}

String _safeSegment(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

String _extension(XFile image) {
  final name = image.name.toLowerCase();
  if (name.endsWith('.png')) return '.png';
  if (name.endsWith('.webp')) return '.webp';
  if (image.mimeType == 'image/png') return '.png';
  if (image.mimeType == 'image/webp') return '.webp';
  return '.jpg';
}

String _join(String first, String second, [String? third]) => [
  first,
  second,
  if (third != null) third,
].join(Platform.pathSeparator);
