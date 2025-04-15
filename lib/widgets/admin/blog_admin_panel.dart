// lib/widgets/admin/blog_admin_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/blog_post.dart';
import '../../services/blog_service.dart';
import '../../utils/theme_config.dart';
import 'blog_editor_dialog.dart';

class BlogAdminPanel extends StatefulWidget {
  const BlogAdminPanel({super.key});

  @override
  _BlogAdminPanelState createState() => _BlogAdminPanelState();
}

class _BlogAdminPanelState extends State<BlogAdminPanel> {
  List<BlogPost> _posts = [];
  bool _isLoading = true;
  String? _selectedPostId;
  DocumentSnapshot? _lastDocument;
  bool _hasMorePosts = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get posts without filtering by published status for admin view
      final posts = await BlogService.getPaginatedPosts(
        publishedOnly: false,
        limit: 20,
      );
      
      setState(() {
        _posts = posts;
        _isLoading = false;
        _hasMorePosts = posts.length == 20; // If we got the full page, there might be more
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blog posts: $e')),
        );
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMorePosts || _posts.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get reference to the last document for pagination
      final lastDocId = _posts.last.id;
      final lastDocRef = await FirebaseFirestore.instance
          .collection('blog_posts')
          .doc(lastDocId)
          .get();
      
      final morePosts = await BlogService.getPaginatedPosts(
        publishedOnly: false,
        limit: 20,
        startAfter: lastDocRef,
      );
      
      setState(() {
        _posts.addAll(morePosts);
        _isLoading = false;
        _hasMorePosts = morePosts.length == 20;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more posts: $e')),
        );
      }
    }
  }

  void _createNewPost() {
    showDialog(
      context: context,
      builder: (context) => BlogEditorDialog(
        onSave: (newPost) async {
          final postId = await BlogService.createPost(newPost);
          if (postId != null) {
            _loadPosts(); // Refresh the list
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Blog post created successfully')),
            );
          }
        },
      ),
    );
  }

  void _editPost(BlogPost post) {
    showDialog(
      context: context,
      builder: (context) => BlogEditorDialog(
        post: post,
        onSave: (updatedPost) async {
          final success = await BlogService.updatePost(updatedPost);
          if (success) {
            _loadPosts(); // Refresh the list
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Blog post updated successfully')),
            );
          }
        },
      ),
    );
  }

  Future<void> _togglePublishStatus(BlogPost post) async {
    final newStatus = !post.isPublished;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Publish Post?' : 'Unpublish Post?'),
        content: Text(
          newStatus
              ? 'Are you sure you want to publish this post? It will be visible to all users.'
              : 'Are you sure you want to unpublish this post? It will no longer be visible to users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(newStatus ? 'Publish' : 'Unpublish'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await BlogService.setPublishStatus(post.id, newStatus);
      if (success) {
        _loadPosts(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Post published successfully' : 'Post unpublished successfully',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deletePost(BlogPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await BlogService.deletePost(post.id);
      if (success) {
        _loadPosts(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blog post deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? AppTheme.darkNavy : AppTheme.deepRed.withOpacity(0.1),
            child: Row(
              children: [
                Text(
                  'Blog Posts: ${_posts.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppTheme.deepRed,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _createNewPost,
                  icon: const Icon(Icons.add),
                  label: const Text('New Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No blog posts found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _createNewPost,
                              child: const Text('Create Your First Post'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : TextButton(
                                    onPressed: _loadMorePosts,
                                    child: const Text('Load More'),
                                  );
                          }

                          final post = _posts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                post.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: post.isPublished ? null : Colors.grey,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${post.publishedDate.month}/${post.publishedDate.day}/${post.publishedDate.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                  if (post.categories.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      children: post.categories.map((category) {
                                        return Chip(
                                          label: Text(
                                            category,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      post.isPublished
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: post.isPublished
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    tooltip: post.isPublished ? 'Published' : 'Draft',
                                    onPressed: () => _togglePublishStatus(post),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit',
                                    onPressed: () => _editPost(post),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Delete',
                                    color: Colors.red,
                                    onPressed: () => _deletePost(post),
                                  ),
                                ],
                              ),
                              onTap: () => _editPost(post),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}