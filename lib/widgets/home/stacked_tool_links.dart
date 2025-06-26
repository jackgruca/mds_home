import 'package:flutter/material.dart';
import '../../utils/theme_config.dart'; // Import ThemeConfig for color access

class StackedToolLinks extends StatelessWidget {
  // Expect a list of tools, including an 'isPlaceholder' flag
  final List<Map<String, dynamic>> tools;

  const StackedToolLinks({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
     final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final Color placeholderColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500;
     final Color titleColor = isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed; // Use red for titles

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
        // Use red for active tools, gray for placeholders
        final Color actualTitleColor = isPlaceholder ? placeholderColor : titleColor;
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
                ? Icon(tool['icon'], size: 32, color: isPlaceholder ? placeholderColor : titleColor) // Use red for icons too
                : tool['icon'], // Allow for custom icon widgets if needed
              title: Text(
                displayTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: actualTitleColor,
                  fontWeight: FontWeight.w600, // Make titles slightly bolder
                )
              ),
              subtitle: Text(
                tool['desc'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtitleColor)
                ),
              onTap: onTapAction, // Disable tap for placeholders
              trailing: (tool['route'] != null && !isPlaceholder) 
                        ? Icon(Icons.arrow_forward_ios, size: 18, color: titleColor) // Make arrow red too
                        : null,
              enabled: !isPlaceholder, // Visually disable the ListTile
            ),
          ),
        );
      }).toList(),
    );
  }
} 