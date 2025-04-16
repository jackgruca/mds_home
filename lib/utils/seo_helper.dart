import 'dart:js' as js;

import 'package:mds_home/models/blog_post.dart';

class SEOHelper {
  static void updateMetaTags({
    required String title,
    required String description,
    required String url,
  }) {
    js.context.callMethod('updateMetaTags', [title, description, url]);
  }
  
  static void updateForBlogPost(BlogPost post) {
    final url = 'https://sticktothemodel.com/blog/${post.id}';
    updateMetaTags(
      title: "${post.title} | NFL Draft Simulator",
      description: post.shortDescription,
      url: url,
    );
  }
  
  static void updateForBlogList() {
    updateMetaTags(
      title: "NFL Draft Blog | Insights and Analysis",
      description: "Read the latest NFL draft analysis, mock draft comparisons, and scouting reports.",
      url: 'https://sticktothemodel.com/blog',
    );
  }
  
  static void updateForHomepage() {
    updateMetaTags(
      title: "NFL Draft Simulator | Build Your Team",
      description: "Simulate the NFL draft with our free mock draft tool. Make trades, analyze picks, and build your team.",
      url: 'https://sticktothemodel.com',
    );
  }

  // Add this to your SEOHelper class
static void updateBlogPostStructuredData(BlogPost post) {
  final data = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    "headline": post.title,
    "datePublished": post.publishedDate.toIso8601String(),
    "description": post.shortDescription,
    "author": {
      "@type": "Person",
      "name": post.author
    },
    "publisher": {
      "@type": "Organization",
      "name": "NFL Draft Simulator",
      "logo": {
        "@type": "ImageObject",
        "url": "https://sticktothemodel.com/logo.png"
      }
    }
  };
  
  js.context.callMethod('updateStructuredData', [js.JsObject.jsify(data)]);
}
}