// Create a new file: lib/widgets/draft/draft_action_dialog.dart

import 'package:flutter/material.dart';

class DraftActionDialog extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onUndo;
  final bool canUndo;
  
  const DraftActionDialog({
    super.key,
    required this.onRestart,
    required this.onUndo,
    required this.canUndo,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings_backup_restore, 
               color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Draft Actions'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canUndo) ...[
            ListTile(
              leading: Icon(Icons.undo,
                          color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700),
              title: const Text('Undo Last Pick'),
              subtitle: const Text('Go back to your last decision'),
              onTap: () {
                Navigator.of(context).pop(); // Close dialog
                onUndo();
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: Icon(Icons.refresh,
                        color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700),
            title: const Text('Restart Draft'),
            subtitle: const Text('Start the draft over from the beginning'),
            onTap: () {
              Navigator.of(context).pop(); // Close dialog
              onRestart();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}