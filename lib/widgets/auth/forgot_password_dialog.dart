// // lib/widgets/auth/forgot_password_dialog.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';
// import '../../utils/theme_config.dart';
// import '../design_system/mds_button.dart';
// import 'reset_password_dialog.dart';

// class ForgotPasswordDialog extends StatefulWidget {
//   const ForgotPasswordDialog({super.key});

//   @override
//   _ForgotPasswordDialogState createState() => _ForgotPasswordDialogState();
// }

// class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   bool _isSubmitting = false;
//   bool _emailSent = false;
//   String? _error;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }

//   Future<void> _requestReset() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       setState(() {
//         _isSubmitting = true;
//         _error = null;
//       });

//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final success = await authProvider.requestPasswordReset(_emailController.text);
      
//       setState(() {
//         _isSubmitting = false;
//       });

//       if (success) {
//         setState(() {
//           _emailSent = true;
//         });
//       } else {
//         setState(() {
//           _error = authProvider.error ?? 'Failed to send reset email';
//         });
//       }
//     }
//   }

//   void _proceedToReset() {
//     Navigator.of(context).pop(); // Close current dialog
    
//     showDialog(
//       context: context,
//       builder: (context) => ResetPasswordDialog(email: _emailController.text),
//     );
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
//           child: _emailSent ? _buildSuccessUI() : _buildRequestUI(isDarkMode),
//         ),
//       ),
//     );
//   }

//   Widget _buildRequestUI(bool isDarkMode) {
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
//                 color: isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed,
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 'Forgot Password',
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
          
//           const Text(
//             "Enter your email address and we'll send you instructions to reset your password.",
//             style: TextStyle(fontSize: 14),
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
          
//           // Email field
//           TextFormField(
//             controller: _emailController,
//             decoration: InputDecoration(
//               labelText: 'Email',
//               border: const OutlineInputBorder(),
//               filled: true,
//               fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
//               prefixIcon: const Icon(Icons.email),
//             ),
//             keyboardType: TextInputType.emailAddress,
//             textInputAction: TextInputAction.done,
//             enabled: !_isSubmitting,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter your email';
//               }
//               if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                 return 'Please enter a valid email address';
//               }
//               return null;
//             },
//           ),
          
//           const SizedBox(height: 24),
          
//           // Submit button
//           MdsButton(
//             onPressed: _isSubmitting ? null : _requestReset,
//             text: 'Send Reset Instructions',
//             isLoading: _isSubmitting,
//           ),
          
//           const SizedBox(height: 16),
          
//           // Back to sign in
//           MdsButton(
//             onPressed: () => Navigator.of(context).pop(),
//             text: 'Back to Sign In',
//             type: MdsButtonType.text,
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
//           'Reset Instructions Sent!',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Text(
//           'We\'ve sent password reset instructions to ${_emailController.text}. Please check your email.',
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 24),
//         MdsButton(
//           onPressed: _proceedToReset,
//           text: 'Enter Reset Code',
//         ),
//         const SizedBox(height: 8),
//         MdsButton(
//           onPressed: () => Navigator.of(context).pop(),
//           text: 'Close',
//           type: MdsButtonType.text,
//         ),
//       ],
//     );
//   }
// }