import 'dart:js' as js;
import 'package:mds_home/models/blog_post.dart';
import 'package:mds_home/models/player.dart';

class SEOHelper {
  static const String baseUrl = 'https://sticktothemodel.com';
  
  static void updateMetaTags({
    required String title,
    required String description,
    required String url,
  }) {
    try {
      // Check if the function exists before calling it
      if (js.context.hasProperty('updateMetaTags')) {
        js.context.callMethod('updateMetaTags', [title, description, url]);
      } else {
        print('Warning: updateMetaTags function not found in JavaScript context');
      }
    } catch (e) {
      print('Error updating meta tags: $e');
    }
  }

  // HOMEPAGE
  static void updateForHomepage() {
    updateMetaTags(
      title: "NFL Mock Draft Simulator | Fantasy Football Big Board & Analytics | StickToTheModel",
      description: "Advanced NFL mock draft simulator with 300K+ completed drafts, VORP calculations, and fantasy football big board. Create custom rankings, analyze player trends, and dominate your league.",
      url: baseUrl,
    );
  }

  // FANTASY FOOTBALL HUB
  static void updateForFantasyHub() {
    updateMetaTags(
      title: "Fantasy Football Hub | Big Board, Rankings & Mock Draft Tools | StickToTheModel",
      description: "Complete fantasy football toolkit with VORP big board, custom rankings, player comparison tools, and advanced analytics. Build your championship roster with data-driven insights.",
      url: '$baseUrl/fantasy',
    );
  }

  static void updateForBigBoard() {
    updateMetaTags(
      title: "Fantasy Football Big Board | VORP Rankings & Custom Weights | StickToTheModel",
      description: "Advanced fantasy football big board with VORP calculations, custom weight systems, and tier-based rankings. Create personalized player rankings for your league format.",
      url: '$baseUrl/fantasy/big-board',
    );
  }

  static void updateForPlayerComparison() {
    updateMetaTags(
      title: "Fantasy Football Player Comparison Tool | Head-to-Head Stats & Analysis",
      description: "Compare fantasy football players side-by-side with advanced metrics, historical performance, and projection analysis. Make informed draft and trade decisions.",
      url: '$baseUrl/fantasy/player-comparison',
    );
  }

  static void updateForPlayerTrends() {
    updateMetaTags(
      title: "Fantasy Football Player Trends | Rising & Falling Player Analysis",
      description: "Track fantasy football player trends with advanced analytics. Identify breakout candidates and declining players before your competition.",
      url: '$baseUrl/fantasy/trends',
    );
  }

  static void updateForMyRankings() {
    updateMetaTags(
      title: "My Fantasy Football Rankings | Personalized Player Rankings & Big Board",
      description: "Create and manage your personalized fantasy football rankings. Save custom big boards, track your player evaluations, and export cheat sheets.",
      url: '$baseUrl/my-rankings',
    );
  }

  // MOCK DRAFT SIMULATORS
  static void updateForFantasyMockDraft() {
    updateMetaTags(
      title: "Fantasy Football Mock Draft Simulator | Practice Drafts & AI Opponents",
      description: "Free fantasy football mock draft simulator with AI opponents, multiple platform support (ESPN, Yahoo, Sleeper), and real-time analytics. Perfect your draft strategy.",
      url: '$baseUrl/draft/fantasy',
    );
  }

  static void updateForNFLMockDraft() {
    updateMetaTags(
      title: "NFL Mock Draft Simulator | 7-Round Draft with Trades & Analytics",
      description: "Comprehensive NFL mock draft simulator with 7-round drafting, trade logic, team needs analysis, and real-time grading. Simulate the complete NFL draft experience.",
      url: '$baseUrl/draft',
    );
  }

  // GM HUB
  static void updateForGMHub() {
    updateMetaTags(
      title: "GM Hub | NFL Draft Simulator & Team Management Tools | StickToTheModel",
      description: "Complete GM toolkit with NFL mock draft simulator, bust evaluation tools, team builder, and advanced draft analytics. Make decisions like a real NFL general manager.",
      url: '$baseUrl/gm-hub',
    );
  }

  static void updateForBustEvaluation() {
    updateMetaTags(
      title: "NFL Draft Bust Evaluation Tool | Player Analysis & Risk Assessment",
      description: "Evaluate NFL draft picks against expectations with advanced analytics. Identify potential busts and steals before they happen using historical data patterns.",
      url: '$baseUrl/gm-hub/bust-evaluation',
    );
  }

