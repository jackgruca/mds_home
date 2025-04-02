// lib/widgets/common/help_overlay.dart
import 'package:flutter/material.dart';

/// A reusable help overlay widget that can be used throughout the app
class HelpOverlay extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onClose;
  
  const HelpOverlay({
    super.key, 
    required this.title,
    required this.content,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, 
                  color: Colors.blue[400],
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[400],
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A help button that can be placed throughout the app
class HelpButton extends StatelessWidget {
  final String title;
  final String content;
  
  const HelpButton({
    super.key, 
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: 'What can I do?',
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        child: InkWell(
          onTap: () {
            debugPrint("Help button clicked: $title");
            _showHelpOverlay(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.help_outline,
              size: 24,
              color: Colors.blue[400],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showHelpOverlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HelpOverlay(
        title: title,
        content: content,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// A summary dialog for the app functionality
class AppSummaryDialog extends StatelessWidget {
  final VoidCallback onClose;
  
  const AppSummaryDialog({
    super.key,
    required this.onClose, 
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_football,
                    color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'NFL Draft Simulator',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _getAppSummary(),
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, 
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pro Tip: Look for ? icons throughout the app for more help',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.blue[700] : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("Let's Draft!"),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getAppSummary() {
    return '''Welcome to your NFL Draft Simulator! Here's what you can do:

• Control any NFL team(s) in the draft
• Scout and draft from a realistic pool of college prospects
• Receive and propose trades with other teams
• Customize draft settings like speed, rounds, and randomness
• View team needs to make informed decisions
• See real-time draft analytics and grades
• Create your own custom draft boards

This simulator is designed to be both fun and realistic. Make strategic decisions, build your team, and see how your draft choices compare to AI teams. Good luck!''';
  }
}