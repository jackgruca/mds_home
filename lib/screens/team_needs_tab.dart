import 'package:flutter/material.dart';

class TeamNeedsTab extends StatelessWidget {
  final List<List<dynamic>> teamNeeds = [
    ["Team", "Needs"],
    ["Chicago Bears", "QB, OL, WR"],
    ["Houston Texans", "QB, RB, CB"],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('Needs')),
          ],
          rows: teamNeeds
              .skip(1) // Skipping header row
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row[0].toString())),
                    DataCell(Text(row[1].toString())),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
