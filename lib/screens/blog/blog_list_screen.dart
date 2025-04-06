// lib/screens/blog/blog_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/blog_post.dart';
import '../../services/blog_service.dart';
import '../../widgets/blog/blog_card.dart';
import '../../widgets/blog/featured_blog_slider.dart';
import 'blog_detail_screen.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  _BlogListScreenState createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final BlogService _blogService = BlogService();
  List<BlogPost> _blogPosts = [];
  List<BlogPost> _featuredPosts = [];
  List<String> _tags = [];
  String? _selectedTag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tags = await _blogService.getTags();
      final featuredPosts = await _blogService.getBlogPosts(featuredOnly: true, limit: 5);
      final posts = await _blogService.getBlogPosts(
        tag: _selectedTag,
        limit: 20,
      );

      setState(() {
        _tags = tags;
        _featuredPosts = featuredPosts;
        _blogPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading blog data: $e');
    }
  }

  void _navigateToDetail(BlogPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogDetailScreen(postId: post.id),
      ),
    ).then((_) {
      // Refresh data when returning from detail page
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Blog')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Featured posts slider
            if (_featuredPosts.isNotEmpty)
              SliverToBoxAdapter(
                child: FeaturedBlogSlider(
                  featuredPosts: _featuredPosts,
                  onPostTap: _navigateToDetail,
                ),
              ),

            // Tags filter
            SliverToBoxAdapter(
              child: Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // All posts filter
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedTag == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTag = null;
                              _loadData();
                            });
                          }
                        },
                      ),
                    ),
                    
                    // Tags filters
                    ..._tags.map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag),
                        selected: _selectedTag == tag,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTag = selected ? tag : null;
                            _loadData();
                          });
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ),

            // Blog posts grid
            if (_blogPosts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No posts found'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = _blogPosts[index];
                      return BlogCard(
                        post: post,
                        onTap: () => _navigateToDetail(post),
                      );
                    },
                    childCount: _blogPosts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}