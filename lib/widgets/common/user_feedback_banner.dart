// lib/widgets/common/user_feedback_banner.dart
import 'package:flutter/material.dart';
import '../../utils/theme_config.dart';
import 'contact_form_dialog.dart';

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
  bool _isSubscribed = false;
  bool _isValidEmail = false;
  bool _showEmailField = false;
  final _emailController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  void _validateEmail(String value) {
    setState(() {
      // Simple email validation
      _isValidEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
    });
  }
  
  void _showContactForm() {
    showDialog(
      context: context,
      builder: (context) => const ContactFormDialog(),
    );
  }
  
  void _toggleSubscriptionField() {
    setState(() {
      _showEmailField = !_showEmailField;
    });
  }
  
  void _submitEmail() {
    if (_isValidEmail) {
      // Here you would typically send the email to your backend
      // For now we'll just show a success message
      setState(() {
        _isSubscribed = true;
        _showEmailField = false;
      });
      
      // Show confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for subscribing! You\'ll receive updates soon.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Help Us Improve',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppTheme.darkNavy,
                    ),
                  ),
                  const Spacer(),
                  if (widget.allowDismiss && widget.onDismiss != null)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
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
            
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isSubscribed) ...[
                    Text(
                      'We\'re constantly improving our draft simulator. Share your suggestions or subscribe for updates on new features including betting analytics and fantasy forecasting.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Contact form button (replacing email copy button)
                        OutlinedButton.icon(
                          onPressed: _showContactForm,
                          icon: const Icon(Icons.contact_mail, size: 16),
                          label: const Text('Contact Me'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                            side: BorderSide(
                              color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                            ),
                          ),
                        ),
                        
                        // Subscribe button
                        ElevatedButton.icon(
                          onPressed: _toggleSubscriptionField,
                          icon: const Icon(Icons.notifications_outlined, size: 16),
                          label: Text(_showEmailField ? 'Cancel' : 'Get Updates'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    // Conditional email field
                    if (_showEmailField) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                isDense: true,
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isValidEmail ? _submitEmail : null,
                            icon: const Icon(Icons.send),
                            color: _isValidEmail
                                ? (isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed)
                                : Colors.grey,
                            tooltip: 'Subscribe',
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    // Thank you message after subscription
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thanks for subscribing! You\'ll receive updates on new features soon.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showContactForm,
                      icon: const Icon(Icons.contact_mail, size: 16),
                      label: const Text('Contact Me'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                        side: BorderSide(
                          color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}