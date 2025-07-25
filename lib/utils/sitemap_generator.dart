// lib/utils/sitemap_generator.dart
import 'dart:io';
import '../services/blog_service.dart';

class SitemapGenerator {
  static const String baseUrl = 'https://sticktothemodel.com';
  
  // Define all static routes with their properties
  static final List<Map<String, dynamic>> staticRoutes = [
    // Homepage - Highest priority
    {'url': '', 'changefreq': 'weekly', 'priority': 1.0},
    
    // Main Hubs - High priority
    {'url': '/fantasy', 'changefreq': 'daily', 'priority': 0.9},
    {'url': '/gm-hub', 'changefreq': 'daily', 'priority': 0.9},
    {'url': '/data', 'changefreq': 'daily', 'priority': 0.9},
    
    // Fantasy Hub Tools - High priority for SEO
    {'url': '/fantasy/big-board', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/fantasy/player-comparison', 'changefreq': 'weekly', 'priority': 0.8},
    {'url': '/fantasy/trends', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/my-rankings', 'changefreq': 'weekly', 'priority': 0.7},
    {'url': '/fantasy/custom-rankings', 'changefreq': 'weekly', 'priority': 0.7},
    
    // Mock Draft Simulators - Core functionality
    {'url': '/draft', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/draft/fantasy', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/mock-draft-sim', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/mock-draft-sim/setup', 'changefreq': 'weekly', 'priority': 0.6},
    
    // GM Hub Tools
    {'url': '/gm-hub/bust-evaluation', 'changefreq': 'weekly', 'priority': 0.7},
    
    // Rankings Pages - Important for SEO
    {'url': '/rankings', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/rankings/qb', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/rankings/wr', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/rankings/rb', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/rankings/te', 'changefreq': 'daily', 'priority': 0.8},
    {'url': '/rankings/ol', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/rankings/dl', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/rankings/lb', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/rankings/secondary', 'changefreq': 'weekly', 'priority': 0.6},
    
    // Projections & Analytics
    {'url': '/projections', 'changefreq': 'weekly', 'priority': 0.7},
    {'url': '/projections/wr-2025', 'changefreq': 'weekly', 'priority': 0.7},
    {'url': '/projections/stat-predictor', 'changefreq': 'weekly', 'priority': 0.7},
    
    // Data Explorer Pages
    {'url': '/data/passing', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/data/rushing', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/data/receiving', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/data/fantasy', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/data/historical', 'changefreq': 'monthly', 'priority': 0.6},
    {'url': '/player-season-stats', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/historical-data', 'changefreq': 'monthly', 'priority': 0.5},
    {'url': '/historical-game-data', 'changefreq': 'monthly', 'priority': 0.5},
    {'url': '/wr-model', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/nfl-rosters', 'changefreq': 'weekly', 'priority': 0.6},
    {'url': '/depth-charts', 'changefreq': 'weekly', 'priority': 0.6},
    
    // VORP and Advanced Tools
    {'url': '/vorp/my-rankings', 'changefreq': 'weekly', 'priority': 0.7},
    
    // Blog
    {'url': '/blog', 'changefreq': 'daily', 'priority': 0.8},
  ];
  
  static Future<String> generateSitemap() async {
    final blogPosts = await BlogService.getAllPosts();
    
    final StringBuffer sitemap = StringBuffer();
    sitemap.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sitemap.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    
    // Add all static routes
    for (final route in staticRoutes) {
      sitemap.writeln('  <url>');
      sitemap.writeln('    <loc>$baseUrl${route['url']}</loc>');
      sitemap.writeln('    <changefreq>${route['changefreq']}</changefreq>');
      sitemap.writeln('    <priority>${route['priority']}</priority>');
      sitemap.writeln('  </url>');
    }
    
    // Add individual blog posts
    for (final post in blogPosts) {
      if (post.isPublished) {
        sitemap.writeln('  <url>');
        sitemap.writeln('    <loc>$baseUrl/blog/${post.id}</loc>');
        sitemap.writeln('    <lastmod>${post.publishedDate.toIso8601String().substring(0, 10)}</lastmod>');
        sitemap.writeln('    <changefreq>monthly</changefreq>');
        sitemap.writeln('    <priority>0.6</priority>');
        sitemap.writeln('  </url>');
      }
    }
    
    sitemap.writeln('</urlset>');
    return sitemap.toString();
  }
  
  static Future<void> writeSitemapToFile(String outputPath) async {
    final sitemap = await generateSitemap();
    final file = File(outputPath);
    await file.writeAsString(sitemap);
  }
  
  static Future<void> main() async {
    final sitemap = await SitemapGenerator.generateSitemap();
    final file = File('web/sitemap.xml');
    await file.writeAsString(sitemap);
  }
}