  // DATA EXPLORER
  static void updateForDataExplorer() {
    updateMetaTags(
      title: "NFL Data Explorer | Player Stats, Historical Data & Analytics",
      description: "Comprehensive NFL database with 435K+ plays analyzed, player season stats, historical game data, and advanced analytics. Explore 10M+ data points.",
      url: '$baseUrl/data',
    );
  }

  static void updateForPlayerStats() {
    updateMetaTags(
      title: "NFL Player Season Stats | Comprehensive Statistical Database",
      description: "Complete NFL player statistics database with season stats, advanced metrics, and historical performance data. Search and analyze player performance trends.",
      url: '$baseUrl/player-season-stats',
    );
  }

  static void updateForHistoricalData() {
    updateMetaTags(
      title: "NFL Historical Data | Game Data, Draft History & League Statistics",
      description: "Extensive NFL historical database with game data, draft history, and league statistics spanning multiple seasons. Perfect for research and analysis.",
      url: '$baseUrl/data/historical',
    );
  }

  // RANKINGS SYSTEM
  static void updateForQBRankings() {
    updateMetaTags(
      title: "NFL Quarterback Rankings | Fantasy Football QB Rankings & Analysis",
      description: "Comprehensive NFL quarterback rankings with tier-based analysis, fantasy football projections, and advanced metrics. Find your championship QB.",
      url: '$baseUrl/rankings/qb',
    );
  }

  static void updateForWRRankings() {
    updateMetaTags(
      title: "NFL Wide Receiver Rankings | Fantasy Football WR Rankings & Analysis",
      description: "Advanced NFL wide receiver rankings with EPA analysis, tier calculations, and fantasy football projections. Dominate your WR draft strategy.",
      url: '$baseUrl/rankings/wr',
    );
  }

  static void updateForRBRankings() {
    updateMetaTags(
      title: "NFL Running Back Rankings | Fantasy Football RB Rankings & Analysis",
      description: "Complete NFL running back rankings with rush/receiving metrics, workload analysis, and fantasy projections. Find your workhorse RBs.",
      url: '$baseUrl/rankings/rb',
    );
  }

  static void updateForTERankings() {
    updateMetaTags(
      title: "NFL Tight End Rankings | Fantasy Football TE Rankings & Analysis",
      description: "Comprehensive NFL tight end rankings with target share analysis, red zone usage, and fantasy football projections. Secure your TE advantage.",
      url: '$baseUrl/rankings/te',
    );
  }

  // PROJECTIONS
  static void updateForPlayerProjections() {
    updateMetaTags(
      title: "NFL Player Projections | Fantasy Football Projections & Statistical Forecasts",
      description: "Advanced NFL player projections with statistical forecasting, fantasy football projections, and performance predictions. Data-driven season forecasts.",
      url: '$baseUrl/projections',
    );
  }

  static void updateForStatPredictor() {
    updateMetaTags(
      title: "NFL Player Stat Predictor | Season Statistics Prediction Tool",
      description: "Predict NFL player season statistics with advanced modeling. Forecast rushing yards, receiving stats, touchdowns, and fantasy points.",
      url: '$baseUrl/projections/stat-predictor',
    );
  }

  // BLOG
  static void updateForBlogList() {
    updateMetaTags(
      title: "NFL Draft Blog | Fantasy Football Analysis & Mock Draft Insights",
      description: "Latest NFL draft analysis, fantasy football insights, mock draft breakdowns, and player evaluations. Data-driven content from StickToTheModel experts.",
      url: '$baseUrl/blog',
    );
  }
  
  static void updateForBlogPost(BlogPost post) {
    final url = '$baseUrl/blog/${post.id}';
    updateMetaTags(
      title: "${post.title} | StickToTheModel NFL Analysis",
      description: post.shortDescription,
      url: url,
    );
  }

  // PLAYER-SPECIFIC PAGES
  static void updateForPlayerProfile(Player player) {
    final playerName = player.name ?? 'NFL Player';
    final position = player.position ?? '';
    final college = player.college ?? '';
    
    final title = '$playerName $position Profile | Stats, Analysis & Fantasy Outlook';
    final description = 'Complete $playerName profile with college stats, NFL projection, fantasy football analysis, and draft outlook. ${college.isNotEmpty ? 'Former $college standout' : 'Detailed player breakdown'} with advanced metrics.';
    final url = '$baseUrl/players/${playerName.toLowerCase().replaceAll(' ', '-')}';
    
    updateMetaTags(
      title: title,
      description: description,
      url: url,
    );
  }

