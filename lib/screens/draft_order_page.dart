import 'package:flutter/material.dart';

class DraftOrderPage extends StatelessWidget {
  final List<List<dynamic>> draftOrder;

  DraftOrderPage({required this.draftOrder});

  @override
  Widget build(BuildContext context) {
    if (draftOrder.isEmpty || draftOrder.length <= 1) {
      return Center(child: CircularProgressIndicator());
    }

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
              .skip(1) // Skip header row
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
