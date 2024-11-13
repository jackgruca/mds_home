import 'package:flutter/material.dart';

class AvailablePlayersPage extends StatelessWidget {
  final List<List<dynamic>> availablePlayers;

  AvailablePlayersPage({required this.availablePlayers});

  @override
  Widget build(BuildContext context) {
//    if (availablePlayers.isEmpty || availablePlayers.length <= 1) {
//      return Center(child: CircularProgressIndicator());
//    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: [
            DataColumn(label: Text('x')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Position')),
          ],
          rows: availablePlayers
              .skip(1) // Skipping header row
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row[0].toString())),
                    DataCell(Text(row[1].toString())),
                    DataCell(Text(row[2].toString())),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}      