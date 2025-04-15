// lib/utils/blog_route_handler.dart
import 'package:flutter/material.dart';
import '../models/blog_post.dart';
import '../services/blog_service.dart';
import '../screens/blog_detail_screen.dart';

class BlogRouteHandler {
  // Handle blog post URLs of the form /blog/[slug]
  static Route<dynamic>? handleRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    final pathSegments = uri.pathSegments;
    
    // Check if this is a blog post route
    if (pathSegments.length >= 2 && pathSegments[0] == 'blog') {
      final slug = pathSegments[1];
      
      // This will be a dynamic route that loads the post by slug
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => _BlogPostBySlugScreen(slug: slug),
      );
    }
    
    // Not a blog route, return null to let other route handlers process it
    return null;
  }
}

// Helper screen to load a post by slug
class _BlogPostBySlugScreen extends StatefulWidget {
  final String slug;
  
  const _BlogPostBySlugScreen({required this.slug});
  
  @override
  _BlogPostBySlugScreenState createState() => _BlogPostBySlugScreenState();
}

class _BlogPostBySlugScreenState extends State<_BlogPostBySlugScreen> {
  BlogPost? _post;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPost();
  }
  
  Future<void> _loadPost() async {
    try {
      final post = await BlogService.getPostBySlug(widget.slug);
      
      if (post != null && mounted) {
        // Update view count
        BlogService.incrementViewCount(post.id);
        
        setState(() {
          _post = post;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Not Found')),
        body: const Center(
          child: Text('The requested blog post was not found.'),
        ),
      );
    }
    
    // Render the blog post using the existing detail screen
    return BlogDetailScreen(postId: _post!.id);
  }
}