import 'package:flutter/material.dart';

class StackedToolLinks extends StatelessWidget {
  // Expect a list of tools, including an 'isPlaceholder' flag
  final List<Map<String, dynamic>> tools;

  const StackedToolLinks({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
     final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final Color placeholderColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500;

     // Handle empty tools list gracefully
     if (tools.isEmpty) {
       return const Padding(
         padding: EdgeInsets.symmetric(vertical: 16.0),
         child: Center(child: Text('No tools available for this section yet.')),
       );
     }

     return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tools.map((tool) {
        final bool isPlaceholder = tool['isPlaceholder'] ?? false;
        final String displayTitle = tool['title'] + (isPlaceholder ? ' *' : '');
        final Color titleColor = isPlaceholder ? placeholderColor : Theme.of(context).textTheme.titleLarge?.color ?? (isDarkMode ? Colors.white : Colors.black);
        final Color subtitleColor = isPlaceholder ? placeholderColor : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
        final VoidCallback? onTapAction = (tool['route'] != null && !isPlaceholder) 
                                           ? () => Navigator.pushNamed(context, tool['route']) 
                                           : null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: isPlaceholder ? 1 : 2,
            color: isPlaceholder ? (isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200) : null,
            child: ListTile(
              leading: tool['icon'] is IconData 
                ? Icon(tool['icon'], size: 32, color: isPlaceholder ? placeholderColor : Theme.of(context).colorScheme.primary) 
                : tool['icon'], // Allow for custom icon widgets if needed
              title: Text(
                displayTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: titleColor)
              ),
              subtitle: Text(
                tool['desc'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtitleColor)
                ),
              onTap: onTapAction, // Disable tap for placeholders
              trailing: (tool['route'] != null && !isPlaceholder) 
                        ? const Icon(Icons.arrow_forward_ios, size: 18) 
                        : null,
              enabled: !isPlaceholder, // Visually disable the ListTile
            ),
          ),
        );
      }).toList(),
    );
  }
} 