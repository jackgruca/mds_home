import 'package:flutter/material.dart';

class TutorialSection extends StatelessWidget {
  final Map<String, dynamic> section;
  
  const TutorialSection({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        leading: Icon(section['icon'], color: Colors.blue),
        title: Text(
          section['title'], 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Text(section['description']),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildSectionContent(section['content']),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildSectionContent(List<dynamic> content) {
    return content.map<Widget>((item) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['subtitle'], 
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold
            )
          ),
          Text(item['details']),
          ...((item['features'] as List).map((feature) => 
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            )
          ).toList())
        ],
      );
    }).toList();
  }
}