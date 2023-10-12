# Create table class implements ISQLiteItem
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
    return id;
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
//Init if SQLiteConnection not initialize when new instance created
    SQLiteConnection.initDatabaseLib();
    //Sqlite filepath
    final databasePath = await getTemporaryDatabasePath();
    final connection = SQLiteConnection(path: databasePath);
    //insert new item;
    var newItem = SqlModel(title: 'Title 1', value: 'Value 1');
    await connection.insert(newItem);
    //retrieve items
    var items = await connection.toList(SqlModel());
    //update items
    for (var item in items) {
      (item as SqlModel).value = 'Updated';
      await connection.update(item);
    }
    //Delete all table records
    connection.deleteAll(SqlModel());
    //Delete table
    connection.deleteTable(SqlModel());
    //create table
    connection.createTable(SqlModel());
```
[pub.dev](https://pub.dev/packages/sqlite_flutter_pcl)