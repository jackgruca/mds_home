// lib/utils/seo_manager.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:js' as js;
import '../models/blog_post.dart';
import '../services/blog_service.dart';

class SEOManager {
  // Update metadata for the current page
  static void updateMetadata({
    required String title,
    required String description,
    String? keywords,
    String? imageUrl,
  }) {
    if (!kIsWeb) return;
    
    try {
      js.context.callMethod('updateMetadata', [
        title,
        description,
        keywords ?? '',
        null, // Let the browser set the current URL
        imageUrl ?? '',
      ]);
    } catch (e) {
      debugPrint('Error updating metadata: $e');
    }
  }
  
  // Update metadata specifically for a blog post
  static Future<void> updateBlogPostMetadata(BlogPost post) async {
    if (!kIsWeb) return;
    
    try {
      // Generate description from content (first 150 chars)
      final description = post.content.length > 150
          ? '${post.content.substring(0, 150)}...'
          : post.content;
      
      // Create keywords from categories and tags
      final keywords = [
        ...post.categories,
        ...post.tags,
        'NFL', 'draft', 'football'
      ].join(', ');
      
      updateMetadata(
        title: '${post.title} | NFL Draft Simulator',
        description: description,
        keywords: keywords,
        imageUrl: post.thumbnailUrl,
      );
    } catch (e) {
      debugPrint('Error updating blog post metadata: $e');
    }
  }
  
  // Register JavaScript handler to get blog post metadata
  static void registerJavaScriptHandlers() {
    if (!kIsWeb) return;
    
    try {
      // Set up a handler that can be called from JavaScript
      js.context['getBlogMetadataBySlug'] = (String slug) async {
        try {
          final post = await BlogService.getPostBySlug(slug);
          
          if (post != null) {
            // Generate description and keywords
            final description = post.content.length > 150
                ? '${post.content.substring(0, 150)}...'
                : post.content;
            
            final keywords = [
              ...post.categories,
              ...post.tags,
              'NFL', 'draft', 'football'
            ].join(', ');
            
            // Return JSON object
            return jsonEncode({
              'title': post.title,
              'description': description,
              'keywords': keywords,
              'imageUrl': post.thumbnailUrl,
            });
          }
        } catch (e) {
          debugPrint('Error in getBlogMetadataBySlug: $e');
        }
        
        return null;
      };
    } catch (e) {
      debugPrint('Error registering JavaScript handlers: $e');
    }
  }
}