// lib/widgets/blog/tag_cloud_widget.dart
import 'package:flutter/material.dart';
import '../../services/blog_service.dart';
import '../../utils/theme_config.dart';

class TagCloudWidget extends StatefulWidget {
  final Function(String) onTagSelected;
  
  const TagCloudWidget({super.key, required this.onTagSelected});

  @override
  _TagCloudWidgetState createState() => _TagCloudWidgetState();
}

class _TagCloudWidgetState extends State<TagCloudWidget> {
  List<String> _tags = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadTags();
  }
  
  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // This assumes you'd add a getAllTags method to BlogService
      final tags = await BlogService.getAllTags();
      
      setState(() {
        _tags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Topics',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tags.isEmpty
                  ? const Text('No tags available')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return ActionChip(
                          label: Text('#$tag'),
                          backgroundColor: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade200,
                          onPressed: () {
                            widget.onTagSelected(tag);
                          },
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }
}