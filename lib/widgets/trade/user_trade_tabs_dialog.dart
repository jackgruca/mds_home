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
    // Determine initial tab index based on pending offers
    final initialTabIndex = _getAllPendingOffers().isNotEmpty ? 0 : 1;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialTabIndex);
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
      title: null, // Remove title completely
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
                labelColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black, // Selected tab text color
                unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.grey.shade700, // Unselected tab text color
                indicatorWeight: 3, // Make the indicator more visible
                indicatorColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.blue.shade300 
                  : Colors.blue.shade700, // Indicator color
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
      final valueRatio = offer.totalValueOffered / offer.targetPickValue;
      final valueScore = (valueRatio * 100).toInt();
      
      // Extract the picks offered and picks received
      final picksGained = _getPicksSummary(offer.targetPick, offer.additionalTargetPicks);
      final picksLost = _getPicksOfferedSummary(offer.picksOffered, offer.includesFuturePick ? offer.futurePickDescription : null);
      
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _getOfferValueColor(offer).withOpacity(0.5),
            width: 1.0,
          ),
        ),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showTradeDetails(context, offer),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                // Team offering logo and what they get
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TeamLogoUtils.buildNFLTeamLogo(
                        offer.teamOffering,
                        size: 32.0,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.teamOffering,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Gets: $picksGained",
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Swap arrows
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    Icons.swap_horiz,
                    size: 20,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                  ),
                ),
                
                // Your team logo and what you get
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TeamLogoUtils.buildNFLTeamLogo(
                        offer.teamReceiving,
                        size: 32.0,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.teamReceiving,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Gets: $picksLost",
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Value score chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOfferValueColor(offer).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getOfferValueColor(offer),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    '$valueScore%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _getOfferValueColor(offer),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Action buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reject button
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: IconButton(
                        onPressed: () {
                          // Remove this offer from the pending offers
                          if (widget.pendingOffers.containsKey(offer.targetPick.pickNumber)) {
                            setState(() {
                              widget.pendingOffers[offer.targetPick.pickNumber]!.removeWhere(
                                (o) => o.teamOffering == offer.teamOffering && o.targetPick.pickNumber == offer.targetPick.pickNumber
                              );
                              
                              // If no more offers for this pick, remove the entry
                              if (widget.pendingOffers[offer.targetPick.pickNumber]!.isEmpty) {
                                widget.pendingOffers.remove(offer.targetPick.pickNumber);
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.cancel, size: 20),
                        color: Colors.red,
                        tooltip: 'Reject Offer',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    
                    // Counter button
SizedBox(
  height: 30,
  width: 30,
  child: IconButton(
    onPressed: () {
      Navigator.of(context).pop();
      
      // Get all available picks from the offering team
      List<DraftPick> allOfferingTeamPicks = widget.targetPicks.where(
        (pick) => pick.teamName == offer.teamOffering
      ).toList();
      
      // If no picks found, fall back to the picks in the offer
      if (allOfferingTeamPicks.isEmpty) {
        allOfferingTeamPicks = offer.picksOffered;
      }
      
      // Get all available user team picks
      List<DraftPick> allUserTeamPicks = widget.userPicks;
      
      // Create lists to track future picks
      List<int> initialUserFutureRounds = [];
      List<int> initialTargetFutureRounds = [];
      
      // Check for future picks in the original offer
      if (offer.includesFuturePick && offer.futurePickDescription != null) {
        // Parse future pick description to extract rounds
        String desc = offer.futurePickDescription!;
        if (desc.contains("1st")) initialTargetFutureRounds.add(1);
        if (desc.contains("2nd")) initialTargetFutureRounds.add(2);
        if (desc.contains("3rd")) initialTargetFutureRounds.add(3);
        if (desc.contains("4th")) initialTargetFutureRounds.add(4);
        if (desc.contains("5th")) initialTargetFutureRounds.add(5);
        if (desc.contains("6th")) initialTargetFutureRounds.add(6);
        if (desc.contains("7th")) initialTargetFutureRounds.add(7);
      }
      
      // Check for future picks received by target
      if (offer.targetReceivedFuturePicks != null && offer.targetReceivedFuturePicks!.isNotEmpty) {
        for (String desc in offer.targetReceivedFuturePicks!) {
          if (desc.contains("1st")) initialUserFutureRounds.add(1);
          if (desc.contains("2nd")) initialUserFutureRounds.add(2);
          if (desc.contains("3rd")) initialUserFutureRounds.add(3);
          if (desc.contains("4th")) initialUserFutureRounds.add(4);
          if (desc.contains("5th")) initialUserFutureRounds.add(5);
          if (desc.contains("6th")) initialUserFutureRounds.add(6);
          if (desc.contains("7th")) initialUserFutureRounds.add(7);
        }
      }
      
      showDialog(
        context: context,
        builder: (ctx) => UserTradeProposalDialog(
          userTeam: offer.teamReceiving,
          userPicks: allUserTeamPicks,
          targetPicks: allOfferingTeamPicks,
          initialSelectedUserPicks: [offer.targetPick, ...offer.additionalTargetPicks],
          initialSelectedTargetPicks: offer.picksOffered,
          initialSelectedUserFutureRounds: initialUserFutureRounds,
          initialSelectedTargetFutureRounds: initialTargetFutureRounds,
          hasLeverage: true,
          onPropose: (counterPackage) {
            debugPrint("Counter offer proposed: ${counterPackage.tradeDescription}"); // Debug print
            Navigator.of(ctx).pop(); // Close the dialog
            
            // Call the parent onPropose callback to process the counter offer
            widget.onPropose(counterPackage);
          },
          onCancel: () => Navigator.of(ctx).pop(),
          onBack: () {
            // Don't close the dialog, just go back
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => UserTradeTabsDialog(
                userTeam: widget.userTeam,
                userPicks: widget.userPicks,
                targetPicks: widget.targetPicks,
                pendingOffers: widget.pendingOffers,
                onAcceptOffer: widget.onAcceptOffer,
                onPropose: widget.onPropose,
                onCancel: widget.onCancel,
              ),
            ).then((_) {
              // After the new dialog is closed, close the original dialog
              Navigator.of(ctx).pop();
            });
          },
        ),
      );
    },
    icon: const Icon(Icons.edit, size: 20),
    color: Colors.blue,
    tooltip: 'Counter Offer',
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
  ),
),
                    
                    // Accept button (original)
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: IconButton(
                        onPressed: () => widget.onAcceptOffer(offer),
                        icon: const Icon(Icons.check_circle, size: 20),
                        color: Colors.green,
                        tooltip: 'Accept Offer',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
  
  // Helper method to get a simple summary of picks gained
  String _getPicksSummary(DraftPick targetPick, List<DraftPick> additionalPicks) {
    String result = "#${targetPick.pickNumber}";
    
    if (additionalPicks.isNotEmpty) {
      final additionalCount = additionalPicks.length;
      result += " +$additionalCount more";
    }
    
    return result;
  }
  
  // Helper method to get a simple summary of picks offered
  String _getPicksOfferedSummary(List<DraftPick> picksOffered, String? futureDesc) {
    if (picksOffered.isEmpty && (futureDesc == null || futureDesc.isEmpty)) {
      return "None";
    }
    
    final mainPicks = picksOffered.map((p) => "#${p.pickNumber}").join(", ");
    
    if (futureDesc != null && futureDesc.isNotEmpty) {
      if (mainPicks.isNotEmpty) {
        return "$mainPicks + Future";
      } else {
        return "Future pick(s)";
      }
    }
    
    return mainPicks;
  }
  
  // Show detailed trade info in a bottom sheet
  void _showTradeDetails(BuildContext context, TradePackage offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trade header with team names
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TeamLogoUtils.buildNFLTeamLogo(
                      offer.teamOffering,
                      size: 40.0,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      offer.teamOffering,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(Icons.swap_horiz),
                    ),
                    Text(
                      offer.teamReceiving,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TeamLogoUtils.buildNFLTeamLogo(
                      offer.teamReceiving,
                      size: 40.0,
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Trade description
                const Text(
                  'Trade Details:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.tradeDescription,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // Value analysis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getOfferValueColor(offer).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getOfferValueColor(offer).withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            offer.isGreatTrade ? Icons.thumb_up : (offer.isFairTrade ? Icons.check_circle : Icons.warning),
                            color: _getOfferValueColor(offer),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            offer.isGreatTrade ? 'Great Value' : (offer.isFairTrade ? 'Fair Trade' : 'Below Value'),
                            style: TextStyle(
                              color: _getOfferValueColor(offer),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getOfferValueColor(offer)),
                            ),
                            child: Text(
                              '${((offer.totalValueOffered / offer.targetPickValue) * 100).toInt()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getOfferValueColor(offer),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.valueSummary,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      widget.onAcceptOffer(offer);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept Trade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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