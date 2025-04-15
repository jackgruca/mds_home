// lib/models/blog_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime publishedDate;
  final DateTime? updatedDate;
  final String? thumbnailUrl;
  final bool isPublished;
  final List<String> categories;
  final List<String> tags;
  final String slug;
  final int viewCount;
  
  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.publishedDate,
    this.updatedDate,
    this.thumbnailUrl,
    this.isPublished = true,
    this.categories = const [],
    this.tags = const [],
    required this.slug,
    this.viewCount = 0,
  });
  
  // Create from Firestore document
  factory BlogPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlogPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      publishedDate: (data['publishedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedDate: (data['updatedDate'] as Timestamp?)?.toDate(),
      thumbnailUrl: data['thumbnailUrl'],
      isPublished: data['isPublished'] ?? false,
      categories: List<String>.from(data['categories'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      slug: data['slug'] ?? '',
      viewCount: data['viewCount'] ?? 0,
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'updatedDate': updatedDate != null ? Timestamp.fromDate(updatedDate!) : null,
      'thumbnailUrl': thumbnailUrl,
      'isPublished': isPublished,
      'categories': categories,
      'tags': tags,
      'slug': slug,
      'viewCount': viewCount,
    };
  }
  
  // Helper method to generate slug from title
  static String generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')  // Remove special characters
        .replaceAll(RegExp(r'\s+'), '-')      // Replace spaces with hyphens
        .trim();
  }
  
  // Create a copy with updated fields
  BlogPost copyWith({
    String? id,
    String? title,
    String? content,
    String? author,
    DateTime? publishedDate,
    DateTime? updatedDate,
    String? thumbnailUrl,
    bool? isPublished,
    List<String>? categories,
    List<String>? tags,
    String? slug,
    int? viewCount,
  }) {
    return BlogPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      publishedDate: publishedDate ?? this.publishedDate,
      updatedDate: updatedDate ?? this.updatedDate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isPublished: isPublished ?? this.isPublished,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      slug: slug ?? this.slug,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}