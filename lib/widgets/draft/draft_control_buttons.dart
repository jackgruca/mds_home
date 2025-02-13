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
            // When using multiple floating action buttons, you want to give them a name (heroTag) to avoid conflicts
            child: FloatingActionButton(
              heroTag: 'restartDraft', // Added Hero Tags here @Gruca
              onPressed: onRestartDraft,
              tooltip: 'Restart Draft',
              mini: true,
              child: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(
              width: 24), // Reduced spacing to bring buttons closer together
          SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              heroTag: 'toggleDraft', // Added Hero Tags here @Gruca
              onPressed: onToggleDraft,
              tooltip: isDraftRunning ? 'Pause Draft' : 'Start Draft',
              mini: true,
              child: Icon(isDraftRunning ? Icons.pause : Icons.play_arrow),
            ),
          ),
          const SizedBox(
              width: 24), // Reduced spacing to bring buttons closer together
          SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              heroTag: 'requestTrade', // Added Hero Tags here @Gruca
              onPressed: onRequestTrade,
              tooltip: 'Request Trade',
              mini: true,
              child: const Icon(Icons.swap_horiz),
            ),
          ),
        ],
      ),
    );
  }
}
