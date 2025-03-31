// lib/widgets/trade/trade_dialog_wrapper.dart
import 'package:flutter/material.dart';
import '../../models/trade_package.dart';
import '../../models/trade_offer.dart';
import '../../services/enhanced_trade_manager.dart';
import 'enhanced_trade_dialog.dart';
import '../../services/draft_value_service.dart';
import '../../models/draft_pick.dart';
import '../../widgets/trade/trade_response_dialog.dart';
import 'user_trade_dialog.dart'; 

class TradeDialogWrapper extends StatelessWidget {
  final TradeOffer tradeOffer;
  final Function(TradePackage) onAccept;
  final VoidCallback onReject;
  final Function(TradePackage)? onCounter;
  final bool showAnalytics;
  final EnhancedTradeManager? tradeManager;

  const TradeDialogWrapper({
    super.key,
    required this.tradeOffer,
    required this.onAccept,
    required this.onReject,
    this.onCounter,
    this.showAnalytics = true,
    this.tradeManager,
  });

  @override
Widget build(BuildContext context) {
  // Check if the offer is empty or contains already handled picks
  if (tradeOffer.packages.isEmpty) {
    return AlertDialog(
      title: const Text('No Trade Offers'),
      content: const Text('There are no trade offers available for this pick.'),
      actions: [
        TextButton(
          onPressed: onReject,
          child: const Text('Close'),
        ),
      ],
    );
  }

  // Use the enhanced trade dialog with motivation
  return EnhancedTradeDialog(
    tradeOffer: tradeOffer,
    onAccept: (package) {
      // First accept the trade
      onAccept(package);
      
      // Then show a response dialog confirming the trade
      _showTradeResponseDialog(context, package, true);
    },
    onReject: () {
      // Generate a rejection reason
      final package = tradeOffer.packages.first;
      Map<String, dynamic>? rejectionDetails;
      
      // Try to get detailed rejection if trade manager available
      if (tradeManager != null) {
        rejectionDetails = tradeManager!.getRejectionDetails(package);
      }
      
      String rejectionReason = rejectionDetails != null ? 
                             rejectionDetails['reason'] : 
                             _generateRejectionReason(package);
      
      // Show rejection dialog first
      if (tradeOffer.isUserInvolved) {
        _showTradeResponseDialog(
          context, 
          package, 
          false, 
          rejectionReason,
          rejectionDetails?['improvements']
        );
      } else {
        // Just close the dialog
        onReject();
      }
    },
    // Pass the context along with the package to the counter handler
    onCounter: onCounter != null ? (package) => onCounter!(package) : null,
    showAnalytics: showAnalytics,
  );
}
  
  // Show a response dialog after trade is accepted or rejected
  void _showTradeResponseDialog(
    BuildContext context, 
    TradePackage tradePackage, 
    bool wasAccepted,
    [String? rejectionReason,
    Map<String, dynamic>? improvements]
  ) {
    // First dismiss the current trade dialog
    Navigator.of(context).pop();
    
    // Then show the response dialog
    showDialog(
      context: context,
      builder: (context) => TradeResponseDialog(
        tradePackage: tradePackage,
        wasAccepted: wasAccepted,
        rejectionReason: rejectionReason,
        improvements: improvements,
        onClose: onReject,
      ),
    );
  }
  
  // Generate a realistic rejection reason
  String _generateRejectionReason(TradePackage package) {
    final valueRatio = package.totalValueOffered / package.targetPickValue;
    
    if (valueRatio < 0.85) {
      final options = [
        "The offer doesn't provide sufficient draft value.",
        "We need more compensation to move down from this position.",
        "That offer falls short of our valuation of this pick.",
        "We're looking for significantly more value to make this move.",
      ];
      return options[DateTime.now().microsecond % options.length];
    } else if (valueRatio < 0.95) {
      final options = [
        "We're close, but we need a bit more value to make this deal work.",
        "The offer is slightly below what we're looking for.",
        "We'd need a little more compensation to justify moving back.",
        "Interesting offer, but not quite enough value for us.",
      ];
      return options[DateTime.now().microsecond % options.length];
    } else {
      final options = [
        "We have our eye on a specific player at this position.",
        "We believe we can address a key roster need with this selection.",
        "Our scouts are high on a player that should be available here.",
        "We have immediate needs that we're planning to address with this pick.",
      ];
      return options[DateTime.now().microsecond % options.length];
    }
  }
}