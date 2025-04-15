// lib/utils/sitemap_generator.dart
import 'dart:convert';
import 'dart:io';
import '../models/blog_post.dart';
import '../services/blog_service.dart';

class SitemapGenerator {
  static const String baseUrl = 'https://yourdomain.com';
  
  static Future<String> generateSitemap() async {
    final blogPosts = await BlogService.getAllPosts();
    
    final StringBuffer sitemap = StringBuffer();
    sitemap.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sitemap.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    
    // Add homepage
    sitemap.writeln('  <url>');
    sitemap.writeln('    <loc>$baseUrl</loc>');
    sitemap.writeln('    <changefreq>weekly</changefreq>');
    sitemap.writeln('    <priority>1.0</priority>');
    sitemap.writeln('  </url>');
    
    // Add blog index page
    sitemap.writeln('  <url>');
    sitemap.writeln('    <loc>$baseUrl/blog</loc>');
    sitemap.writeln('    <changefreq>daily</changefreq>');
    sitemap.writeln('    <priority>0.8</priority>');
    sitemap.writeln('  </url>');
    
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
}