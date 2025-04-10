// Create a new file: lib/widgets/auth/email_verification_banner.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  _EmailVerificationBannerState createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isVisible = true;
  bool _isSendingEmail = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Don't show if user is not logged in or email is already verified
    if (!authProvider.isLoggedIn || AuthService.isEmailVerified()) {
      return const SizedBox.shrink();
    }
    
    // Don't show if banner is dismissed
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Please verify your email address to ensure access to all features',
              style: TextStyle(fontSize: 12),
            ),
          ),
          _isSendingEmail
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                )
              : TextButton(
                  onPressed: _sendVerificationEmail,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Resend', style: TextStyle(fontSize: 12)),
                ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _isVisible = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isSendingEmail = true;
    });
    
    try {
      await AuthService.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
    }
  }
}