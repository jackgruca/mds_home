import 'package:flutter/material.dart';

class AvailablePlayersTab extends StatelessWidget {
  final List<List<dynamic>> availablePlayers = [
    ["ID", "Name", "Position", "Rank Combined"],
    [1, "John Doe", "QB", "A"],
    [2, "Jane Doe", "WR", "B"],
  ];

  AvailablePlayersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Position')),
            DataColumn(label: Text('Rank Combined')),
          ],
          rows: availablePlayers
              .skip(1) // Skipping header row
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row[0].toString())),
                    DataCell(Text(row[1].toString())),
                    DataCell(Text(row[2].toString())),
                    DataCell(Text(row[3].toString())),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
