// lib/widgets/blog/blog_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/blog_post.dart';
import '../../utils/constants.dart';

class BlogCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback onTap;
  final bool isHorizontal;

  const BlogCard({
    super.key,
    required this.post,
    required this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');
    
    if (isHorizontal) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured image
              if (post.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12)
                  ),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                  ),
                ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Date & Views
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, 
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(post.publishedDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.visibility, size: 12, 
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${post.views}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Tags
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: post.tags.take(2).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade800,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Vertical card
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12)
                ),
                child: AspectRatio(
                  aspectRatio: 16/9,
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
                  ),
                ),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Date & views
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, 
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(post.publishedDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.visibility, size: 12, 
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${post.views}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Tags
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: post.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade800,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}