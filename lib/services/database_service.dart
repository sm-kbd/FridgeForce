import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

// Table names
final String _fridgeTableName = "fridge";
final String _categoryTableName = "categories";

// Fridge columns
final String _fridgeId = "fid";
final String _fridgeProductName = "product_name";
final String _fridgeCategoryId = "category_id";
final String _fridgeCreationDate = "creation_date";
final String _fridgeExpiryDate = "expiry_date";
final String _fridgeDaysBefore = "days_before";
final String _fridgeMemo = "memo";

// Category columns
final String _categoryId = "cid";
final String _categoryName = "name";
final String _categoryColor = "color";

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db == null) {
      _db = await _initDatabase();
    }
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'fridge.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create category table
        await db.execute('''
          CREATE TABLE $_categoryTableName (
            $_categoryId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_categoryName TEXT NOT NULL UNIQUE,
            $_categoryColor INTEGER NOT NULL
          )
        ''');

        // Insert default categories
        await _insertDefaultCategories(db);

        // Create fridge table
        await db.execute('''
          CREATE TABLE $_fridgeTableName (
            $_fridgeId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_fridgeProductName TEXT NOT NULL,
            $_fridgeCategoryId INTEGER NOT NULL,
            $_fridgeCreationDate INTEGER NOT NULL,
            $_fridgeExpiryDate INTEGER NOT NULL,
            $_fridgeDaysBefore INTEGER NOT NULL,
            $_fridgeMemo TEXT,
            FOREIGN KEY ($_fridgeCategoryId) REFERENCES $_categoryTableName($_categoryId)
          )
        ''');
      },
    );
  }

  Future<void> _insertDefaultCategories(Database db) async {
    // Example default categories with colors (ARGB)
    final defaultCategories = [
      {'name': '野菜', 'color': Color.fromARGB(255, 76, 175, 80).value}, // Green
      {'name': '果物', 'color': Color.fromARGB(255, 255, 193, 7).value}, // Yellow
      {'name': '肉', 'color': Color.fromARGB(255, 244, 67, 54).value}, // Red
      {'name': '魚', 'color': Color.fromARGB(255, 33, 150, 243).value}, // Blue
      {
        'name': '乳製品',
        'color': Color.fromARGB(255, 156, 39, 176).value,
      }, // Purple
      {'name': '冷凍食品', 'color': Color.fromARGB(255, 0, 188, 212).value}, // Cyan
    ];

    for (var category in defaultCategories) {
      await db.insert(_categoryTableName, category);
    }
  }

  // Category methods
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_categoryTableName);
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> addCategory(String name, int colorValue) async {
    final db = await database;
    return await db.insert(_categoryTableName, {
      _categoryName: name,
      _categoryColor: colorValue,
    });
  }

  // Fridge item methods
  Future<int> addFridgeItem({
    required String productName,
    required int categoryId,
    required DateTime creationDate,
    required DateTime expiryDate,
    required int daysBefore,
    String? memo,
  }) async {
    final db = await database;
    return await db.insert(_fridgeTableName, {
      _fridgeProductName: productName,
      _fridgeCategoryId: categoryId,
      _fridgeCreationDate: creationDate.millisecondsSinceEpoch,
      _fridgeExpiryDate: expiryDate.millisecondsSinceEpoch,
      _fridgeDaysBefore: daysBefore,
      _fridgeMemo: memo,
    });
  }

  Future<void> removeFridgeItem(int id) async {
    final db = await database;
    await db.delete(_fridgeTableName, where: '$_fridgeId = ?', whereArgs: [id]);
  }

  Future<int> updateFridgeItem(
    int id, {
    String? productName,
    int? categoryId,
    DateTime? creationDate,
    DateTime? expiryDate,
    int? daysBefore,
    String? memo,
  }) async {
    final db = await database;
    Map<String, Object?> updateValues = {};

    if (productName != null) updateValues[_fridgeProductName] = productName;
    if (categoryId != null) updateValues[_fridgeCategoryId] = categoryId;
    if (creationDate != null)
      updateValues[_fridgeCreationDate] = creationDate.millisecondsSinceEpoch;
    if (expiryDate != null)
      updateValues[_fridgeExpiryDate] = expiryDate.millisecondsSinceEpoch;
    if (daysBefore != null) updateValues[_fridgeDaysBefore] = daysBefore;
    if (memo != null) updateValues[_fridgeMemo] = memo;

    if (updateValues.isEmpty) return 0;

    return await db.update(
      _fridgeTableName,
      updateValues,
      where: '$_fridgeId = ?',
      whereArgs: [id],
    );
  }

  Future<List<FridgeItem>> getFridgeItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT f.$_fridgeId, 
           f.$_fridgeProductName, 
           f.$_fridgeCategoryId, 
           f.$_fridgeCreationDate, 
           f.$_fridgeExpiryDate, 
           f.$_fridgeDaysBefore, 
           f.$_fridgeMemo,
           c.$_categoryId,
           c.$_categoryName,
           c.$_categoryColor
    FROM $_fridgeTableName f
    INNER JOIN $_categoryTableName c
      ON f.$_fridgeCategoryId = c.$_categoryId
    ORDER BY f.$_fridgeExpiryDate ASC
  ''');

    return maps.map((map) => FridgeItem.fromMap(map)).toList();
  }
}

class FridgeItem {
  final int id;
  final String productName;
  final int creationDate; // Unix timestamp (int)
  final int expiryDate;
  final String? memo;
  final Category category;

  FridgeItem({
    required this.id,
    required this.productName,
    required this.creationDate,
    required this.expiryDate,
    this.memo,
    required this.category,
  });

  factory FridgeItem.fromMap(Map<String, dynamic> map) {
    return FridgeItem(
      id: map[_fridgeId] as int,
      productName: map[_fridgeProductName] as String,
      creationDate: map[_fridgeCreationDate] as int,
      expiryDate: map[_fridgeExpiryDate] as int,
      memo: map[_fridgeMemo] as String?,
      category: Category.fromMap(map),
    );
  }

  int getDaysRemaining() {
    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(this.expiryDate);
    return expiryDateTime.difference(DateTime.now()).inDays;
  }
}

class Category {
  final int id;
  final String name;
  final int color; // store as ARGB int in DB

  Category({required this.id, required this.name, required this.color});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map[_categoryId] as int,
      name: map[_categoryName] as String,
      color: map[_categoryColor] as int,
    );
  }
}
