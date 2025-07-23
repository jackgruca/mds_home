// // lib/widgets/auth/reset_password_dialog.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';
// import '../../utils/theme_config.dart';

// class ResetPasswordDialog extends StatefulWidget {
//   final String email;
  
//   const ResetPasswordDialog({
//     super.key,
//     required this.email,
//   });

//   @override
//   _ResetPasswordDialogState createState() => _ResetPasswordDialogState();
// }

// class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _tokenController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
  
//   bool _isSubmitting = false;
//   bool _isSuccess = false;
//   String? _error;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   @override
//   void dispose() {
//     _tokenController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   Future<void> _resetPassword() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       setState(() {
//         _isSubmitting = true;
//         _error = null;
//       });

//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
//       // First verify the token
//       final isValid = await authProvider.verifyResetToken(
//         widget.email,
//         _tokenController.text,
//       );
      
//       if (!isValid) {
//         setState(() {
//           _isSubmitting = false;
//           _error = 'Invalid or expired reset code. Please try again.';
//         });
//         return;
//       }
      
//       // Then reset the password
//       final success = await authProvider.resetPassword(
//         widget.email,
//         _tokenController.text,
//         _passwordController.text,
//       );
      
//       setState(() {
//         _isSubmitting = false;
//       });

//       if (success) {
//         setState(() {
//           _isSuccess = true;
//         });
//       } else {
//         setState(() {
//           _error = authProvider.error ?? 'Failed to reset password';
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: _isSuccess ? _buildSuccessUI() : _buildResetUI(isDarkMode),
//         ),
//       ),
//     );
//   }

//   Widget _buildResetUI(bool isDarkMode) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Header
//           Row(
//             children: [
//               Icon(
//                 Icons.lock_reset,
//                 color: isDarkMode ? ThemeConfig.gold : ThemeConfig.deepRed,
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 'Reset Password',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Spacer(),
//               IconButton(
//                 icon: const Icon(Icons.close),
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 16),
          
//           Text(
//             'Enter the reset code sent to ${widget.email} and create a new password.',
//             style: const TextStyle(fontSize: 14),
//           ),
          
//           const SizedBox(height: 16),
          
//           if (_error != null)
//             Container(
//               padding: const EdgeInsets.all(8),
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(4),
//                 border: Border.all(color: Colors.red.shade300),
//               ),
//               child: Text(
//                 _error!,
//                 style: TextStyle(color: Colors.red.shade700, fontSize: 12),
//               ),
//             ),
          
//           // Reset token field
//           TextFormField(
//             controller: _tokenController,
//             decoration: InputDecoration(
//               labelText: 'Reset Code',
//               border: const OutlineInputBorder(),
//               filled: true,
//               fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
//               prefixIcon: const Icon(Icons.vpn_key),
//             ),
//             textInputAction: TextInputAction.next,
//             enabled: !_isSubmitting,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter the reset code';
//               }
//               return null;
//             },
//           ),
          
//           const SizedBox(height: 16),
          
//           // New password field
//           TextFormField(
//             controller: _passwordController,
//             decoration: InputDecoration(
//               labelText: 'New Password',
//               border: const OutlineInputBorder(),
//               filled: true,
//               fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
//               prefixIcon: const Icon(Icons.lock),
//               suffixIcon: IconButton(
//                 icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
//                 onPressed: () {
//                   setState(() {
//                     _obscurePassword = !_obscurePassword;
//                   });
//                 },
//               ),
//             ),
//             obscureText: _obscurePassword,
//             textInputAction: TextInputAction.next,
//             enabled: !_isSubmitting,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter a new password';
//               }
//               if (value.length < 6) {
//                 return 'Password must be at least 6 characters';
//               }
//               return null;
//             },
//           ),
          
//           const SizedBox(height: 16),
          
//           // Confirm password field
//           TextFormField(
//             controller: _confirmPasswordController,
//             decoration: InputDecoration(
//               labelText: 'Confirm Password',
//               border: const OutlineInputBorder(),
//               filled: true,
//               fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
//               prefixIcon: const Icon(Icons.lock_outline),
//               suffixIcon: IconButton(
//                 icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
//                 onPressed: () {
//                   setState(() {
//                     _obscureConfirmPassword = !_obscureConfirmPassword;
//                   });
//                 },
//               ),
//             ),
//             obscureText: _obscureConfirmPassword,
//             textInputAction: TextInputAction.done,
//             enabled: !_isSubmitting,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please confirm your password';
//               }
//               if (value != _passwordController.text) {
//                 return 'Passwords do not match';
//               }
//               return null;
//             },
//           ),
          
//           const SizedBox(height: 24),
          
//           // Submit button
//           ElevatedButton(
//             onPressed: _isSubmitting ? null : _resetPassword,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isDarkMode ? ThemeConfig.gold : ThemeConfig.deepRed,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 12),
//             ),
//             child: _isSubmitting
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : const Text('Reset Password'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSuccessUI() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Icon(
//           Icons.check_circle_outline,
//           color: Colors.green,
//           size: 64,
//         ),
//         const SizedBox(height: 16),
//         const Text(
//           'Password Reset Successful!',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         const Text(
//           'Your password has been reset successfully. You can now sign in with your new password.',
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 24),
//         ElevatedButton(
//           onPressed: () => Navigator.of(context).pop(),
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           ),
//           child: const Text('Sign In'),
//         ),
//       ],
//     );
//   }
// }