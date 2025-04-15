// lib/services/blog_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/blog_post.dart';

class BlogService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionPath = 'blog_posts';
  
  // Get all blog posts with pagination
  static Future<List<BlogPost>> getPaginatedPosts({
    int limit = 10,
    DocumentSnapshot? startAfter,
    List<String>? categories,
    bool publishedOnly = true,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(_collectionPath)
          .orderBy('publishedDate', descending: true)
          .limit(limit);
      
      // Apply startAfter cursor for pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      // Filter by published status
      if (publishedOnly) {
        query = query.where('isPublished', isEqualTo: true);
      }
      
      // Filter by categories if provided
      if (categories != null && categories.isNotEmpty) {
        query = query.where('categories', arrayContainsAny: categories);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting blog posts: $e');
      return [];
    }
  }
  
  // Get a single post by ID
  static Future<BlogPost?> getPostById(String id) async {
    try {
      final doc = await _db.collection(_collectionPath).doc(id).get();
      
      if (doc.exists) {
        return BlogPost.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting blog post by ID: $e');
      return null;
    }
  }
  
  // Get a post by slug (for SEO-friendly URLs)
  static Future<BlogPost?> getPostBySlug(String slug) async {
    try {
      final query = await _db.collection(_collectionPath)
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return BlogPost.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting blog post by slug: $e');
      return null;
    }
  }
  
  // Increment view count for a post
  static Future<void> incrementViewCount(String postId) async {
    try {
      await _db.collection(_collectionPath).doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }
  
  // Get all categories used in posts
  static Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _db.collection(_collectionPath).get();
      
      // Extract all categories from all posts
      final Set<String> categories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['categories'] != null) {
          categories.addAll(List<String>.from(data['categories']));
        }
      }
      
      return categories.toList()..sort();
    } catch (e) {
      debugPrint('Error getting all categories: $e');
      return [];
    }
  }
  
  // CRUD operations for admin
  
  // Create a new blog post
  static Future<String?> createPost(BlogPost post) async {
    try {
      final docRef = await _db.collection(_collectionPath).add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating blog post: $e');
      return null;
    }
  }
  
  // Update an existing blog post
  static Future<bool> updatePost(BlogPost post) async {
    try {
      await _db.collection(_collectionPath).doc(post.id).update(post.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating blog post: $e');
      return false;
    }
  }
  
  // Delete a blog post
  static Future<bool> deletePost(String id) async {
    try {
      await _db.collection(_collectionPath).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting blog post: $e');
      return false;
    }
  }
  
  // Change publish status
  static Future<bool> setPublishStatus(String id, bool isPublished) async {
    try {
      await _db.collection(_collectionPath).doc(id).update({
        'isPublished': isPublished,
        'updatedDate': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error changing publish status: $e');
      return false;
    }
  }
}