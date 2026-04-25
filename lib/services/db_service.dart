import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DBService {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), "health_history_v2.db");
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(
          "CREATE TABLE history (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, imagePath TEXT, resultJson TEXT)");
    });
  }

  Future<int> insertHistory(String imagePath, Map<String, dynamic> result) async {
    var dbClient = await db;
    return await dbClient.insert("history", {
      "date": DateTime.now().toIso8601String(),
      "imagePath": imagePath,
      "resultJson": jsonEncode(result)
    });
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    var dbClient = await db;
    return await dbClient.query("history", orderBy: "date DESC");
  }
}
