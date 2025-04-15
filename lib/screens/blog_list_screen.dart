// lib/screens/blog_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog_post.dart';
import '../services/blog_service.dart';
import '../utils/theme_config.dart';
import 'blog_detail_screen.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  _BlogListScreenState createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<BlogPost> _posts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPosts();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore && 
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await BlogService.getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      if (refresh) {
        _posts = [];
        _lastDocument = null;
        _hasMorePosts = true;
      }
    });

    try {
      List<String>? categoryFilter;
      if (_selectedCategory != null) {
        categoryFilter = [_selectedCategory!];
      }
      
      final posts = await BlogService.getPaginatedPosts(
        limit: 10,
        categories: categoryFilter,
      );
      
      if (posts.isNotEmpty) {
        final lastId = posts.last.id;
        final lastDocRef = await FirebaseFirestore.instance
            .collection('blog_posts')
            .doc(lastId)
            .get();
        
        setState(() {
          _posts = posts;
          _lastDocument = lastDocRef;
          _hasMorePosts = posts.length == 10; // If we got the full page, there might be more
          _isLoading = false;
        });
      } else {
        setState(() {
          _posts = [];
          _hasMorePosts = false;
          _isLoading = false;
        });
      }
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
    if (!_hasMorePosts || _loadingMore || _lastDocument == null) return;
    
    setState(() {
      _loadingMore = true;
    });

    try {
      List<String>? categoryFilter;
      if (_selectedCategory != null) {
        categoryFilter = [_selectedCategory!];
      }
      
      final morePosts = await BlogService.getPaginatedPosts(
        limit: 10,
        startAfter: _lastDocument,
        categories: categoryFilter,
      );
      
      if (morePosts.isNotEmpty) {
        final lastId = morePosts.last.id;
        final lastDocRef = await FirebaseFirestore.instance
            .collection('blog_posts')
            .doc(lastId)
            .get();
        
        setState(() {
          _posts.addAll(morePosts);
          _lastDocument = lastDocRef;
          _hasMorePosts = morePosts.length == 10; // If we got the full page, there might be more
          _loadingMore = false;
        });
      } else {
        setState(() {
          _hasMorePosts = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more posts: $e')),
        );
      }
    }
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Draft Blog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadPosts(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories filter
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // All categories option
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        if (selected) {
                          _selectCategory(null);
                        }
                      },
                    ),
                  ),
                  // Individual categories
                  ..._categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          if (selected) {
                            _selectCategory(category);
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          
          // Posts list
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
                              _selectedCategory == null
                                  ? 'No blog posts found'
                                  : 'No posts found in category "$_selectedCategory"',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                            if (_selectedCategory != null) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _selectCategory(null),
                                child: const Text('Show All Posts'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return _loadingMore
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }

                          final post = _posts[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlogDetailScreen(postId: post.id),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post.thumbnailUrl != null) ...[
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      child: Image.network(
                                        post.thumbnailUrl!,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 180,
                                          color: isDarkMode ? AppTheme.darkNavy : AppTheme.deepRed.withOpacity(0.1),
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                            ),
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
                                          post.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 16,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              post.author,
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
                                              '${post.publishedDate.month}/${post.publishedDate.day}/${post.publishedDate.year}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (post.categories.isNotEmpty) ...[
                                          const SizedBox(height: 8),
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
                                        const SizedBox(height: 12),
                                        Text(
                                          post.content.length > 150
                                              ? '${post.content.substring(0, 150)}...'
                                              : post.content,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Read More',
                                          style: TextStyle(
                                            color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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