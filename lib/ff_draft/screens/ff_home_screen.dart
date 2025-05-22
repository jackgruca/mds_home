import 'package:flutter/material.dart';

class FFHomeScreen extends StatefulWidget {
  const FFHomeScreen({super.key});

  @override
  State<FFHomeScreen> createState() => _FFHomeScreenState();
}

class _FFHomeScreenState extends State<FFHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Immediately navigate to the setup screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/ff-draft/setup');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
} 