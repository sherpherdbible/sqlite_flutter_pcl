import 'package:flutter/material.dart';
import 'package:sqlite_flutter_pcl/sqlite_connetion.dart';


import 'path_helper.dart';
import 'sql_model.dart';

class ViewSample extends StatefulWidget {
  const ViewSample({super.key});

  @override
  State<ViewSample> createState() => _ViewSampleState();
}

class _ViewSampleState extends State<ViewSample> {
  List<ISQLiteItem> sampleItems = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () async {
            sampleItems = [
              SqlModel(title: 'Sample Title 1', value: 'Sample Value 1'),
              SqlModel(title: 'Sample Title 2', value: 'Sample Value 2'),
              SqlModel(title: 'Sample Title 3', value: 'Sample Value 3'),
              SqlModel(title: 'Sample Title 4', value: 'Sample Value 4'),
              SqlModel(title: 'Sample Title 5', value: 'Sample Value 5'),
            ];
            final databasePath = await getTemporaryDatabasePath();
            final connection = SQLiteConnection(path: databasePath);
            connection.createTable(SqlModel());
            for (var item in sampleItems) {
              await connection.insert(item); // Await here
            }
            setState(() {});
          },
          child: const Text('Insert'),
        ),
        OutlinedButton(
          onPressed: () async {
            final databasePath = await getTemporaryDatabasePath();
            final connection = SQLiteConnection(path: databasePath);
            final retrievedItems = await connection.toList(SqlModel());

            setState(() {
              sampleItems = retrievedItems; // Update the list after retrieval
            });
          },
          child: const Text('Retrieve'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sampleItems.length,
            itemBuilder: (context, index) {
              var item = sampleItems[index] as SqlModel;
              return ListTile(
                title: Text(item.title!),
                subtitle: Text(item.value!),
              );
            },
          ),
        ),
      ],
    );
  }
}
