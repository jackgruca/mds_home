import 'package:flutter/material.dart';

class AvailablePlayersPage extends StatelessWidget {
  final List<List<dynamic>> draftOrder;

  AvailablePlayersPage({required this.draftOrder});

  @override
  Widget build(BuildContext context) {
    if (draftOrder.isEmpty || draftOrder.length <= 1) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: draftOrder.length - 1,
        itemBuilder: (context, index) {
          final row = draftOrder[index + 1]; // Skip header row
          return ListTile(
            title: Text(row[1].toString()),
            subtitle: Text('Pick: ${row[0]}, Previous Record: ${row[2]}'),
          );
        },
      ),
    );
  }
}
