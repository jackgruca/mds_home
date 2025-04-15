// lib/utils/blog_structured_data.dart
import 'dart:convert';
import '../models/blog_post.dart';
import 'seo_manager.dart';

class BlogStructuredData {
  // Generate BlogPosting schema.org JSON-LD
  static String generateBlogPostingSchema(BlogPost post) {
    // Create proper description from content
    String description = post.content;
    if (post.isRichContent) {
      try {
        // Try to extract plain text from Quill Delta
        final delta = jsonDecode(post.content);
        description = SEOManager.extractPlainTextFromDelta(delta);
      } catch (e) {
        // Fallback to a generic description
        description = 'Read this article about ${post.title} by ${post.author}.';
      }
    }
    
    // Limit description length
    if (description.length > 160) {
      description = '${description.substring(0, 157)}...';
    }
    
    // Build structured data object
    final Map<String, dynamic> schemaData = {
      '@context': 'https://schema.org',
      '@type': 'BlogPosting',
      'headline': post.title,
      'description': description,
      'author': {
        '@type': 'Person',
        'name': post.author,
      },
      'datePublished': post.publishedDate.toIso8601String(),
      'dateModified': post.updatedDate?.toIso8601String() ?? post.publishedDate.toIso8601String(),
      'mainEntityOfPage': {
        '@type': 'WebPage',
        '@id': 'https://yourdomain.com/blog/${post.slug}',
      },
      'keywords': [...post.categories, ...post.tags].join(', '),
    };
    
    // Add image if available
    if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty) {
      schemaData['image'] = {
        '@type': 'ImageObject',
        'url': post.thumbnailUrl,
        'width': '1200',
        'height': '630',
      };
    }
    
    // Return formatted JSON-LD
    return jsonEncode(schemaData);
  }
  
  // Helper to extract plain text from Quill Delta
  static String _extractPlainTextFromDelta(List<dynamic> delta) {
    final buffer = StringBuffer();
    
    for (final op in delta) {
      if (op['insert'] is String) {
        buffer.write(op['insert']);
      }
    }
    
    return buffer.toString().trim();
  }
}