  // STRUCTURED DATA HELPERS
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
        "name": "StickToTheModel",
        "logo": {
          "@type": "ImageObject",
          "url": "https://sticktothemodel.com/logo.png"
        }
      },
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": "$baseUrl/blog/${post.id}"
      }
    };
    
    try {
      if (js.context.hasProperty('updateStructuredData')) {
        js.context.callMethod('updateStructuredData', [js.JsObject.jsify(data)]);
      }
    } catch (e) {
      print('Error updating blog structured data: $e');
    }
  }

  static void updatePlayerStructuredData(Player player) {
    final playerName = player.name ?? 'NFL Player';
    final position = player.position ?? '';
    final college = player.college ?? '';
    
    final data = {
      "@context": "https://schema.org",
      "@type": "Person",
      "name": playerName,
      "jobTitle": "$position - NFL Player",
      "description": "NFL $position prospect ${college.isNotEmpty ? 'from $college' : ''} with detailed stats and analysis",
      "sport": "American Football",
      "memberOf": {
        "@type": "SportsTeam",
        "name": college.isNotEmpty ? college : "College Football"
      },
      "url": "$baseUrl/players/${playerName.toLowerCase().replaceAll(' ', '-')}"
    };
    
    try {
      if (js.context.hasProperty('updateStructuredData')) {
        js.context.callMethod('updateStructuredData', [js.JsObject.jsify(data)]);
      }
    } catch (e) {
      print('Error updating player structured data: $e');
    }
  }

  static void updateToolStructuredData({
    required String toolName,
    required String description,
    required String url,
  }) {
    final data = {
      "@context": "https://schema.org",
      "@type": "WebApplication",
      "name": toolName,
      "description": description,
      "url": url,
      "applicationCategory": "Sports Analysis Tool",
      "operatingSystem": "Web Browser",
      "offers": {
        "@type": "Offer",
        "price": "0",
        "priceCurrency": "USD"
      },
      "creator": {
        "@type": "Organization",
        "name": "StickToTheModel",
        "url": baseUrl
      }
    };
    
    try {
      if (js.context.hasProperty('updateStructuredData')) {
        js.context.callMethod('updateStructuredData', [js.JsObject.jsify(data)]);
      }
    } catch (e) {
      print('Error updating tool structured data: $e');
    }
  }

  static void updateRankingsStructuredData({
    required String position,
    required String url,
  }) {
    final data = {
      "@context": "https://schema.org",
      "@type": "Dataset",
      "name": "NFL $position Rankings",
      "description": "Comprehensive NFL $position rankings with advanced analytics and fantasy football projections",
      "url": url,
      "keywords": "NFL, $position, rankings, fantasy football, draft, analytics",
      "creator": {
        "@type": "Organization",
        "name": "StickToTheModel"
      },
      "license": "https://creativecommons.org/licenses/by-nc/4.0/",
      "temporalCoverage": "2024/2025"
    };
    
    try {
      if (js.context.hasProperty('updateStructuredData')) {
        js.context.callMethod('updateStructuredData', [js.JsObject.jsify(data)]);
      }
    } catch (e) {
      print('Error updating rankings structured data: $e');
    }
  }

  // BREADCRUMB HELPERS
  static void updateBreadcrumbs(List<Map<String, String>> breadcrumbs) {
    final breadcrumbList = breadcrumbs.asMap().entries.map((entry) {
      return {
        "@type": "ListItem",
        "position": entry.key + 1,
        "name": entry.value['name'],
        "item": entry.value['url']
      };
    }).toList();

    final data = {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": breadcrumbList
    };
    
    try {
      if (js.context.hasProperty('updateStructuredData')) {
        js.context.callMethod('updateStructuredData', [js.JsObject.jsify(data)]);
      }
    } catch (e) {
      print('Error updating breadcrumbs: $e');
    }
  }

  // FAQ STRUCTURED DATA
  static void updateFAQStructuredData(List<Map<String, String>> faqs) {
    final faqList = faqs.map((faq) {
      return {
        "@type": "Question",
        "name": faq['question'],
        "acceptedAnswer": {
          "@type": "Answer",
          "text": faq['answer']
        }
      };
    }).toList();

    final data = {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      "mainEntity": faqList
    };
    
    try {
      if (js.context.hasProperty('updateStructuredData')) {
        js.context.callMethod('updateStructuredData', [js.JsObject.jsify(data)]);
      }
    } catch (e) {
      print('Error updating FAQ structured data: $e');
    }
  }
}