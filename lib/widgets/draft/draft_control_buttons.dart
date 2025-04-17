import 'package:flutter/material.dart';

class DraftControlButtons extends StatelessWidget {
  final bool isDraftRunning;
  final bool hasTradeOffers;
  final int tradeOffersCount;
  final VoidCallback onToggleDraft;
  final VoidCallback onRestartDraft;
  final VoidCallback onRequestTrade;

  const DraftControlButtons({
    super.key,
    required this.isDraftRunning,
    required this.onToggleDraft,
    required this.onRestartDraft,
    required this.onRequestTrade,
    this.hasTradeOffers = false,
    this.tradeOffersCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Restart button with label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: FloatingActionButton(
                  onPressed: onRestartDraft,
                  tooltip: 'Undo/Restart',  // Changed from 'Restart Draft'
                  mini: true,
                  child: const Icon(Icons.settings_backup_restore),  // Changed from Icons.refresh
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Undo/Restart',  // Changed from 'Restart'
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // Start/Pause button with label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: FloatingActionButton(
                  onPressed: onToggleDraft,
                  tooltip: isDraftRunning ? 'Pause Draft' : 'Start Draft',
                  mini: true,
                  child: Icon(isDraftRunning ? Icons.pause : Icons.play_arrow),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isDraftRunning ? 'Pause' : 'Start',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // Trade button with label and numeric badge
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Badge(
                  isLabelVisible: hasTradeOffers,
                  label: Text(tradeOffersCount > 1 ? '$tradeOffersCount' : '!'),
                  child: FloatingActionButton(
                    onPressed: onRequestTrade,
                    tooltip: 'Trade Center',
                    mini: true,
                    child: const Icon(Icons.swap_horiz),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Trade',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}