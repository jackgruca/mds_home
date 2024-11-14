import 'package:flutter/material.dart';

class DraftOrderTab extends StatelessWidget {
  final List<List<dynamic>> draftOrder = [
    ["Pick", "Team", "Previous Record"],
    [1, "Chicago Bears", "3-14"],
    [2, "Houston Texans", "3-13-1"],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Pick')),
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('Previous Record')),
          ],
          rows: draftOrder
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
