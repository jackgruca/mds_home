import 'package:flutter/material.dart';

class DraftControlButtons extends StatelessWidget {
  final bool isDraftRunning;
  final VoidCallback onToggleDraft;
  final VoidCallback onRestartDraft;
  final VoidCallback onRequestTrade;

  const DraftControlButtons({
    super.key,
    required this.isDraftRunning,
    required this.onToggleDraft,
    required this.onRestartDraft,
    required this.onRequestTrade,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              onPressed: onRestartDraft,
              tooltip: 'Restart Draft',
              child: const Icon(Icons.refresh),
              mini: true,
            ),
          ),
          SizedBox(width: 24), // Reduced spacing to bring buttons closer together
          SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              onPressed: onToggleDraft,
              tooltip: isDraftRunning ? 'Pause Draft' : 'Start Draft',
              child: Icon(isDraftRunning ? Icons.pause : Icons.play_arrow),
              mini: true,
            ),
          ),
          SizedBox(width: 24), // Reduced spacing to bring buttons closer together
          SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              onPressed: onRequestTrade,
              tooltip: 'Request Trade',
              child: const Icon(Icons.swap_horiz),
              mini: true,
            ),
          ),
        ],
      ),
    );
  }
}
