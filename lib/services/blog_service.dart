// lib/services/blog_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog_post.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'blog_posts';

  // Get all blog posts
  Future<List<BlogPost>> getBlogPosts({
    int limit = 10,
    String? tag,
    bool featuredOnly = false,
  }) async {
    try {
      Query query = _firestore.collection(_collection)
          .orderBy('publishedDate', descending: true);
      
      if (featuredOnly) {
        query = query.where('featured', isEqualTo: true);
      }
      
      if (tag != null) {
        query = query.where('tags', arrayContains: tag);
      }
      
      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting blog posts: $e');
      return [];
    }
  }

  // Get a single blog post by ID
  Future<BlogPost?> getBlogPost(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return BlogPost.fromFirestore(doc);
    } catch (e) {
      print('Error getting blog post: $e');
      return null;
    }
  }

  // Get a single blog post by slug
  Future<BlogPost?> getBlogPostBySlug(String slug) async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return BlogPost.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting blog post by slug: $e');
      return null;
    }
  }

  // Increment view count for a post
  Future<void> incrementViews(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  // Get all unique tags
  Future<List<String>> getTags() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      Set<String> tags = {};
      
      for (var doc in snapshot.docs) {
        final post = BlogPost.fromFirestore(doc);
        tags.addAll(post.tags);
      }
      
      return tags.toList()..sort();
    } catch (e) {
      print('Error getting tags: $e');
      return [];
    }
  }
}