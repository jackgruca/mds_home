// lib/models/blog_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPost {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? author;
  final List<String> tags;
  final DateTime publishedDate;
  final DateTime? updatedDate;
  final int views;
  final bool featured;
  final String slug;

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.author,
    required this.tags,
    required this.publishedDate,
    this.updatedDate,
    this.views = 0,
    this.featured = false,
    required this.slug,
  });

  // Create from Firestore document
  factory BlogPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlogPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      author: data['author'],
      tags: List<String>.from(data['tags'] ?? []),
      publishedDate: (data['publishedDate'] as Timestamp).toDate(),
      updatedDate: data['updatedDate'] != null ? (data['updatedDate'] as Timestamp).toDate() : null,
      views: data['views'] ?? 0,
      featured: data['featured'] ?? false,
      slug: data['slug'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'author': author,
      'tags': tags,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'updatedDate': updatedDate != null ? Timestamp.fromDate(updatedDate!) : null,
      'views': views,
      'featured': featured,
      'slug': slug,
    };
  }

  // Create slug from title
  static String createSlug(String title) {
    return title.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }
}