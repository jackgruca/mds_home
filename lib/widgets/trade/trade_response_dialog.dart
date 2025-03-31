// lib/widgets/trade/trade_response_dialog.dart
import 'package:flutter/material.dart';
import '../../models/trade_package.dart';
import '../../services/draft_value_service.dart';
import '../../models/trade_motivation.dart';

class TradeResponseDialog extends StatelessWidget {
  final TradePackage tradePackage;
  final bool wasAccepted;
  final String? rejectionReason;
  final VoidCallback onClose;
  final Map<String, dynamic>? improvements;
  final TradeMotivation? motivation;

  const TradeResponseDialog({
    super.key,
    required this.tradePackage,
    required this.wasAccepted,
    this.rejectionReason,
    required this.onClose,
    this.improvements,
    this.motivation,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        wasAccepted ? 'Trade Accepted!' : 'Trade Rejected',
        style: TextStyle(
          color: wasAccepted ? Colors.green : Colors.red,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trade details
              Text(
                wasAccepted
                    ? 'Your trade proposal has been accepted!'
                    : 'Your trade proposal was rejected.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Trade summary
              const Text(
                'Trade Summary:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(tradePackage.tradeDescription),
              const SizedBox(height: 16),
              
              // Trade value
              const Text(
                'Trade Value:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Your offer: ${tradePackage.totalValueOffered.toStringAsFixed(0)} points'),
              Text('Their pick: ${tradePackage.targetPickValue.toStringAsFixed(0)} points'),
              Text(
                'Difference: ${(tradePackage.totalValueOffered - tradePackage.targetPickValue).toStringAsFixed(0)} points',
                style: TextStyle(
                  color: tradePackage.totalValueOffered >= tradePackage.targetPickValue
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Motivation section if available
if (motivation != null) ...[
  const SizedBox(height: 16),
  const Text(
    'Team Motivation:',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 8),
  Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: wasAccepted ? Colors.green.shade50 : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: wasAccepted ? Colors.green.shade200 : Colors.blue.shade200
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          motivation.primaryMotivation,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (motivation.motivationDescription.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(motivation.motivationDescription),
        ]
      ],
    ),
  ),
],
              
              // Rejection reason if applicable
              if (!wasAccepted && rejectionReason != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Reason:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    rejectionReason!,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              
              // Suggested improvements if rejected
              if (!wasAccepted && improvements != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Suggested Improvements:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(improvements!['suggestionText'] ?? "Try adding more draft value to make this offer acceptable."),
                      if (improvements!['futureText'] != null) ...[
                        const SizedBox(height: 4),
                        Text(improvements!['futureText']),
                      ],
                    ],
                  ),
                ),
              ],
              
              // Picks involved
              const SizedBox(height: 16),
              const Text(
                'Picks Involved:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1),
                },
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Pick #', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Target pick
                  TableRow(
                    decoration: BoxDecoration(
                      color: wasAccepted ? Colors.green.shade50 : Colors.red.shade50
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('#${tradePackage.targetPick.pickNumber}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(tradePackage.teamReceiving),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(DraftValueService.getValueDescription(tradePackage.targetPickValue)),
                      ),
                    ],
                  ),
                  // Offered picks
                  ...tradePackage.picksOffered.map((pick) => TableRow(
                    decoration: BoxDecoration(
                      color: wasAccepted ? Colors.green.shade50 : Colors.grey.shade100
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('#${pick.pickNumber}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(tradePackage.teamOffering),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(DraftValueService.getValueDescription(
                          DraftValueService.getValueForPick(pick.pickNumber)
                        )),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}