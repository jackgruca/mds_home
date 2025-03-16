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
      elevation: 1, // Reduced elevation for subtlety
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey.shade800.withOpacity(0.6) : Colors.grey.shade50, // More subtle background
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Text content
              Expanded(
                child: Text(
                  "Help us improve by sharing any suggestions/feedback! Create an account for advanced features.",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Contact button only (remove the Auth button as it will be in header)
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
                child: const Text('Contact Us'),
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
      ),
    );
  }

}