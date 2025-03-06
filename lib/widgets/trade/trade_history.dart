// lib/widgets/trade/trade_history.dart
import 'package:flutter/material.dart';
import '../../models/trade_package.dart';

class TradeHistoryWidget extends StatelessWidget {
  final List<TradePackage> trades;

  const TradeHistoryWidget({
    super.key,
    required this.trades,
  });

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return const Center(
        child: Text('No trades have been made yet.'),
      );
    }

    return ListView.builder(
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trade header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trade #${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Chip(
                      label: Text(
                        trade.isGreatTrade ? 'Great Value' : 'Fair Trade',
                      ),
                      backgroundColor: trade.isGreatTrade
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                    ),
                  ],
                ),
                const Divider(),
                
                // Trade details
                Text(
                  trade.tradeDescription,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Trade value
                Text(
                  'Value: ${trade.totalValueOffered.toStringAsFixed(0)} points for ${trade.targetPickValue.toStringAsFixed(0)} points',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                // Future pick info if applicable
                if (trade.includesFuturePick) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Includes future pick: ${trade.futurePickDescription}',
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}