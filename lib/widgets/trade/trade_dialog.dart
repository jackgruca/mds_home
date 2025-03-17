// lib/widgets/trade/trade_dialog.dart
import 'package:flutter/material.dart';
import '../../models/trade_package.dart';
import '../../models/trade_offer.dart';
import '../../services/draft_value_service.dart';

class TradeDialog extends StatefulWidget {
  final TradeOffer tradeOffer;
  final Function(TradePackage) onAccept;
  final VoidCallback onReject;

  const TradeDialog({
    super.key,
    required this.tradeOffer,
    required this.onAccept,
    required this.onReject,
  });

  @override
  _TradeDialogState createState() => _TradeDialogState();
}

class _TradeDialogState extends State<TradeDialog> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.tradeOffer.packages.isEmpty) {
      return AlertDialog(
        title: const Text('No Trade Offers'),
        content: const Text('There are no trade offers available for this pick.'),
        actions: [
          TextButton(
            onPressed: widget.onReject,
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Trade Offers for Pick #${widget.tradeOffer.pickNumber}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team selector tabs
            _buildTeamSelector(),
            const Divider(),
            // Trade details
            _buildTradeDetails(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onReject,
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAccept(widget.tradeOffer.packages[_selectedIndex]);
          },
          child: const Text('Accept Trade'),
        ),
      ],
    );
  }

  Widget _buildTeamSelector() {
    final offeringTeams = widget.tradeOffer.offeringTeams;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          offeringTeams.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(offeringTeams[index]),
              selected: _selectedIndex == index,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTradeDetails() {
    final package = widget.tradeOffer.packages[_selectedIndex];
    final isFair = package.isFairTrade;
    final isGreat = package.isGreatTrade;
    
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trade summary
            const Text(
              'Trade Summary:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(package.tradeDescription),
            const SizedBox(height: 16),
            
            // Trade value
            const Text(
              'Trade Value:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(package.valueSummary),
            const SizedBox(height: 8),
            
            // Value indicator
            LinearProgressIndicator(
              value: package.totalValueOffered / package.targetPickValue,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isGreat ? Colors.green : (isFair ? Colors.blue : Colors.orange),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isGreat 
                ? 'Great value! (${((package.totalValueOffered / package.targetPickValue) * 100).toStringAsFixed(0)}%)'
                : (isFair 
                  ? 'Fair trade (${((package.totalValueOffered / package.targetPickValue) * 100).toStringAsFixed(0)}%)'
                  : 'Below market value (${((package.totalValueOffered / package.targetPickValue) * 100).toStringAsFixed(0)}%)'),
              style: TextStyle(
                color: isGreat ? Colors.green : (isFair ? Colors.blue : Colors.orange),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Picks involved
            const Text(
              'Picks Involved:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildPicksTable(package),
          ],
        ),
      ),
    );
  }

  Widget _buildPicksTable(TradePackage package) {
    return Table(
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
          decoration: BoxDecoration(color: Colors.blue.shade50),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('#${package.targetPick.pickNumber}'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(package.teamReceiving),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(DraftValueService.getValueDescription(package.targetPickValue)),
            ),
          ],
        ),
        // Offered picks
        ...package.picksOffered.map((pick) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('#${pick.pickNumber}'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(package.teamOffering),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(DraftValueService.getValueDescription(
                DraftValueService.getValueForPick(pick.pickNumber)
              )),
            ),
          ],
        )),
        // Future pick if included
        if (package.includesFuturePick)
          TableRow(
            decoration: BoxDecoration(color: Colors.amber.shade50),
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Future'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(package.teamOffering),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(DraftValueService.getValueDescription(
                  package.futurePickValue ?? 0
                )),
              ),
            ],
          ),
      ],
    );
  }
}