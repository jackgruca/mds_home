import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/widgets/blog/blog_preview_card.dart';

class BlogSection extends StatelessWidget {
  // Expect a list of blog posts
  final List<Map<String, String>> blogPosts;
  final String title;

  const BlogSection({
    super.key,
    required this.blogPosts,
    this.title = 'Latest Insights & Analysis', // Default title
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Placeholder if no posts are provided
    if (blogPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.headlineSmall),
            const SizedBox(height: 20),
            const Center(child: Text('No blog posts available.')),
             const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/blog'),
                  child: const Text('View Blog →'), // Arrow
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.headlineSmall),
          const SizedBox(height: 20),
          ResponsiveLayoutBuilder(
            mobile: (context) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blogPosts.length,
              itemBuilder: (context, index) {
                final post = blogPosts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: BlogPreviewCard(
                    title: post['title']!,
                    excerpt: post['excerpt']!,
                    date: post['date']!,
                    imageUrl: post['imageUrl']!,
                    // Add onTap to navigate to detail screen if route is provided
                    onTap: post.containsKey('route') 
                           ? () => Navigator.pushNamed(context, post['route']!) 
                           : null,
                  ),
                );
              },
            ),
            desktop: (context) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.25,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: blogPosts.length,
              itemBuilder: (context, index) {
                final post = blogPosts[index];
                return BlogPreviewCard(
                  title: post['title']!,
                  excerpt: post['excerpt']!,
                  date: post['date']!,
                  imageUrl: post['imageUrl']!,
                  // Add onTap to navigate to detail screen if route is provided
                   onTap: post.containsKey('route') 
                           ? () => Navigator.pushNamed(context, post['route']!) 
                           : null,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/blog'),
              child: const Text('View All Blog Posts →'), // Arrow
            ),
          ),
        ],
      ),
    );
  }
} 