import 'package:flutter/material.dart';

class TeamNeedsPage extends StatelessWidget {
  final List<List<dynamic>> teamNeeds;

  TeamNeedsPage({required this.teamNeeds});

  @override
  Widget build(BuildContext context) {
    if (teamNeeds.isEmpty || teamNeeds.length <= 1) {
      return Center(child: CircularProgressIndicator());
    }

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
                    DataCell(Text(row.length > 0 ? row[0].toString() : 'N/A')), // Team name
                    DataCell(Text(row.length > 1 ? row[1].toString() : 'N/A')), // Needs
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}