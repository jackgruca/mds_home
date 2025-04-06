// lib/screens/blog/blog_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/blog_post.dart';
import '../../services/blog_service.dart';
import '../../widgets/blog/blog_card.dart';

class BlogDetailScreen extends StatefulWidget {
  final String postId;
  final String? slug;

  const BlogDetailScreen({
    super.key,
    required this.postId,
    this.slug,
  });

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final BlogService _blogService = BlogService();
  BlogPost? _post;
  List<BlogPost> _relatedPosts = [];
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
      BlogPost? post;
      
      // Load by ID or slug
      if (widget.slug != null) {
        post = await _blogService.getBlogPostBySlug(widget.slug!);
      } else {
        post = await _blogService.getBlogPost(widget.postId);
      }
      
      if (post != null) {
        // Increment view count
        _blogService.incrementViews(post.id);
        
        // Load related posts by first tag
        if (post.tags.isNotEmpty) {
          final relatedPosts = await _blogService.getBlogPosts(
            tag: post.tags.first,
            limit: 4,
          );
          
          // Filter out the current post
          _relatedPosts = relatedPosts.where((p) => p.id != post!.id).toList();
        }
        
        setState(() {
          _post = post;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading blog post: $e');
    }
  }

  void _sharePost() {
    if (_post != null) {
      final url = 'https://yourdomain.com/blog/${_post!.slug}';
      Share.share('${_post!.title}\n$url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMMM d, yyyy');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Post not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePost,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image
            if (_post!.imageUrl != null)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.network(
                  _post!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: _post!.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade800,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    _post!.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Date and author
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, 
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(_post!.publishedDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                       ),
                     ),
                     if (_post!.author != null) ...[
                       const SizedBox(width: 16),
                       Icon(Icons.person, size: 14,
                           color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                       const SizedBox(width: 4),
                       Text(
                         _post!.author!,
                         style: TextStyle(
                           fontSize: 14,
                           color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                         ),
                       ),
                     ],
                   ],
                 ),
                 
                 const Divider(height: 32),
                 
                 // Content
                 Html(
                   data: _post!.content,
                   style: {
                     "body": Style(
                       fontSize: FontSize(16),
                       lineHeight: const LineHeight(1.6),
                     ),
                     "h1": Style(
                       fontSize: FontSize(22),
                       fontWeight: FontWeight.bold,
                       margin: Margins.only(bottom: 16, top: 24),
                     ),
                     "h2": Style(
                       fontSize: FontSize(20),
                       fontWeight: FontWeight.bold,
                       margin: Margins.only(bottom: 12, top: 20),
                     ),
                     "h3": Style(
                       fontSize: FontSize(18),
                       fontWeight: FontWeight.bold,
                       margin: Margins.only(bottom: 8, top: 16),
                     ),
                     "p": Style(
                       margin: Margins.only(bottom: 16),
                     ),
                     "ul": Style(
                       margin: Margins.only(bottom: 16),
                     ),
                     "ol": Style(
                       margin: Margins.only(bottom: 16),
                     ),
                     "img": Style(
                       margin: Margins.symmetric(vertical: 16),
                     ),
                     "a": Style(
                       color: Colors.blue,
                       textDecoration: TextDecoration.none,
                     ),
                   },
                 ),
                 
                 // Related posts
                 if (_relatedPosts.isNotEmpty) ...[
                   const Divider(height: 32),
                   
                   const Text(
                     'Related Posts',
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 18,
                     ),
                   ),
                   const SizedBox(height: 16),
                   
                   // Related posts cards
                   ListView.builder(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: _relatedPosts.length,
                     itemBuilder: (context, index) {
                       final post = _relatedPosts[index];
                       return BlogCard(
                         post: post,
                         onTap: () {
                           Navigator.pushReplacement(
                             context,
                             MaterialPageRoute(
                               builder: (context) => BlogDetailScreen(postId: post.id),
                             ),
                           );
                         },
                         isHorizontal: true,
                       );
                     },
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