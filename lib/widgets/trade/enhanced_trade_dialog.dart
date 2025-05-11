// Updated EnhancedTradeDialog with team logos, reject+counter buttons
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/trade_package.dart';
import '../../models/trade_offer.dart';
import '../../services/draft_value_service.dart';
import '../../utils/team_logo_utils.dart';

class EnhancedTradeDialog extends StatefulWidget {
  final TradeOffer tradeOffer;
  final Function(TradePackage) onAccept;
  final VoidCallback onReject;
  final Function(TradePackage)? onCounter; // New callback for counter offer
  final bool showAnalytics;

  const EnhancedTradeDialog({
    super.key,
    required this.tradeOffer,
    required this.onAccept,
    required this.onReject,
    this.onCounter, // New optional parameter
    this.showAnalytics = true,
  });

  @override
  _EnhancedTradeDialogState createState() => _EnhancedTradeDialogState();
}

class _EnhancedTradeDialogState extends State<EnhancedTradeDialog> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  bool _showDetails = false;
  final ValueNotifier<bool> _animationComplete = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add haptic feedback when dialog opens
    HapticFeedback.mediumImpact();
    
    // Start animation sequence
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _showDetails = true;
      });
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _animationComplete.value = true;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationComplete.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 8.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: MediaQuery.of(context).size.width * 0.9,
        height: _showDetails 
          ? MediaQuery.of(context).size.height * 0.7 
          : MediaQuery.of(context).size.height * 0.1,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.swap_horiz, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Trade Offers for Pick #${widget.tradeOffer.pickNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onReject,
                ),
              ],
            ),
            
            if (_showDetails) ...[
              const Divider(),
              // Team selector tabs with animation and logos
              AnimatedOpacity(
                opacity: _showDetails ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: _buildTeamSelector(),
              ),
              
              // Tab controller for switching between details and analytics
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Trade Details'),
                  Tab(text: 'Value Analysis'),
                ],
              ),
              
              // Trade details with animation
              Expanded(
                child: AnimatedOpacity(
                  opacity: _showDetails ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTradeDetails(),
                      _buildValueAnalysis(),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              AnimatedOpacity(
                opacity: _showDetails ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Reject button
                      OutlinedButton.icon(
                        onPressed: widget.onReject,
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Counter offer button (if enabled)
                      if (widget.onCounter != null)
                        OutlinedButton(
                          onPressed: widget.onCounter != null 
                            ? () => widget.onCounter!(widget.tradeOffer.packages[_selectedIndex])
                            : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                          child: const Text('Counter'),
                        ),
                      const SizedBox(width: 8),
                      
                      // Accept button
                      ValueListenableBuilder<bool>(
                        valueListenable: _animationComplete,
                        builder: (context, isComplete, child) {
                          return ElevatedButton.icon(
                            onPressed: isComplete 
                              ? () {
                                  // Add haptic feedback
                                  HapticFeedback.mediumImpact();
                                  widget.onAccept(widget.tradeOffer.packages[_selectedIndex]);
                                }
                              : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Accept Trade'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getValueColor(),
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelector() {
    final offeringTeams = widget.tradeOffer.offeringTeams;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 60, // Increased height to accommodate logo
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: offeringTeams.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedIndex == index;
            final teamName = offeringTeams[index];
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected 
                    ? _getValueColor().withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: isSelected ? _getValueColor() : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        // Team logo
                        TeamLogoUtils.buildNFLTeamLogo(
                          teamName,
                          size: 28.0,
                        ),
                        const SizedBox(width: 8),
                        // Team name
                        Text(
                          teamName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? _getValueColor() : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTradeDetails() {
  final package = widget.tradeOffer.packages[_selectedIndex];
  
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
          
          // Visual trade summary with team logos
          _buildVisualTradeSummary(package),
          
          const SizedBox(height: 16),
          
          // Trade value
          Row(
            children: [
              const Text(
                'Trade Value:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getValueColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getValueColor()),
                ),
                child: Text(
                  package.isGreatTrade 
                    ? 'Great Value' 
                    : (package.isFairTrade ? 'Fair Trade' : 'Below Value'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getValueColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(package.valueSummary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Value indicator
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                height: 12,
                width: MediaQuery.of(context).size.width * 0.8 * 
                  (package.totalValueOffered / package.targetPickValue)
                    .clamp(0.0, 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _getValueColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${((package.totalValueOffered / package.targetPickValue) * 100).toStringAsFixed(0)}% of target value',
            style: TextStyle(
              color: _getValueColor(),
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
          
          // Updated pick table
          _buildEnhancedPicksTable(package),
          
          // Future picks section if applicable
          if (package.includesFuturePick || 
              (package.targetReceivedFuturePicks != null && 
               package.targetReceivedFuturePicks!.isNotEmpty)) ...[
            const SizedBox(height: 16),
            const Text(
              'Future Picks:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (package.futurePickDescription != null && package.futurePickDescription!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Text(
                      '${package.teamOffering} sends: ${package.futurePickDescription}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            if (package.targetReceivedFuturePicks != null && 
                package.targetReceivedFuturePicks!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.teal.shade800),
                    const SizedBox(width: 8),
                    Text(
                      '${package.teamReceiving} sends: ${package.targetReceivedFuturePicks!.join(", ")}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

  // New method to build visual trade summary with team logos
  Widget _buildVisualTradeSummary(TradePackage package) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Team offering
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TeamLogoUtils.buildNFLTeamLogo(
                  package.teamOffering,
                  size: 40.0,
                ),
                const SizedBox(height: 4),
                Text(
                  package.teamOffering,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Trade flow arrows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward, color: Colors.green.shade700),
                const SizedBox(height: 4),
                Icon(Icons.arrow_back, color: Colors.red.shade700),
              ],
            ),
          ),
          
          // Team receiving
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TeamLogoUtils.buildNFLTeamLogo(
                  package.teamReceiving,
                  size: 40.0,
                ),
                const SizedBox(height: 4),
                Text(
                  package.teamReceiving,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueAnalysis() {
    final package = widget.tradeOffer.packages[_selectedIndex];
    
    // Calculate some analytics for the trade
    final valueRatio = package.totalValueOffered / package.targetPickValue;
    final fairnessPercentage = (valueRatio * 100).clamp(0.0, 200.0);
    final bool isGoodDeal = valueRatio > 1.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value gauge
          Center(
            child: Column(
              children: [
                Text(
                  isGoodDeal ? 'Good Deal' : 'Poor Deal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getValueColor(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: fairnessPercentage / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(_getValueColor()),
                      ),
                      Text(
                        '${fairnessPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Pro/Con analysis
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trade Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  
                  // Pros
                  const Text(
                    'Pros:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  ...(_getProPoints(package).map((point) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(point)),
                      ],
                    ),
                  ))),
                  
                  const SizedBox(height: 16),
                  
                  // Cons
                  const Text(
                    'Cons:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  ...(_getConPoints(package).map((point) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(point)),
                      ],
                    ),
                  ))),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recommendation
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: _getValueColor().withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isGoodDeal ? Icons.thumb_up : Icons.thumb_down,
                        color: _getValueColor(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommendation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getValueColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_getRecommendation(package)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPicksTable(TradePackage package) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Header row
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text('Pick', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 8),
                  Expanded(child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 8),
                  SizedBox(width: 60, child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const Divider(),
            
            // Target pick
            _buildPickRow(
              pickNumber: package.targetPick.pickNumber,
              teamName: package.teamReceiving,
              value: DraftValueService.getValueForPick(package.targetPick.pickNumber),
              isHighlighted: true,
              direction: 'Receive',
              isCurrentYear: true,
            ),
            
            // Additional target picks
            ...package.additionalTargetPicks.map((pick) => _buildPickRow(
              pickNumber: pick.pickNumber,
              teamName: package.teamReceiving,
              value: DraftValueService.getValueForPick(pick.pickNumber),
              isHighlighted: true,
              direction: 'Receive',
              isCurrentYear: true,
            )),
            
            // Target team's future picks
            if (package.targetReceivedFuturePicks != null && package.targetReceivedFuturePicks!.isNotEmpty) 
              ...package.targetReceivedFuturePicks!.map((desc) => _buildFuturePickRow(
                description: desc,
                teamName: package.teamReceiving,
                value: 0, // You would need to calculate this
                isHighlighted: true,
                direction: 'Receive',
              )),
            
            if (package.picksOffered.isNotEmpty || package.includesFuturePick)
              const Divider(),
            
            // Offered picks
            ...package.picksOffered.map((pick) => _buildPickRow(
              pickNumber: pick.pickNumber,
              teamName: package.teamOffering,
              value: DraftValueService.getValueForPick(pick.pickNumber),
              isHighlighted: false,
              direction: 'Give',
              isCurrentYear: true,
            )),
            
            // Future pick
            if (package.includesFuturePick)
              _buildFuturePickRow(
                description: package.futurePickDescription ?? 'Future Pick',
                teamName: package.teamOffering,
                value: package.futurePickValue ?? 0,
                isHighlighted: false,
                direction: 'Give',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickRow({
    required int pickNumber,
    required String teamName,
    required double value,
    required bool isHighlighted,
    required String direction,
    required bool isCurrentYear,
  }) {
    final bgColor = isHighlighted 
        ? Colors.green.withOpacity(0.1)
        : Colors.orange.withOpacity(0.1);
    
    final iconData = direction == 'Receive' 
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    
    final iconColor = direction == 'Receive'
        ? Colors.green
        : Colors.orange;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Icon(iconData, size: 14, color: iconColor),
                const SizedBox(width: 2),
                Text('#$pickNumber'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                // Add team logo
                SizedBox(
                  width: 24,
                  height: 24,
                  child: TeamLogoUtils.buildNFLTeamLogo(
                    teamName,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 6),
                // Team name
                Expanded(
                  child: Text(
                    teamName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              DraftValueService.getValueDescription(value),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturePickRow({
    required String description,
    required String teamName,
    required double value,
    required bool isHighlighted,
    required String direction,
  }) {
    final bgColor = isHighlighted 
        ? Colors.green.withOpacity(0.1)
        : Colors.orange.withOpacity(0.1);
    
    final iconData = direction == 'Receive' 
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    
    final iconColor = direction == 'Receive'
        ? Colors.green
        : Colors.orange;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.amber.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Icon(iconData, size: 14, color: iconColor),
                const SizedBox(width: 2),
                const Icon(Icons.calendar_today, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Add team logo
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: TeamLogoUtils.buildNFLTeamLogo(
                        teamName,
                        size: 16.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Team name
                    Expanded(
                      child: Text(
                        teamName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              DraftValueService.getValueDescription(value),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getValueColor() {
    final package = widget.tradeOffer.packages[_selectedIndex];
    final valueRatio = package.totalValueOffered / package.targetPickValue;
    
    if (valueRatio >= 1.2) return Colors.green;
    if (valueRatio >= 1.0) return Colors.blue;
    if (valueRatio >= 0.9) return Colors.orange;
    return Colors.red;
  }

  List<String> _getProPoints(TradePackage package) {
    final List<String> points = [];
    final valueRatio = package.totalValueOffered / package.targetPickValue;
    
    if (valueRatio > 1.0) {
      points.add('You receive more draft value than you give up.');
    }
    
    if (package.picksOffered.length > 1) {
      points.add('You receive a higher pick in exchange for multiple lower picks.');
    }
    
    if (package.targetPick.pickNumber <= 32) {
      points.add('You gain a valuable pick in the first round.');
    }
    
    if (valueRatio > 1.2) {
      points.add('This trade offers exceptional value (over 20% surplus).');
    }
    
    if (package.includesFuturePick) {
      points.add('The trade includes future draft capital, spreading out your assets.');
    }
    
    // Add at least one pro point if none are generated
    if (points.isEmpty) {
      points.add('You receive immediate draft capital for your team.');
    }
    
    return points;
  }

  List<String> _getConPoints(TradePackage package) {
    final List<String> points = [];
    final valueRatio = package.totalValueOffered / package.targetPickValue;
    
    if (valueRatio < 1.0) {
      points.add('You give up more draft value than you receive.');
    }
    
    if (package.picksOffered.length < package.additionalTargetPicks.length + 1) {
      points.add('You give up a higher pick for multiple lower picks.');
    }
    
    if (package.picksOffered.isNotEmpty && package.picksOffered[0].pickNumber <= 10) {
      points.add('You\'re trading away a premium top-10 pick.');
    }
    
    if (valueRatio < 0.9) {
      points.add('This trade offers poor value (over 10% deficit).');
    }
    
    if (package.includesFuturePick) {
      points.add('You\'re giving up future draft capital that could be valuable later.');
    }
    
    // Add at least one con point if none are generated
    if (points.isEmpty) {
      points.add('You\'re committing draft resources that could be used differently.');
    }
    
    return points;
  }

  String _getRecommendation(TradePackage package) {
    final valueRatio = package.totalValueOffered / package.targetPickValue;
    
    if (valueRatio >= 1.2) {
      return 'Strongly recommend accepting this trade. You\'re getting excellent value that significantly exceeds the standard draft value chart.';
    } else if (valueRatio >= 1.05) {
      return 'Recommend accepting this trade. The value is in your favor according to the standard draft value chart.';
    } else if (valueRatio >= 0.95) {
      return 'This trade is fairly balanced. Consider your team needs and whether the pick positions help your draft strategy.';
    } else if (valueRatio >= 0.85) {
      return 'Consider carefully before accepting. This trade offers slightly less value than the standard chart suggests is fair.';
    } else {
      return 'Not recommended. This trade offers significantly less value than what draft analytics would suggest is fair compensation.';
    }
  }
}