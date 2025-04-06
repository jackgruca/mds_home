// lib/widgets/blog/featured_blog_slider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/blog_post.dart';

class FeaturedBlogSlider extends StatefulWidget {
  final List<BlogPost> featuredPosts;
  final Function(BlogPost) onPostTap;

  const FeaturedBlogSlider({
    super.key,
    required this.featuredPosts,
    required this.onPostTap,
  });

  @override
  _FeaturedBlogSliderState createState() => _FeaturedBlogSliderState();
}

class _FeaturedBlogSliderState extends State<FeaturedBlogSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.featuredPosts.isEmpty) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('MMM d, yyyy');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // PageView for slides
          PageView.builder(
            controller: _pageController,
            itemCount: widget.featuredPosts.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final post = widget.featuredPosts[index];
              return GestureDetector(
                onTap: () => widget.onPostTap(post),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Featured image
                    post.imageUrl != null
                        ? Image.network(
                            post.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.article, size: 40),
                          ),
                    
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    
                    // Content overlay
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Tags
                          if (post.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                post.tags.first,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          
                          // Title
                          Text(
                            post.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Date & views
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(post.publishedDate),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.visibility, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                '${post.views}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Pagination indicators
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: List.generate(
                widget.featuredPosts.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}