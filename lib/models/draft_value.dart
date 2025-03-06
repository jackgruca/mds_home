// lib/models/draft_value.dart
class DraftValue {
  final int pick;
  final double value;

  DraftValue({
    required this.pick,
    required this.value,
  });

  factory DraftValue.fromCsvRow(List<dynamic> row) {
    return DraftValue(
      pick: int.tryParse(row[0].toString()) ?? 0,
      value: double.tryParse(row[1].toString()) ?? 0.0,
    );
  }
}