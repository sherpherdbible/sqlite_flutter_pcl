import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteConnection {
  ///The full sqlite file path
  final String path;

  SQLiteConnection({required this.path}) {
    _initLib();
  }
  void _initLib() {
    initDatabaseLib();
  }

  Future<Database> getOpenDatabase() async {
    var database = await openDatabase(path, version: 1);
    return database;
  }

  Future<List<ISQLiteItem>> toList(ISQLiteItem item) async {
    final db = await getOpenDatabase();
    final tableName = item.getTableName();
    final List<Map<String, dynamic>> results = await db.query(tableName);
    // Convert the query results into a list of ISQLiteItem objects
    final List<ISQLiteItem> items =
        results.map((map) => item.fromMap(map)).toList();
    return items;
  }

  Future<List<ISQLiteItem>> getRandomItems(ISQLiteItem item, int count) async {
    final db = await getOpenDatabase();
    final tableName = item.getTableName();

    // Query the table and order by random, limit by the given count
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT * FROM $tableName ORDER BY RANDOM() LIMIT ?',
      [count], // Use parameterized queries to avoid SQL injection
    );

    // Convert the query results into a list of ISQLiteItem objects
    final List<ISQLiteItem> items =
        results.map((map) => item.fromMap(map)).toList();

    return items;
  }

  Future<int> insert(ISQLiteItem item) async {
    var db = await getOpenDatabase();
    var map = item.toMap();
    if (map[item.getPrimaryKeyName()] is int &&
        map[item.getPrimaryKeyName()] == 0) {
      map[item.getPrimaryKeyName()] = null;
    }
    var row = await db.insert(item.getTableName(), map);
    return row;
  }

  Future<int> insertAll(List<ISQLiteItem> items) async {
    var db = await getOpenDatabase();
    var totalRow = 0;
    for (var item in items) {
      var map = item.toMap();
      if (map[item.getPrimaryKeyName()] is int &&
          map[item.getPrimaryKeyName()] == 0) {
        map[item.getPrimaryKeyName()] = null;
      }
      await db.insert(item.getTableName(), map);
      totalRow++;
    }
    return totalRow;
  }

  Future<void> update(ISQLiteItem item) async {
    final db = await getOpenDatabase();
    final map = item.toMap();
    final id = map[item.getPrimaryKeyName()];

    if (id != null) {
      // Perform an update with the same ID
      await db.update(item.getTableName(), map,
          where: '${item.getPrimaryKeyName()} = ?', whereArgs: [id]);
    } else {
      // Handle the case where ID is null (e.g., insert as a new record or raise an error)
    }
  }

  Future<void> updateAll(List<ISQLiteItem> items) async {
    final db = await getOpenDatabase();
    for (var item in items) {
      final map = item.toMap();
      final id = map[item.getPrimaryKeyName()];

      if (id != null) {
        // Perform an update with the same ID
        await db.update(item.getTableName(), map,
            where: '${item.getPrimaryKeyName()} = ?', whereArgs: [id]);
      } else {
        // Handle the case where ID is null (e.g., insert as a new record or raise an error)
      }
    }
  }

  Future<int> delete(ISQLiteItem item) async {
    var db = await getOpenDatabase();
    final primaryKeyValue = item.toMap()[item.getPrimaryKeyName()];
    var rowsDeleted = 0;
    if (primaryKeyValue != null) {
      rowsDeleted = await db.delete(
        item.getTableName(),
        where: '${item.getPrimaryKeyName()} = ?',
        whereArgs: [primaryKeyValue],
      );
    } else {
      // Handle the case where the primary key is null (e.g., raise an error).
      // Return 0 to indicate that no rows were deleted.
    }
    return rowsDeleted;
  }

  Future<int> deleteAll(List<ISQLiteItem> items) async {
    var db = await getOpenDatabase();
    var totalDeleted = 0;
    for (var item in items) {
      final primaryKeyValue = item.toMap()[item.getPrimaryKeyName()];

      if (primaryKeyValue != null) {
        await db.delete(
          item.getTableName(),
          where: '${item.getPrimaryKeyName()} = ?',
          whereArgs: [primaryKeyValue],
        );
        totalDeleted++;
      } else {
        // Handle the case where the primary key is null (e.g., raise an error).
        // Return 0 to indicate that no rows were deleted.
      }
    }
    return totalDeleted;
  }

  Future<void> deleteTable(ISQLiteItem item) async {
    final database = await getOpenDatabase();
    await database.execute('DROP TABLE IF EXISTS ${item.getTableName()}');
    database.close();
  }

  Future<void> deleteRecords(ISQLiteItem item) async {
    final db = await getOpenDatabase();
    await db.rawDelete('DELETE FROM ${item.getTableName()}');
    // Reset the auto-increment primary key to 1
    await db.rawUpdate(
        'DELETE FROM sqlite_sequence WHERE name = ?', [item.getTableName()]);
  }

  Future<List<ISQLiteItem>> where(
      ISQLiteItem item, String columnName, String columnValueOf,
      {int? limit}) async {
    String condition = '$columnName = ?';
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();
    var maps = await db.query(
      item.getTableName(),
      where: condition,
      whereArgs: [columnValueOf], // Pass the value as an array
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  Future<List<ISQLiteItem>> whereAnd(
      ISQLiteItem item, Map<String, dynamic> columnNameAndValues,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnNameAndValues.forEach((columnName, columnValue) {
      whereConditions.add('$columnName = ?');
      whereArgs.add(columnValue);
    });

    String condition = whereConditions.join(' AND ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  Future<List<ISQLiteItem>> whereOr(
      ISQLiteItem item, Map<String, dynamic> columnNameAndValues,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnNameAndValues.forEach((columnName, columnValue) {
      whereConditions.add('$columnName = ?');
      whereArgs.add(columnValue);
    });

    String condition = whereConditions.join(' OR ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  /// Performs a case-sensitive search in multiple columns of an SQLite table with AND condition.
  ///
  /// This method searches for the specified values in the given [columnNameAndValues]
  /// of the [tableName] and returns a list of items that match all the search criteria.
  /// It uses the LIKE operator for searching.
  ///
  /// Parameters:
  /// - [item]: An instance of ISQLiteItem representing the database table schema.
  /// - [columnNameAndValues]: A map of column names and values to search for.
  ///
  /// Returns a list of ISQLiteItem objects that match all the search criteria.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<ISQLiteItem> searchResults = await whereSearchAnd(
  ///   MyDatabaseItem(), // Replace with your ISQLiteItem implementation
  ///   {
  ///     'title': 'flutter',
  ///     'category': 'mobile',
  ///   },
  /// );
  ///
  /// for (var result in searchResults) {
  ///   print(result.toString());
  /// }
  /// ```

  Future<List<ISQLiteItem>> whereSearchAnd(
      ISQLiteItem item, Map<String, dynamic> columnNameAndValues,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnNameAndValues.forEach((columnName, columnValue) {
      // Modify the condition to use LIKE for searching
      whereConditions.add('$columnName LIKE ?');
      // Modify the whereArgs to use '%' for wildcard search
      whereArgs.add('%$columnValue%');
    });

    String condition = whereConditions.join(' AND ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  /// Performs a search in multiple columns of an SQLite table with exact matching (no "LIKE" operator)
  /// and an "AND" condition.
  ///
  /// This method searches for the specified exact values in the given [columnNameAndValues] of the
  /// [tableName] and returns a list of items that match all the search criteria.
  ///
  /// Parameters:
  /// - [item]: An instance of ISQLiteItem representing the database table schema.
  /// - [columnNameAndValues]: A map of column names and exact values to search for.
  ///
  /// Returns a list of ISQLiteItem objects that match all the search criteria.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<ISQLiteItem> searchResults = await whereSearchExactAnd(
  ///   MyDatabaseItem(), // Replace with your ISQLiteItem implementation
  ///   {
  ///     'title': 'Flutter',
  ///     'category': 'Mobile',
  ///   },
  /// );
  ///
  /// for (var result in searchResults) {
  ///   print(result.toString());
  /// }
  /// ```

  Future<List<ISQLiteItem>> whereSearchExactAnd(
      ISQLiteItem item, Map<String, dynamic> columnNameAndValues,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    columnNameAndValues.forEach((columnName, columnValue) {
      // Modify the condition to use = for exact matching
      whereConditions.add('$columnName = ?');
      whereArgs.add(columnValue);
    });

    String condition = whereConditions.join(' AND ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  /// Performs a case-insensitive search in multiple columns of an SQLite table.
  ///
  /// This method searches for the specified query in the given [columnNames] of the
  /// [tableName] and returns a list of items that match the search criteria. It uses
  /// the LIKE operator for searching and COLLATE NOCASE for case-insensitivity.
  ///
  /// Parameters:
  /// - [item]: An instance of ISQLiteItem representing the database table schema.
  /// - [columnNames]: A list of column names to search in.
  /// - [query]: The search query to match against the specified columns.
  ///
  /// Returns a list of ISQLiteItem objects that match the search criteria.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<ISQLiteItem> searchResults = await whereSearchOr(
  ///   MyDatabaseItem(), // Replace with your ISQLiteItem implementation
  ///   ['title', 'description', 'author'],
  ///   'flutter',
  /// );
  ///
  /// for (var result in searchResults) {
  ///   print(result.toString());
  /// }
  /// ```

  Future<List<ISQLiteItem>> whereSearchOr(
      ISQLiteItem item, List<String> columnNames, String query,
      {int? limit}) async {
    String tableName = item.getTableName();
    List<ISQLiteItem> results = [];
    var db = await getOpenDatabase();

    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    // Modify the condition to use LIKE for searching and COLLATE NOCASE for case-insensitivity
    for (var columnName in columnNames) {
      whereConditions.add('$columnName LIKE ? COLLATE NOCASE');
      whereArgs.add('%$query%');
    }

    String condition = whereConditions.join(' OR ');

    var maps = await db.query(
      tableName,
      where: condition,
      whereArgs: whereArgs,
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  /// Performs a case-insensitive search in a specified column of an SQLite table.
  ///
  /// This method searches for the specified [query] in the [columnName] of the [tableName] and returns
  /// a list of items that match the search criteria. It uses the LIKE operator for searching and
  /// COLLATE NOCASE for case-insensitivity.
  ///
  /// Parameters:
  /// - [item]: An instance of ISQLiteItem representing the database table schema.
  /// - [columnName]: The name of the column to search in.
  /// - [query]: The search query to match against the specified column.
  /// - [limit]: (Optional) The maximum number of results to return.
  ///
  /// Returns a list of ISQLiteItem objects that match the search criteria.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<ISQLiteItem> searchResults = await search(
  ///   MyDatabaseItem(), // Replace with your ISQLiteItem implementation
  ///   'title',
  ///   'flutter',
  ///   limit: 10,
  /// );
  ///
  /// for (var result in searchResults) {
  ///   print(result.toString());
  /// }
  /// ```

  Future<List<ISQLiteItem>> search(
      ISQLiteItem item, String columnName, String query,
      {int? limit}) async {
    var database = await getOpenDatabase();
    String table = item.getTableName();
    List<ISQLiteItem> results = [];
    var maps = await database.query(
      table,
      columns: null, // Fetch all columns
      where: "$columnName LIKE ? COLLATE NOCASE",
      whereArgs: ['%$query%'],
      limit: limit,
    );
    results = maps.map((map) => item.fromMap(map)).toList();
    return results;
  }

  Future<int> getCount(ISQLiteItem item) async {
    var db = await getOpenDatabase();
    var count =
        await db.rawQuery('SELECT COUNT(*) FROM ${item.getTableName()}');
    var total = Sqflite.firstIntValue(count) ?? 0;
    return total;
  }

  Future<void> createTable(ISQLiteItem item,
      {bool autoIncrement = true}) async {
    final db = await getOpenDatabase();
    final tableName = item.getTableName();
    final primaryKey = item.getPrimaryKeyName();

    final columns = <String>[];
    final map = item.toMap();

    map.forEach((key, value) {
      if (key == primaryKey) {
        if (value is int) {
          if (autoIncrement) {
            columns.add('$key INTEGER PRIMARY KEY AUTOINCREMENT');
          } else {
            columns.add('$key INTEGER');
          }
        } else if (value is String) {
          columns.add('$key TEXT PRIMARY KEY');
        } else if (value is Uint8List) {
          columns.add('$key BLOB'); // Add a BLOB column for byte arrays
        } else {
          if (autoIncrement) {
            columns.add('$key INTEGER PRIMARY KEY AUTOINCREMENT');
          } else {
            columns.add('$key INTEGER');
          }
        }
      } else {
        if (value is int) {
          columns.add('$key INTEGER');
        } else if (value is double) {
          columns.add('$key REAL');
        } else if (value is bool) {
          columns.add('$key INTEGER');
        } else if (value is Uint8List) {
          columns.add('$key BLOB'); // Add a BLOB column for byte arrays
        } else {
          columns.add('$key TEXT');
        }
      }
    });

    final createTableQuery =
        'CREATE TABLE IF NOT EXISTS $tableName (${columns.join(', ')});';

    await db.execute(createTableQuery);
    //start primarykey to 1
    // Check the current sequence value for the table
    var currentSeq = Sqflite.firstIntValue(
            await db.rawQuery('PRAGMA table_info($tableName)')) ??
        0;

    // If the current sequence value is 0, reset it to 1
    if (currentSeq < 1) {
      await db.rawUpdate(
        'UPDATE sqlite_sequence SET seq = 1 WHERE name = ?',
        [tableName],
      );
    }
  }

  //Static methods
  static Future<bool> isValidDatabaseFile(String filePath) async {
    final file = File(filePath);
    if (!(await file.exists())) {
      return false; // File does not exist
    }
    final headerBytes = await file.openRead(0, 16).first;
    // SQLite database file header
    const List<int> sqliteHeader = [
      0x53,
      0x51,
      0x4c,
      0x69,
      0x74,
      0x65,
      0x20,
      0x66,
      0x6f,
      0x72,
      0x6d,
      0x61,
      0x74,
      0x20,
      0x33,
      0x00
    ];

    return headerBytes.length == sqliteHeader.length &&
        headerBytes
            .every((byte) => byte == sqliteHeader[headerBytes.indexOf(byte)]);
  }

  static Future<Database> getDatabase(String sqliteFilePath,
      {int version = 1}) async {
    initDatabaseLib();
    var database = await openDatabase(sqliteFilePath, version: version);
    return database;
  }

  static bool _init = false;
  static bool initDatabaseLib() {
    if (_init == false) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Initialize FFI
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _init = true;
      }
    }
    return _init;
  }

  static Future<bool> areDatabaseTablesExist(
      String filePath, List<String> tables) async {
    Database database = await getDatabase(filePath);
    String tableNames = tables.map((table) => '"$table"').join(',');
    try {
      var tableQuery = await database.rawQuery(
          'SELECT name FROM sqlite_master WHERE type="table" AND name IN ($tableNames);');

      //printColor('Expected Tables: $tables');
      //printColor('Found Tables: ${tableQuery.map((row) => row['name'])}');

      return tableQuery.length == tables.length;
    } catch (e) {
      // Handle the exception here
      //printError('Error occurred while checking for tables: $e');
      return false; // Or any other appropriate action
    }
  }

  static Future<List<Map<String, dynamic>>?> getTableInfo(
      String filePath, String tableName) async {
    Database db = await getDatabase(filePath);
    final List<Map<String, dynamic>> tableInfo =
        await db.rawQuery("PRAGMA table_info($tableName);");

    // If the table does not exist, the result will be an empty list.
    // You can check if the list is empty and handle it accordingly.
    if (tableInfo.isEmpty) {
      return null; // Or you can return an empty list or handle the absence of the table in another way.
    }

    return tableInfo;
  }
}

abstract class ISQLiteItem {
  String getTableName();
  dynamic getPrimaryKey();
  String getPrimaryKeyName();
  Map<String, dynamic> toMap();
  ISQLiteItem fromMap(Map<String, dynamic> map);
}
