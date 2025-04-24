import 'package:flutter/material.dart';
import 'package:mds_home/widgets/tutorial/tutorial_section.dart';

import '../utils/tutorial_content.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use StickToTheModel'),
      ),
      body: ListView(
        children: [
          // Introductory banner
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                Text(
                  'Welcome to Your Draft Simulation Companion',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Your ultimate tool for NFL Draft strategy and simulation',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
          
          // Dynamic tutorial sections
          ...TutorialContent.sections.map(
            (section) => TutorialSection(section: section)
          ),
          
          _buildAdvancedTipsSection(),

          // Video Tutorial / External Resources section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Want to See It In Action?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Replace with actual tutorial video URL
                    // launch('https://tutorial-video-url');
                  },
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text('Watch Tutorial Video'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // In lib/screens/tutorial_screen.dart, add this method
Widget _buildAdvancedTipsSection() {
  return ExpansionTile(
    title: const Text(
      'Advanced Strategies',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold
      )
    ),
    children: TutorialContent.advancedTips.map((tip) => 
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 8),
              ...((tip['tips'] as List).map((tipText) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tipText)),
                    ],
                  ),
                )
              ).toList())
            ],
          ),
        ),
      )
    ).toList(),
  );
}
}