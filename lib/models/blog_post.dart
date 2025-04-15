// lib/models/blog_post.dart
class BlogPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime publishedDate;
  final String? thumbnailUrl;
  final bool isPublished;
  
  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.publishedDate,
    this.thumbnailUrl,
    this.isPublished = true,
  });
  
  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      publishedDate: DateTime.parse(json['publishedDate']),
      thumbnailUrl: json['thumbnailUrl'],
      isPublished: json['isPublished'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'publishedDate': publishedDate.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'isPublished': isPublished,
    };
  }
}