// lib/utils/blog_router.dart
import 'package:flutter/material.dart';
import '../screens/blog/blog_detail_screen.dart';

class BlogRouter {
  static const String blogPathPrefix = '/blog/';
  
  // Parse URL to get blog post ID
  static String? getBlogIdFromPath(String path) {
    if (path.startsWith(blogPathPrefix)) {
      return path.substring(blogPathPrefix.length);
    }
    return null;
  }
  
  // Generate URL-friendly ID from title
  static String generateUrlId(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')  // Remove special characters
        .replaceAll(RegExp(r'\s+'), '-');    // Replace spaces with hyphens
  }
  
  // Handle blog routes
  static Route<dynamic>? handleBlogRoute(RouteSettings settings) {
    final String path = settings.name ?? '';
    final blogId = getBlogIdFromPath(path);
    
    if (blogId != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => BlogDetailScreen(postId: blogId),
      );
    }
    
    return null;
  }
}