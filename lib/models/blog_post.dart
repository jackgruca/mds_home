// lib/models/blog_post.dart
class BlogPost {
  final String id;
  final String title;
  final String shortDescription;
  final String content;
  final String author;
  final DateTime publishedDate;
  final String? thumbnailUrl;
  final List<String> tags;
  final bool isPublished;
  
  BlogPost({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.content,
    required this.author,
    required this.publishedDate,
    this.thumbnailUrl,
    required this.tags,
    this.isPublished = true,
  });
  
  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      title: json['title'],
      shortDescription: json['shortDescription'],
      content: json['content'],
      author: json['author'],
      publishedDate: DateTime.parse(json['publishedDate']),
      thumbnailUrl: json['thumbnailUrl'],
      tags: (json['tags'] as List?)?.map((item) => item.toString()).toList() ?? [],
      isPublished: json['isPublished'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'shortDescription': shortDescription,
      'content': content,
      'author': author,
      'publishedDate': publishedDate.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'tags': tags,
      'isPublished': isPublished,
    };
  }
}