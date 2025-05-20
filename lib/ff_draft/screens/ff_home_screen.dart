import 'package:flutter/material.dart';

class FFHomeScreen extends StatefulWidget {
  const FFHomeScreen({super.key});

  @override
  State<FFHomeScreen> createState() => _FFHomeScreenState();
}

class _FFHomeScreenState extends State<FFHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fantasy Football Mock Draft'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Fantasy Football Mock Draft Simulator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/ff-draft/setup');
              },
              child: const Text('Start New Draft'),
            ),
          ],
        ),
      ),
    );
  }
} 