// lib/widgets/auth/auth_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_config.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_dialog.dart';

enum AuthMode { signIn, signUp }

class AuthDialog extends StatefulWidget {
  final AuthMode initialMode;

  const AuthDialog({
    super.key,
    this.initialMode = AuthMode.signIn,
  });

  @override
  _AuthDialogState createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  late AuthMode _authMode;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _subscribeToUpdates = true; // Auto-checked by default
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authMode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
      // Clear form fields when switching
      if (_authMode == AuthMode.signIn) {
        _nameController.clear();
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = false;

      try {
        if (_authMode == AuthMode.signIn) {
          // Handle sign in
          success = await authProvider.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
        } else {
          // Handle sign up
          success = await authProvider.register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            isSubscribed: _subscribeToUpdates,
          );
        }
        
        if (mounted) {
          if (success) {
            // Close the dialog with success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_authMode == AuthMode.signIn 
                    ? 'Successfully signed in!' 
                    : 'Account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true); // Return success
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${authProvider.error ?? "Unknown error"}'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      _authMode == AuthMode.signIn ? Icons.login : Icons.person_add,
                      color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _authMode == AuthMode.signIn ? 'Sign In' : 'Create Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Name field (sign up only)
                if (_authMode == AuthMode.signUp)
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _authMode == AuthMode.signUp
                        ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          }
                        : null,
                  ),
                
                if (_authMode == AuthMode.signUp) const SizedBox(height: 16),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (_authMode == AuthMode.signUp && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                if (_authMode == AuthMode.signIn) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close current dialog
                        showDialog(
                          context: context,
                          builder: (context) => const ForgotPasswordDialog(),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        foregroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                      ),
                      child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Subscribe checkbox (sign up only)
                if (_authMode == AuthMode.signUp)
                  CheckboxListTile(
                    title: Text(
                      'Subscribe for draft updates, betting analytics, and fantasy forecasting',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    value: _subscribeToUpdates,
                    onChanged: (value) {
                      setState(() {
                        _subscribeToUpdates = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                
                const SizedBox(height: 24),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_authMode == AuthMode.signIn ? 'Sign In' : 'Create Account'),
                ),
                
                const SizedBox(height: 16),
                
                // Switch authentication mode
                TextButton(
                  onPressed: _switchAuthMode,
                  child: Text(
                    _authMode == AuthMode.signIn
                        ? 'Don\'t have an account? Sign Up'
                        : 'Already have an account? Sign In',
                    style: TextStyle(
                      color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}