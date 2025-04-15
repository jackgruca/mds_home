// lib/services/blog_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blog_post.dart';

class BlogService {
  static const String _postsKey = 'blog_posts';
  
  // Temporary sample posts for initial testing
  static final List<BlogPost> _samplePosts = [
    BlogPost(
      id: '1',
      title: 'Understanding NFL Draft Value Charts',
      content: 'The NFL Draft Value Chart was originally developed by Jimmy Johnson...',
      author: 'Draft Expert',
      publishedDate: DateTime.now().subtract(const Duration(days: 7)),
    ),
    BlogPost(
      id: '2',
      title: 'Top QB Prospects for 2025',
      content: 'With the college football season underway, let\'s look at the top QB prospects...',
      author: 'Talent Scout',
      publishedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
  
  // Get all blog posts
  static Future<List<BlogPost>> getAllPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString(_postsKey);
      
      if (postsJson != null) {
        final List<dynamic> decoded = jsonDecode(postsJson);
        return decoded.map((item) => BlogPost.fromJson(item)).toList();
      }
      
      // If no saved posts, save and return sample posts
      await _saveSamplePosts();
      return _samplePosts;
    } catch (e) {
      debugPrint('Error getting blog posts: $e');
      return _samplePosts; // Fallback to sample posts on error
    }
  }
  
  // Save sample posts for initial testing
  static Future<void> _saveSamplePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = jsonEncode(_samplePosts.map((post) => post.toJson()).toList());
      await prefs.setString(_postsKey, postsJson);
    } catch (e) {
      debugPrint('Error saving sample posts: $e');
    }
  }
  
  // Get a single post by ID
  static Future<BlogPost?> getPostById(String id) async {
    final posts = await getAllPosts();
    try {
      return posts.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }
}