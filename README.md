# Sample
```
class SqlModel implements ISQLiteItem {
  int? id;
  String? title;
  String? value;

  SqlModel({this.id, this.title, this.value});

  @override
  String getTableName() {
    return 'sql_model';
  }

  @override
  int getPrimaryKey() {
    return id ?? 0;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'value': value,
    };
  }

  @override
  String getPrimaryKeyName() {
    return 'id';
  }

  @override
  ISQLiteItem fromMap(Map<String, dynamic> map) {
    return SqlModel(
      id: map['id'],
      title: map['title'],
      value: map['value'],
    );
  }
}

```
# Create instance of SQLiteConnection
```
Future<void> insertIntoDatabase(ISQLiteItem item,
      {bool insert = true}) async {
    final databasePath = await getTemporaryDatabasePath();
    final connection = SQLiteConnection(path: databasePath);
    await connection.createTable(item);
    if (insert) {
      await connection.insert(item);
    } else {
      await connection.update(item);
    }
  }
```