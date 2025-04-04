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
  final bool isRecommendation;
  final Map<String, String>? targetPlayerInfo;

  const UserTradeTabsDialog({
    super.key,
    required this.userTeam,
    required this.userPicks,
    required this.targetPicks,
    required this.pendingOffers,
    required this.onAcceptOffer,
    required this.onPropose,
    required this.onCancel,
    this.isRecommendation = false,
    this.targetPlayerInfo,
  });

  @override
  _UserTradeTabsDialogState createState() => _UserTradeTabsDialogState();
}

class _UserTradeTabsDialogState extends State<UserTradeTabsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isCounterMode = false;
  String? counter_userTeam;
  String? counter_targetTeam;
  List<DraftPick>? counter_userPicks;
  List<DraftPick>? counter_targetPicks;
  List<DraftPick>? counter_initialSelectedUserPicks;
  List<DraftPick>? counter_initialSelectedTargetPicks;
  List<int>? counter_initialUserFutureRounds;
  List<int>? counter_initialTargetFutureRounds;
  TradePackage? counter_originalOffer;
  
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
  // Modify tabs to show "Trade Suggestions" instead of "Trade Offers" when it's a recommendation
  return AlertDialog(
    title: null,
    contentPadding: EdgeInsets.zero,
    insetPadding: const EdgeInsets.all(12),
    content: SizedBox(
      width: double.maxFinite,
      height: 580,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(vertical: 4.0),
            labelColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.black,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white70 
              : Colors.grey.shade700,
            indicatorWeight: 3,
            indicatorColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.blue.shade300 
              : Colors.blue.shade700,
            tabs: [
              Tab(
                icon: Badge(
                  isLabelVisible: _getAllPendingOffers().isNotEmpty,
                  label: Text(_getAllPendingOffers().length.toString()),
                  child: const Icon(Icons.call_received, size: 16),
                ),
                text: widget.isRecommendation 
                  ? 'Trade Suggestions'  // New title for recommendations
                  : 'Trade Offers (${_getAllPendingOffers().length})',
                iconMargin: const EdgeInsets.only(bottom: 2.0),
              ),
              Tab(
                icon: Icon(isCounterMode ? Icons.reply : Icons.call_made, size: 16),
                text: isCounterMode ? 'Counter Offer' : 'Create Trade',
                iconMargin: const EdgeInsets.only(bottom: 2.0),
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
      
      // Create trade tab - changes based on counter mode
      isCounterMode 
        ? UserTradeProposalDialog(
            userTeam: counter_userTeam!,
            userPicks: counter_userPicks!,
            targetPicks: counter_targetPicks!,
            initialSelectedUserPicks: counter_initialSelectedUserPicks,
            initialSelectedTargetPicks: counter_initialSelectedTargetPicks,
            initialSelectedUserFutureRounds: counter_initialUserFutureRounds,
            initialSelectedTargetFutureRounds: counter_initialTargetFutureRounds,
            onPropose: (counterPackage) {
              // Very important - ensure the original offer is passed along
              // to enable proper detection of replicated offers
              debugPrint("Sending counter offer with original offer metadata");
              debugPrint("Original offer: ${counter_originalOffer?.teamOffering} -> ${counter_originalOffer?.teamReceiving}");
              debugPrint("Counter offer: ${counterPackage.teamOffering} -> ${counterPackage.teamReceiving}");
              
              // Handle the counter package
              widget.onPropose(counterPackage);
              
              // Reset counter mode
              setState(() {
                isCounterMode = false;
                _tabController.animateTo(0); // Return to offers tab
              });
            },
            onCancel: () {
              // Reset counter mode and go back to offers tab
              setState(() {
                isCounterMode = false;
                _tabController.animateTo(0); 
              });
            },
            hasLeverage: true, // Flag that this is a counter offer
            isEmbedded: true,
          )
        : UserTradeProposalDialog(
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
    itemCount: offers.length + (widget.isRecommendation && widget.targetPlayerInfo != null ? 1 : 0),
    itemBuilder: (context, index) {
      // Show recommendation header if appropriate
      if (widget.isRecommendation && widget.targetPlayerInfo != null && index == 0) {
        return _buildRecommendationHeader();
      }
      
      // Adjust index to account for possible header
      final adjustedIndex = widget.isRecommendation && widget.targetPlayerInfo != null ? index - 1 : index;
      if (adjustedIndex >= offers.length) return const SizedBox.shrink();
      
      final offer = offers[adjustedIndex];
      final valueRatio = offer.totalValueOffered / offer.targetPickValue;
      final valueScore = (valueRatio * 100).toInt();
      
      // Extract the picks offered and picks received
      final picksGained = _getPicksSummary(offer.targetPick, offer.additionalTargetPicks);
      final picksLost = _getPicksOfferedSummary(offer.picksOffered, offer.includesFuturePick ? offer.futurePickDescription : null);
      
      // Create the card with modified buttons for recommendations
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
                        widget.isRecommendation ? widget.userTeam : offer.teamOffering,
                        size: 32.0,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isRecommendation ? widget.userTeam : offer.teamOffering,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isRecommendation 
                          ? "Sends: $picksLost" 
                          : "Gets: $picksGained",
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
                
                // Team receiving logo and what they get
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TeamLogoUtils.buildNFLTeamLogo(
                        widget.isRecommendation ? offer.teamReceiving : offer.teamReceiving,
                        size: 32.0,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isRecommendation ? offer.teamReceiving : offer.teamReceiving,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isRecommendation 
                          ? "Gets: $picksGained" 
                          : "Gets: $picksLost",
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
                
                // Action buttons - changed for recommendations
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Different set of buttons for recommendations
                    if (widget.isRecommendation) ...[
                      // Send trade button
                      SizedBox(
                        height: 30,
                        width: 30,
                        child: IconButton(
                          onPressed: () => widget.onPropose(offer),
                          icon: const Icon(Icons.send, size: 20),
                          color: Colors.green,
                          tooltip: 'Send Offer',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      
                      // Edit/Counter button
                      SizedBox(
                        height: 30,
                        width: 30,
                        child: IconButton(
                          onPressed: () {
                            // Setup counter but with correct teams
                            _setupCounterOffer(offer, keepTeamsSame: widget.isRecommendation);
                          },
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.blue,
                          tooltip: widget.isRecommendation ? 'Edit Offer' : 'Counter Offer',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ] else ...[
                      // Original buttons for regular offers
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
                            _setupCounterOffer(offer);
                          },
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.blue,
                          tooltip: 'Counter Offer',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      
                      // Accept button
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
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  );
}

Widget _buildRecommendationHeader() {
  if (widget.targetPlayerInfo == null) return const SizedBox.shrink();
  
  return Card(
    margin: const EdgeInsets.all(8.0),
    color: Colors.blue.shade50,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text(
                'Trade Recommendation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Target Player: ${widget.targetPlayerInfo!['name']} (${widget.targetPlayerInfo!['position']})'),
          const SizedBox(height: 4),
          Text(widget.targetPlayerInfo!['reason'] ?? ''),
          const SizedBox(height: 8),
          const Text(
            'Consider the trade offered below, or create your own proposal in the "Create Trade" tab.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    ),
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
  
  void _setupCounterOffer(TradePackage offer, {bool keepTeamsSame = false}) {
  debugPrint("Setting up counter offer for ${offer.teamOffering} -> ${offer.teamReceiving}");
  
  // Determine which teams to use based on recommendation status
  String offeringTeam, receivingTeam;
  
  if (keepTeamsSame) {
    // For recommendation edits, keep teams the same
    offeringTeam = offer.teamOffering;
    receivingTeam = offer.teamReceiving;
  } else {
    // For regular counters, flip the teams
    offeringTeam = offer.teamReceiving;
    receivingTeam = offer.teamOffering;
  }
  
  // Get all the offering team's picks
  List<DraftPick> allOfferingTeamPicks = widget.targetPicks
      .where((pick) => pick.teamName == offeringTeam)
      .toList();
  
  if (allOfferingTeamPicks.isEmpty && offeringTeam == widget.userTeam) {
    // If offering team is user's team, use user picks
    allOfferingTeamPicks = widget.userPicks;
  }
  
  // Get all receiving team's picks
  List<DraftPick> allReceivingTeamPicks = widget.targetPicks
      .where((pick) => pick.teamName == receivingTeam)
      .toList();
  
  if (allReceivingTeamPicks.isEmpty && receivingTeam == widget.userTeam) {
    // If receiving team is user's team, use user picks
    allReceivingTeamPicks = widget.userPicks;
  }
  
  // Define initial selections correctly
  List<DraftPick> selectedOfferingTeamPicks = [];
  List<DraftPick> selectedReceivingTeamPicks = [];
  
  // For recommendations, pre-select the correct picks
  if (keepTeamsSame) {
    // Find the matching offered picks
    for (var availablePick in allOfferingTeamPicks) {
      for (var offeredPick in offer.picksOffered) {
        if (availablePick.pickNumber == offeredPick.pickNumber) {
          selectedOfferingTeamPicks.add(availablePick);
        }
      }
    }
    
    // Find the matching target pick
    for (var availablePick in allReceivingTeamPicks) {
      if (availablePick.pickNumber == offer.targetPick.pickNumber) {
        selectedReceivingTeamPicks.add(availablePick);
      }
      
      // Add any additional target picks
      for (var additionalPick in offer.additionalTargetPicks) {
        if (availablePick.pickNumber == additionalPick.pickNumber) {
          selectedReceivingTeamPicks.add(availablePick);
        }
      }
    }
  } else {
    // For counter offers, flip the selections
    // Find the offering team's available picks matching the original target pick
    for (var availablePick in allOfferingTeamPicks) {
      if (availablePick.pickNumber == offer.targetPick.pickNumber) {
        selectedOfferingTeamPicks.add(availablePick);
      }
      
      // Add any additional target picks
      for (var additionalPick in offer.additionalTargetPicks) {
        if (availablePick.pickNumber == additionalPick.pickNumber) {
          selectedOfferingTeamPicks.add(availablePick);
        }
      }
    }
    
    // Find the receiving team's available picks matching the original offered picks
    for (var availablePick in allReceivingTeamPicks) {
      for (var offeredPick in offer.picksOffered) {
        if (availablePick.pickNumber == offeredPick.pickNumber) {
          selectedReceivingTeamPicks.add(availablePick);
        }
      }
    }
  }
  
  // Setup future picks if needed
List<int> initialOfferingTeamFutureRounds = [];
List<int> initialReceivingTeamFutureRounds = [];

if (offer.includesFuturePick && offer.futurePickDescription != null) {
  String desc = offer.futurePickDescription!.toLowerCase();
  
  // Determine which future list to populate based on keepTeamsSame
  List<int> targetFutureList = keepTeamsSame 
      ? initialOfferingTeamFutureRounds 
      : initialReceivingTeamFutureRounds;
  
  if (desc.contains("1st")) targetFutureList.add(1);
  if (desc.contains("2nd")) targetFutureList.add(2);
  if (desc.contains("3rd")) targetFutureList.add(3);
  if (desc.contains("4th")) targetFutureList.add(4);
  if (desc.contains("5th")) targetFutureList.add(5);
  if (desc.contains("6th")) targetFutureList.add(6);
  if (desc.contains("7th")) targetFutureList.add(7);
}
  
  // Update state for counter mode
  setState(() {
    isCounterMode = true;
    counter_userTeam = offeringTeam;
    counter_targetTeam = receivingTeam;
    counter_userPicks = allOfferingTeamPicks;
    counter_targetPicks = allReceivingTeamPicks;
    counter_initialSelectedUserPicks = selectedOfferingTeamPicks;
    counter_initialSelectedTargetPicks = selectedReceivingTeamPicks;
    counter_initialUserFutureRounds = initialOfferingTeamFutureRounds;
    counter_initialTargetFutureRounds = initialReceivingTeamFutureRounds;
    counter_originalOffer = offer;
  });
  
  // Switch to the counter tab
  _tabController.animateTo(1);
}
}