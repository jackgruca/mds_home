// lib/screens/blog_detail_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:mds_home/utils/seo_manager.dart';
import 'package:mds_home/widgets/blog/rich_text_renderer.dart';
import '../models/blog_post.dart';
import '../services/blog_service.dart';
import '../utils/theme_config.dart';
import '../widgets/blog/related_posts_widget.dart';
import 'tag_results_screen.dart';

class BlogDetailScreen extends StatefulWidget {
  final String postId;

  const BlogDetailScreen({super.key, required this.postId});

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogPost? _post;
  bool _isLoading = true;
  List<BlogPost> _relatedPosts = [];
  List<BlogPost> _popularPosts = [];
  bool _loadingRelated = false;

  @override
  void initState() {
    super.initState();
    _loadPost().then((_) {
      if (_post != null) {
        _loadRelatedPosts();
      }
    });
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
    });

    // Add this to the _loadPost method after loading the post
    if (kIsWeb) {
      // Update SEO metadata for this post
      SEOManager.updateBlogPostMetadata(post as BlogPost);
    }
    
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
                            _post!.isRichContent
                              ? RichTextRenderer(
                                  content: _post!.content,
                                  isRichContent: true,
                                )
                              : Text(
                                  _post!.content,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),

                                // After the main content, add:
if (_post != null) ...[
  const SizedBox(height: 40),
  const Divider(),
  const SizedBox(height: 24),
  
  // Show related posts if available
  if (_relatedPosts.isNotEmpty) ...[
    RelatedPostsWidget(
      posts: _relatedPosts,
      title: 'Related Posts',
    ),
    const SizedBox(height: 32),
  ],
  
  // Show popular posts if available
  if (_popularPosts.isNotEmpty) ...[
    RelatedPostsWidget(
      posts: _popularPosts,
      title: 'Popular Posts',
    ),
    const SizedBox(height: 24),
  ],
  
  // Show loading indicator if still loading
  if (_loadingRelated)
    const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    ),
],
                            
                            // Tags
                            if (_post!.tags.isNotEmpty) ...[
  const SizedBox(height: 24),
  const Divider(),
  const SizedBox(height: 8),
  const Text(
    'Tags:',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 8),
  Wrap(
    spacing: 4,
    runSpacing: 4,
    children: _post!.tags.map((tag) {
      return ActionChip(
        label: Text('#$tag'),
        backgroundColor: isDarkMode
            ? Colors.grey.shade800
            : Colors.grey.shade200,
        onPressed: () => _onTagSelected(tag),
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

  Future<void> _loadRelatedPosts() async {
  if (_post == null) return;
  
  setState(() {
    _loadingRelated = true;
  });
  
  try {
    // Fetch related posts
    final related = await BlogService.getRelatedPosts(
      postId: _post!.id,
      categories: _post!.categories,
      tags: _post!.tags,
      limit: 3,
    );
    
    // Fetch popular posts
    final popular = await BlogService.getPopularPosts(limit: 3);
    
    if (mounted) {
      setState(() {
        _relatedPosts = related;
        _popularPosts = popular.where((p) => p.id != _post!.id).toList();
        _loadingRelated = false;
      });
    }
  } catch (e) {
    debugPrint('Error loading related posts: $e');
    if (mounted) {
      setState(() {
        _loadingRelated = false;
      });
    }
  }
}
void _onTagSelected(String tag) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TagResultsScreen(tag: tag),
    ),
  );
}

}