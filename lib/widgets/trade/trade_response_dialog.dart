// lib/widgets/trade/trade_response_dialog.dart
import 'package:flutter/material.dart';
import '../../models/trade_package.dart';
import '../../services/draft_value_service.dart';

class TradeResponseDialog extends StatelessWidget {
  final TradePackage tradePackage;
  final bool wasAccepted;
  final String? rejectionReason;
  final VoidCallback onClose;

  const TradeResponseDialog({
    super.key,
    required this.tradePackage,
    required this.wasAccepted,
    this.rejectionReason,
    required this.onClose,
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
            
            // Rejection reason if applicable
            if (!wasAccepted && rejectionReason != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Reason:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                rejectionReason!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
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
            // Future picks section if applicable
if (tradePackage.includesFuturePick || 
    (tradePackage.targetReceivedFuturePicks != null && 
     tradePackage.targetReceivedFuturePicks!.isNotEmpty)) ...[
  const SizedBox(height: 16),
  const Text(
    'Future Picks:',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 8),
  
  // If offering team sends future picks
  if (tradePackage.includesFuturePick && 
      tradePackage.futurePickDescription != null) ...[
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.amber.shade800),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${tradePackage.teamOffering} sends: ${tradePackage.futurePickDescription}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
  ],
  
  // If receiving team sends future picks
  if (tradePackage.targetReceivedFuturePicks != null && 
      tradePackage.targetReceivedFuturePicks!.isNotEmpty) ...[
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.teal.shade800),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${tradePackage.teamReceiving} sends: ${tradePackage.targetReceivedFuturePicks!.join(", ")}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
        ),
      ],
    ),
  ],
],
          ],
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