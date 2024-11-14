import 'package:flutter/material.dart';

class DraftControlButtons extends StatelessWidget {
  final bool isDraftRunning;
  final VoidCallback onToggleDraft;
  final VoidCallback onRestartDraft;
  final VoidCallback onRequestTrade;

  DraftControlButtons({
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            onPressed: onToggleDraft,
            tooltip: isDraftRunning ? 'Pause Draft' : 'Start Draft',
            child: Icon(isDraftRunning ? Icons.pause : Icons.play_arrow),
          ),
          FloatingActionButton(
            onPressed: onRestartDraft,
            tooltip: 'Restart Draft',
            child: Icon(Icons.refresh),
          ),
          FloatingActionButton(
            onPressed: onRequestTrade,
            tooltip: 'Request Trade',
            child: Icon(Icons.swap_horiz),
          ),
        ],
      ),
    );
  }
}
