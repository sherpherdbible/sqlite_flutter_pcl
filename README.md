# Create table class implements ISQLiteItem
``` dart
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
``` dart
   //Init if SQLiteConnection not initialize when new instance created
    SQLiteConnection.initDatabaseLib();
    //Sqlite filepath
    final databasePath = await getTemporaryDatabasePath();
    final connection = SQLiteConnection(path: databasePath);
    //create table
    connection.createTable(SqlModel());
    //insert new item;
    var newItem = SqlModel(title: 'Title 1', value: 'Value 1');
    await connection.insert(newItem);
    //retrieve items
    var isqliteItems = await connection.toList(SqlModel());
    //convert to type list
    var items = isqliteItems.whereType<SqlModel>().toList();
    //update items
    for (var item in items) {
      item.value = 'Updated';
      await connection.update(item);
    }
    //OR
    await connection.updateAll(items);
    //delete items
    await connection.deleteAll(items);
    //query single value
    var queryItems = await connection.where(SqlModel(), 'title', 'Title 1');
    //search items
    var searchItems = await connection.search(SqlModel(), 'title', 'title 1');
    //query with multiple columns
    Map<String, dynamic> columnNameAndValues = {
      'title': 'Title 1',
      'value': 'Value 2',
    };
    var results = await connection.whereOr(SqlModel(), columnNameAndValues);

    //Delete all table records
    connection.deleteRecords(SqlModel());
    //Delete table
    connection.deleteTable(SqlModel());
```
[pub.dev](https://pub.dev/packages/sqlite_flutter_pcl)