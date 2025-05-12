// lib/screens/blog_detail_screen.dart 
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mds_home/utils/seo_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/blog_post.dart';
import '../../services/blog_service.dart';
import '../../utils/theme_config.dart';

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
    if (_post != null) {
    SEOHelper.updateForBlogPost(_post!);
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
                            const SizedBox(height: 24),
                            MarkdownBody(
  data: _post!.content,
  styleSheet: MarkdownStyleSheet(
    p: const TextStyle(fontSize: 16, height: 1.6),
    h1: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.black,
    ),
    h2: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.black,
    ),
    h3: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.black,
    ),
    code: TextStyle(
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      fontFamily: 'monospace',
    ),
    blockquote: TextStyle(
      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
      fontStyle: FontStyle.italic,
    ),
    listBullet: TextStyle(
      color: isDarkMode ? Colors.white : Colors.black,
    ),
  ),
  selectable: true, // Makes text selectable
  onTapLink: (text, href, title) async {
  if (href != null) {
    final uri = Uri.parse(href);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
},
),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}