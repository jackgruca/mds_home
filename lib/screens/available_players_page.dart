import 'package:flutter/material.dart';

class AvailablePlayersPage extends StatelessWidget {
  final List<List<dynamic>> availablePlayers;

  AvailablePlayersPage({required this.availablePlayers});

  @override
  Widget build(BuildContext context) {
    if (availablePlayers.isEmpty || availablePlayers.length <= 1) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Position')),
            DataColumn(label: Text('mddRank')),
          ],
          rows: availablePlayers
              .skip(1) // Skipping header row
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row.length > 0 ? row[0].toString() : 'N/A')), // Player ID
                    DataCell(Text(row.length > 1 ? row[1].toString() : 'N/A')), // Player name
                    DataCell(Text(row.length > 2 ? row[2].toString() : 'N/A')), // Position
                    DataCell(Text(row.length > 3 ? row[4].toString() : 'N/A')), // Rank Combined
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}