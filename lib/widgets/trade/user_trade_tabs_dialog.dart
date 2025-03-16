// lib/widgets/trade/user_trade_tabs_dialog.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/trade_package.dart';
import '../../utils/team_logo_utils.dart';
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
  
  // Helper method to determine the color based on trade value
  Color _getOfferValueColor(TradePackage offer) {
    final valueRatio = offer.totalValueOffered / offer.targetPickValue;
    
    if (valueRatio >= 1.2) return Colors.green;      // Great value (>20% surplus)
    if (valueRatio >= 1.0) return Colors.blue;       // Fair value
    if (valueRatio >= 0.9) return Colors.orange;     // Slightly below value
    return Colors.red;                               // Poor value
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, size: 24),
          const SizedBox(width: 8),
          Text(
            'Trade Center: ${widget.userTeam}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero, // Remove default padding
      insetPadding: const EdgeInsets.all(12), // Reduced inset padding
      content: SizedBox(
        width: double.maxFinite,
        height: 580, // Give enough height but don't take too much
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
                  text: 'Trade Offers (${_getAllPendingOffers().length})',
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
                // Team name with logo
                Row(
                  children: [
                    // Team logo
                    TeamLogoUtils.buildNFLTeamLogo(
                      offer.teamOffering,
                      size: 32.0,
                    ),
                    const SizedBox(width: 12),
                    // Team name
                    Expanded(
                      child: Text(
                        'Offer from ${offer.teamOffering}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Visual trade flow with team logos
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trade flow visualization
                      Row(
                        children: [
                          // Team receiving
                          Expanded(
                            child: Column(
                              children: [
                                TeamLogoUtils.buildNFLTeamLogo(
                                  offer.teamReceiving,
                                  size: 36.0,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  offer.teamReceiving,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          // Exchange arrows
                          Column(
                            children: [
                              Icon(Icons.arrow_forward, color: Colors.green.shade700, size: 20),
                              const SizedBox(height: 4),
                              Icon(Icons.arrow_back, color: Colors.red.shade700, size: 20),
                            ],
                          ),
                          
                          // Team offering
                          Expanded(
                            child: Column(
                              children: [
                                TeamLogoUtils.buildNFLTeamLogo(
                                  offer.teamOffering,
                                  size: 36.0,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  offer.teamOffering,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Text description
                      Text(
                        offer.tradeDescription,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Value summary with improved visual indicators
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getOfferValueColor(offer).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getOfferValueColor(offer).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            offer.isGreatTrade ? Icons.thumb_up : (offer.isFairTrade ? Icons.check_circle : Icons.warning),
                            color: _getOfferValueColor(offer),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            offer.isGreatTrade ? 'Great Value' : (offer.isFairTrade ? 'Fair Trade' : 'Below Value'),
                            style: TextStyle(
                              color: _getOfferValueColor(offer),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.valueSummary,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Accept button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => widget.onAcceptOffer(offer),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Accept Offer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
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