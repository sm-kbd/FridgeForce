import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  final String _fridgeTableName = "fridge";
  final String _fridgeIdColumnName = "id";
  final String _fridgeDateColumnName = "date";
  final String _fridgeItemColumnName = "item";
  final String _fridgeBuyDateColumnName = "buy_date";
  final String _fridgeExpiryDateColumnName = "expiry_date";
  final String _fridgeStockColumnName = "stock";
  final String _fridgeMemoColumnName = "memo";
  final String _fridgeThumbnailColumnName = "thumbnail_image";

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db == null) {
      _db = await getDatabase();
    }
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "fridge.db");
    print(databasePath);
    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) {
        db.execute("""
                        CREATE TABLE $_fridgeTableName (
                            $_fridgeIdColumnName INTEGER PRIMARY KEY,
                            $_fridgeDateColumnName INTEGER NOT NULL,
                            $_fridgeItemColumnName TEXT NOT NULL,
                            $_fridgeBuyDateColumnName INTEGER NOT NULL,
                            $_fridgeExpiryDateColumnName INTEGER NOT NULL,
                            $_fridgeStockColumnName INTEGER,
                            $_fridgeMemoColumnName TEXT,
                            $_fridgeThumbnailColumnName TEXT NOT NULL
                            )
                        """);
      },
    );
    return database;
  }

  void addItem({
    required String item,
    required int buyDate,
    required int expiryDate,
    required int stock,
    required String thumbnail,
    String? memo = null,
  }) async {
    int date = DateTime.now().millisecondsSinceEpoch;
    stock ??= 1;
    final db = await database;
    await db.insert(_fridgeTableName, {
      _fridgeDateColumnName: date,
      _fridgeItemColumnName: item,
      _fridgeBuyDateColumnName: buyDate,
      _fridgeExpiryDateColumnName: expiryDate,
      _fridgeStockColumnName: stock,
      _fridgeMemoColumnName: memo,
      _fridgeThumbnailColumnName: thumbnail,
    });
  }

  void updateItem(
    int id, {
    String? item,
    int? buyDate,
    int? expiryDate,
    int? stock,
    String? thumbnail,
    String? memo,
  }) async {
    Map<String, Object?> updateValues = {};

    if (item != null) {
      updateValues[_fridgeItemColumnName] = item;
    }
    if (buyDate != null) {
      updateValues[_fridgeBuyDateColumnName] = buyDate;
    }
    if (expiryDate != null) {
      updateValues[_fridgeExpiryDateColumnName] = expiryDate;
    }
    if (stock != null) {
      updateValues[_fridgeStockColumnName] = stock;
    }
    if (thumbnail != null) {
      updateValues[_fridgeThumbnailColumnName] = thumbnail;
    }
    if (memo != null) {
      updateValues[_fridgeMemoColumnName] = memo;
    }

    if (updateValues.isEmpty) {
      return;
    }

    final db = await database;
    await db.update(
      _fridgeTableName,
      updateValues,
      where: "$_fridgeIdColumnName = ?",
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getItem({
    int? id,
    String? item,
    int? buyDate,
    int? expiryDate,
    int? stock,
    List<String>? columns,
  }) async {
    columns ??= ["*"];
    List<String> whereConditions = [];
    List<Object?> whereArgs = [];

    if (id != null) {
      whereConditions.add("$_fridgeIdColumnName = ?");
      whereArgs.add(id);
    }
    if (item != null) {
      whereConditions.add("$_fridgeItemColumnName = ?");
      whereArgs.add(item);
    }
    if (buyDate != null) {
      whereConditions.add("$_fridgeBuyDateColumnName = ?");
      whereArgs.add(buyDate);
    }
    if (expiryDate != null) {
      whereConditions.add("$_fridgeExpiryDateColumnName = ?");
      whereArgs.add(expiryDate);
    }
    if (stock != null) {
      whereConditions.add("$_fridgeStockColumnName = ?");
      whereArgs.add(stock);
    }

    final db = await database;

    if (whereConditions.isEmpty) {
      return await db.query(_fridgeTableName);
    }

    return await db.query(
      _fridgeTableName,
      where: whereConditions.join(" AND "),
      whereArgs: whereArgs,
      columns: columns,
    );
  }
}

/*
usage example:
final DatabaseService db = DatabaseService.instance;
db.database;
db.addItem(
item: "food1",
buyDate: 234567890,
expiryDate: 87654322,
stock: 11,
thumbnail: "default location");
db.updateItem(
1,
item: "food0",
buyDate: 1
);
db.getItem().then((items) {
for (var item in items) {
print("Name: ${item['id']}");
}
});

*/
