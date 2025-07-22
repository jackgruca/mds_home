import 'dart:io';

// Simple sitemap generator without dependencies
void main() async {
  final StringBuffer sitemap = StringBuffer();
  sitemap.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  sitemap.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
  
  final baseUrl = 'https://sticktothemodel.com';
  
  // Define all static routes with their properties
  final List<Map<String, dynamic>> routes = [
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
  
  // Add all static routes
  for (final route in routes) {
    sitemap.writeln('  <url>');
    sitemap.writeln('    <loc>$baseUrl${route['url']}</loc>');
    sitemap.writeln('    <changefreq>${route['changefreq']}</changefreq>');
    sitemap.writeln('    <priority>${route['priority']}</priority>');
    sitemap.writeln('  </url>');
  }
  
  sitemap.writeln('</urlset>');
  
  final file = File('web/sitemap.xml');
  await file.writeAsString(sitemap.toString());
  print('✅ Sitemap generated successfully at web/sitemap.xml');
  print('📊 Generated ${routes.length} URLs');
}