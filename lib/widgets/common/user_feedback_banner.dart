// lib/widgets/common/user_feedback_banner.dart
import 'package:flutter/material.dart';
import '../../utils/theme_config.dart';
import 'contact_form_dialog.dart';
import '../auth/auth_dialog.dart';
import '../auth/auth_status_widget.dart';

class UserFeedbackBanner extends StatefulWidget {
  final VoidCallback? onDismiss;
  final bool allowDismiss;
  
  const UserFeedbackBanner({
    super.key,
    this.onDismiss,
    this.allowDismiss = true,
  });

  @override
  State<UserFeedbackBanner> createState() => _UserFeedbackBannerState();
}

class _UserFeedbackBannerState extends State<UserFeedbackBanner> {
  final bool _isSubscribed = false;
  
  void _showContactForm() {
    showDialog(
      context: context,
      builder: (context) => const ContactFormDialog(),
    );
  }
  
  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => const AuthDialog(
        initialMode: AuthMode.signUp,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDarkMode 
                ? [AppTheme.darkNavy, Color.lerp(AppTheme.darkNavy, Colors.black, 0.3)!]
                : [AppTheme.lightBackground, Color.lerp(AppTheme.brightBlue, Colors.white, 0.85)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with optional dismiss
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_football_outlined,
                          color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NFL Draft Simulator',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppTheme.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.allowDismiss && widget.onDismiss != null)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                      onPressed: widget.onDismiss,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            
            // Main content - now more compact
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text content
                  Expanded(
                    child: Text(
                      'Create an account for betting analytics and fantasy forecasting coming soon!',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Action Buttons - now just two buttons side by side
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Contact form button
                      OutlinedButton(
                        onPressed: _showContactForm,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                          side: BorderSide(
                            color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Contact'),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Auth status/sign-in widget
                      const AuthStatusWidget(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}