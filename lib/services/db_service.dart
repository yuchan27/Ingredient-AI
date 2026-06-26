import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/food_entry.dart';

class DBService {
  static Database? _db;
  static const _uuid = Uuid();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), "health_history_v2.db");
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createHistoryTable(db);
        await _createFoodEntriesTable(db);
        await _createUserProfileTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _upgradeHistoryForSync(db);
          await _createFoodEntriesTable(db);
          await _createUserProfileTable(db);
        }
      },
    );
  }

  Future<int> insertHistory(String imagePath, Map<String, dynamic> result) async {
    var dbClient = await db;
    final now = DateTime.now().toUtc().toIso8601String();
    return await dbClient.insert("history", {
      "localId": _uuid.v4(),
      "date": DateTime.now().toIso8601String(),
      "imagePath": imagePath,
      "resultJson": jsonEncode(result),
      "cloudId": null,
      "syncStatus": "pending",
      "updatedAt": now,
      "deletedAt": null,
    });
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    var dbClient = await db;
    return await dbClient.query(
      "history",
      where: "deletedAt IS NULL",
      orderBy: "date DESC",
    );
  }

  Future<List<Map<String, dynamic>>> getPendingHistory() async {
    var dbClient = await db;
    return dbClient.query(
      "history",
      where: "syncStatus = ? AND deletedAt IS NULL",
      whereArgs: ["pending"],
      orderBy: "date ASC",
    );
  }

  Future<void> markHistorySynced(int id, String cloudId) async {
    var dbClient = await db;
    await dbClient.update(
      "history",
      {
        "cloudId": cloudId,
        "syncStatus": "synced",
        "updatedAt": DateTime.now().toUtc().toIso8601String(),
      },
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> insertFoodEntry(FoodEntry entry) async {
    var dbClient = await db;
    final map = Map<String, dynamic>.from(entry.toDatabaseMap());
    if (map["id"] == null) map.remove("id");
    return dbClient.insert(
      "food_entries",
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FoodEntry>> getFoodEntries() async {
    var dbClient = await db;
    final rows = await dbClient.query(
      "food_entries",
      where: "deletedAt IS NULL",
      orderBy: "consumedAt DESC",
    );
    return rows.map(FoodEntry.fromJson).toList();
  }

  Future<List<FoodEntry>> getPendingFoodEntries() async {
    var dbClient = await db;
    final rows = await dbClient.query(
      "food_entries",
      where: "syncStatus = ? AND deletedAt IS NULL",
      whereArgs: ["pending"],
      orderBy: "updatedAt ASC",
    );
    return rows.map(FoodEntry.fromJson).toList();
  }

  Future<void> markFoodEntrySynced(String localId, String cloudId) async {
    var dbClient = await db;
    await dbClient.update(
      "food_entries",
      {
        "cloudId": cloudId,
        "syncStatus": "synced",
        "updatedAt": DateTime.now().toUtc().toIso8601String(),
      },
      where: "localId = ?",
      whereArgs: [localId],
    );
  }

  Future<void> saveUserProfile({
    required String localUserId,
    String? email,
    String? cloudUserId,
    String? authToken,
  }) async {
    var dbClient = await db;
    await dbClient.insert(
      "user_profile",
      {
        "id": 1,
        "localUserId": localUserId,
        "email": email,
        "cloudUserId": cloudUserId,
        "authToken": authToken,
        "updatedAt": DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    var dbClient = await db;
    final rows = await dbClient.query("user_profile", limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<void> _createHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        localId TEXT,
        date TEXT,
        imagePath TEXT,
        resultJson TEXT,
        cloudId TEXT,
        syncStatus TEXT DEFAULT 'pending',
        updatedAt TEXT,
        deletedAt TEXT
      )
    ''');
  }

  static Future<void> _createFoodEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        localId TEXT NOT NULL UNIQUE,
        cloudId TEXT,
        foodName TEXT NOT NULL,
        consumedAt TEXT NOT NULL,
        mealType TEXT NOT NULL,
        servingSize REAL NOT NULL,
        servingUnit TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        sugar REAL NOT NULL,
        sodium REAL NOT NULL,
        fiber REAL NOT NULL,
        healthScore INTEGER NOT NULL,
        notes TEXT,
        source TEXT NOT NULL,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        deletedAt TEXT
      )
    ''');
  }

  static Future<void> _createUserProfileTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        localUserId TEXT NOT NULL,
        email TEXT,
        cloudUserId TEXT,
        authToken TEXT,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _upgradeHistoryForSync(Database db) async {
    await _addColumnIfMissing(db, "history", "localId", "TEXT");
    await _addColumnIfMissing(db, "history", "cloudId", "TEXT");
    await _addColumnIfMissing(
      db,
      "history",
      "syncStatus",
      "TEXT DEFAULT 'pending'",
    );
    await _addColumnIfMissing(db, "history", "updatedAt", "TEXT");
    await _addColumnIfMissing(db, "history", "deletedAt", "TEXT");
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery("PRAGMA table_info($table)");
    final exists = columns.any((row) => row["name"] == column);
    if (!exists) {
      await db.execute("ALTER TABLE $table ADD COLUMN $column $definition");
    }
  }
}
