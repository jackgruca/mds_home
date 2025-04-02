// lib/widgets/walkthrough/welcome_dialog.dart
import 'package:flutter/material.dart';

class WelcomeDialog extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback? onSkip;
  
  const WelcomeDialog({
    super.key,
    required this.onGetStarted,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_football,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Welcome text
            const Text(
              "Welcome to NFL Draft Simulator",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Experience the excitement of the NFL Draft! Take control of your favorite team and make draft picks, execute trades, and build your dream roster.",
              style: TextStyle(
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Features list
            Column(
              children: [
                _buildFeatureItem(
                  context, 
                  Icons.sports_football_outlined, 
                  "Make draft picks for your team"
                ),
                _buildFeatureItem(
                  context, 
                  Icons.swap_horiz, 
                  "Execute and negotiate trades"
                ),
                _buildFeatureItem(
                  context, 
                  Icons.analytics_outlined, 
                  "Analyze your draft performance"
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Get started button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Get Started",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Skip button
            if (onSkip != null)
              TextButton(
                onPressed: onSkip,
                child: const Text("Skip Tutorial"),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}