// lib/widgets/trade/user_trade_tabs_dialog.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/trade_package.dart';
import 'user_trade_dialog.dart';

class UserTradeTabsDialog extends StatefulWidget {
  final String userTeam;
  final List<DraftPick> userPicks;
  final List<DraftPick> targetPicks;
  final Map<int, List<TradePackage>> pendingOffers;
  final Function(TradePackage) onAcceptOffer;
  final Function(TradePackage) onPropose;
  final VoidCallback onCancel;

  const UserTradeTabsDialog({
    super.key,
    required this.userTeam,
    required this.userPicks,
    required this.targetPicks,
    required this.pendingOffers,
    required this.onAcceptOffer,
    required this.onPropose,
    required this.onCancel,
  });

  @override
  _UserTradeTabsDialogState createState() => _UserTradeTabsDialogState();
}

class _UserTradeTabsDialogState extends State<UserTradeTabsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trade Center', style: TextStyle(fontSize: 20)),
      contentPadding: EdgeInsets.zero, // Remove default padding
      insetPadding: const EdgeInsets.all(12), // Reduced inset padding
      content: SizedBox(
        width: double.maxFinite,
        height: 520, // Give enough height but don't take too much
        child: Column(
          children: [
            // Compact tab bar
            TabBar(
              controller: _tabController,
              labelPadding: const EdgeInsets.symmetric(vertical: 4.0),
              tabs: [
                Tab(
                  icon: Badge(
                    isLabelVisible: _getAllPendingOffers().isNotEmpty,
                    label: Text(_getAllPendingOffers().length.toString()),
                    child: const Icon(Icons.call_received, size: 16),
                  ),
                  text: 'Trade Offers',
                  iconMargin: const EdgeInsets.only(bottom: 2.0),
                ),
                const Tab(
                  icon: Icon(Icons.call_made, size: 16),
                  text: 'Create Trade',
                  iconMargin: EdgeInsets.only(bottom: 2.0),
                ),
              ],
            ),
            const Divider(height: 1),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pending offers tab
                  _buildPendingOffersTab(_getAllPendingOffers()),
                  
                  // Create trade tab
                  UserTradeProposalDialog(
                    userTeam: widget.userTeam,
                    userPicks: widget.userPicks,
                    targetPicks: widget.targetPicks,
                    onPropose: widget.onPropose,
                    onCancel: () {}, // Empty since we're using the dialog's close button
                    isEmbedded: true, // This flag makes it fit within the tab
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Compact action buttons
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Close'),
        ),
      ],
    );
  }
  
  Widget _buildPendingOffersTab(List<TradePackage> offers) {
    if (offers.isEmpty) {
      return const Center(
        child: Text('No trade offers available.'),
      );
    }
    
    return ListView.builder(
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offer from ${offer.teamOffering}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(offer.tradeDescription),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Value: ${offer.valueSummary}',
                        style: TextStyle(
                          color: offer.isFairTrade ? Colors.green : Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onAcceptOffer(offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Accept Offer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TradePackage> _getAllPendingOffers() {
    List<TradePackage> allOffers = [];
    widget.pendingOffers.forEach((_, offers) {
      allOffers.addAll(offers);
    });
    return allOffers;
  }
}