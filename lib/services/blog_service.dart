// lib/services/blog_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/blog_post.dart';

class BlogService {
  static const String _blogsAssetPath = 'assets/data/blog_posts.json';
  static List<BlogPost>? _cachedPosts;
  
  // Get all blog posts
  static Future<List<BlogPost>> getAllPosts() async {
    if (_cachedPosts != null) {
      return _cachedPosts!;
    }
    
    try {
      final jsonString = await rootBundle.loadString(_blogsAssetPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedPosts = jsonList.map((json) => BlogPost.fromJson(json)).toList();
      
      // Sort by published date (newest first)
      _cachedPosts!.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
      
      return _cachedPosts!;
    } catch (e) {
      debugPrint('Error loading blog posts: $e');
      return [];
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
  
  // Get posts by tag
  static Future<List<BlogPost>> getPostsByTag(String tag) async {
    final posts = await getAllPosts();
    return posts.where((post) => post.tags.contains(tag.toLowerCase())).toList();
  }
}