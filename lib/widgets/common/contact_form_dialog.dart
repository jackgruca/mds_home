// lib/widgets/common/contact_form_dialog.dart
import 'package:flutter/material.dart';
import '../../services/message_service.dart';
import '../../utils/theme_config.dart';

class ContactFormDialog extends StatefulWidget {
  const ContactFormDialog({super.key});

  @override
  _ContactFormDialogState createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  bool _hasError = false;
  String? _errorMessage;
  String _feedbackType = 'Feature Request';

  final List<String> _feedbackTypes = [
    'Feature Request',
    'Bug Report',
    'General Feedback',
    'Question',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
        _hasError = false;
        _errorMessage = null;
      });

      try {
        final success = await MessageService.saveUserMessage(
          name: _nameController.text,
          email: _emailController.text,
          message: _messageController.text,
          feedbackType: _feedbackType,
        );

        if (success) {
          setState(() {
            _isSubmitting = false;
            _isSubmitted = true;
          });
        } else {
          setState(() {
            _isSubmitting = false;
            _hasError = true;
            _errorMessage = "The message was saved but couldn't be sent via email. We'll send it as soon as possible.";
          });
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
          _hasError = true;
          _errorMessage = "An error occurred: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isSubmitted) {
      return AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Message Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you for your message. We\'ve received your feedback and will review it soon.',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      title: Row(
        children: [
          Icon(
            Icons.contact_mail,
                                    color: isDarkMode ? ThemeConfig.gold : ThemeConfig.deepRed,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Contact Us',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasError)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage ?? 'An error occurred. Please try again later.',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                DropdownButtonFormField<String>(
                  value: _feedbackType,
                  decoration: InputDecoration(
                    labelText: 'Feedback Type',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  dropdownColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                  items: _feedbackTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _feedbackType = newValue!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your message';
                    }
                    if (value.length < 10) {
                      return 'Message is too short (minimum 10 characters)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Your message will be sent securely to our team and stored for reference.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode ? ThemeConfig.gold : ThemeConfig.deepRed,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}