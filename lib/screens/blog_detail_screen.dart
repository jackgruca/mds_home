// lib/screens/blog_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/blog_post.dart';
import '../services/blog_service.dart';
import '../utils/theme_config.dart';

class BlogDetailScreen extends StatefulWidget {
  final String postId;

  const BlogDetailScreen({super.key, required this.postId});

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogPost? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final post = await BlogService.getPostById(widget.postId);
      
      if (post != null) {
        // Increment view count
        BlogService.incrementViewCount(widget.postId);
      }
      
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blog post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading...' : (_post?.title ?? 'Blog Post')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Blog post not found',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_post!.thumbnailUrl != null) ...[
                        Image.network(
                          _post!.thumbnailUrl!,
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 240,
                            color: isDarkMode ? AppTheme.darkNavy : AppTheme.deepRed.withOpacity(0.1),
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _post!.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _post!.author,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_post!.publishedDate.month}/${_post!.publishedDate.day}/${_post!.publishedDate.year}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_post!.categories.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 4,
                                children: _post!.categories.map((category) {
                                  return Chip(
                                    label: Text(category),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            // Main content
                            Text(
                              _post!.content,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            
                            // Tags
                            if (_post!.tags.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: _post!.tags.map((tag) {
                                  return Chip(
                                    label: Text(
                                      '#$tag',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}