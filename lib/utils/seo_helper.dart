import 'dart:js' as js;
import 'package:mds_home/models/blog_post.dart';
import 'package:mds_home/models/player.dart';

class SEOHelper {
  static const String baseUrl = 'https://sticktothemodel.com';
  
  // SEO Configuration - Update these with actual values
  static const String googleAnalyticsId = 'GA_MEASUREMENT_ID'; // Replace with actual GA4 ID
  static const String googleSearchConsoleVerification = 'YOUR_VERIFICATION_CODE_HERE'; // Replace with actual verification code
  
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
      url: '$baseUrl/big-board',
    );
  }

  static void updateForPlayerComparison() {
    updateMetaTags(
      title: "Fantasy Football Player Comparison Tool | Head-to-Head Stats & Analysis",
      description: "Compare fantasy football players side-by-side with advanced metrics, historical performance, and projection analysis. Make informed draft and trade decisions.",
      url: '$baseUrl/player-comparison',
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
      url: '$baseUrl/mock-draft-simulator',
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
      url: '$baseUrl/stat-predictor',
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
    final school = player.school ?? '';
    
    final title = '$playerName $position Profile | Stats, Analysis & Fantasy Outlook';
    final description = 'Complete $playerName profile with college stats, NFL projection, fantasy football analysis, and draft outlook. ${school.isNotEmpty ? 'Former $school standout' : 'Detailed player breakdown'} with advanced metrics.';
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
    final school = player.school ?? '';
    
    final data = {
      "@context": "https://schema.org",
      "@type": "Person",
      "name": playerName,
      "jobTitle": "$position - NFL Player",
      "description": "NFL $position prospect ${school.isNotEmpty ? 'from $school' : ''} with detailed stats and analysis",
      "sport": "American Football",
      "memberOf": {
        "@type": "SportsTeam",
        "name": school.isNotEmpty ? school : "College Football"
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

  // GOOGLE ANALYTICS HELPERS
  static void trackPageView(String pageName, String pageUrl) {
    try {
      if (js.context.hasProperty('gtag')) {
        js.context.callMethod('gtag', ['event', 'page_view', {
          'page_title': pageName,
          'page_location': pageUrl,
        }]);
      }
    } catch (e) {
      print('Error tracking page view: $e');
    }
  }

  static void trackToolUsage(String toolName, String action) {
    try {
      if (js.context.hasProperty('gtag')) {
        js.context.callMethod('gtag', ['event', action, {
          'event_category': 'Tool Usage',
          'event_label': toolName,
        }]);
      }
    } catch (e) {
      print('Error tracking tool usage: $e');
    }
  }

  static void trackMockDraftEvent(String eventType, Map<String, dynamic> parameters) {
    try {
      if (js.context.hasProperty('gtag')) {
        final eventData = {
          'event_category': 'Mock Draft',
          'event_label': eventType,
          ...parameters,
        };
        js.context.callMethod('gtag', ['event', 'mock_draft_action', eventData]);
      }
    } catch (e) {
      print('Error tracking mock draft event: $e');
    }
  }

  // INTERNAL LINKING HELPERS
  static List<Map<String, String>> getRelatedTools(String currentTool) {
    final relatedToolsMap = {
      'big-board': [
        {'title': 'Fantasy Mock Draft Simulator', 'url': '/mock-draft-simulator', 'description': 'Practice your draft strategy'},
        {'title': 'Player Comparison Tool', 'url': '/player-comparison', 'description': 'Compare players head-to-head'},
        {'title': 'My Rankings', 'url': '/my-rankings', 'description': 'Create custom rankings'},
      ],
      'mock-draft': [
        {'title': 'Fantasy Big Board', 'url': '/big-board', 'description': 'VORP-based player rankings'},
        {'title': 'Player Trends', 'url': '/fantasy/trends', 'description': 'Trending players analysis'},
        {'title': 'QB Rankings', 'url': '/rankings/qb', 'description': 'Quarterback tier rankings'},
      ],
      'player-comparison': [
        {'title': 'Fantasy Big Board', 'url': '/big-board', 'description': 'See where players rank'},
        {'title': 'Player Stats Database', 'url': '/player-season-stats', 'description': 'Historical player data'},
        {'title': 'Player Trends', 'url': '/fantasy/trends', 'description': 'Rising and falling players'},
      ],
      'rankings': [
        {'title': 'Fantasy Big Board', 'url': '/big-board', 'description': 'VORP-based consensus rankings'},
        {'title': 'Mock Draft Simulator', 'url': '/mock-draft-simulator', 'description': 'Test your draft strategy'},
        {'title': 'Player Comparison', 'url': '/player-comparison', 'description': 'Compare players side-by-side'},
      ],
      'bust-evaluation': [
        {'title': 'NFL Mock Draft Simulator', 'url': '/draft', 'description': 'Full 7-round NFL draft'},
        {'title': 'Historical Data Explorer', 'url': '/data/historical', 'description': 'NFL historical data'},
        {'title': 'Player Stats Database', 'url': '/player-season-stats', 'description': 'Comprehensive player stats'},
      ],
    };

    return relatedToolsMap[currentTool] ?? [];
  }

  static List<Map<String, String>> getPositionLinks() {
    return [
      {'title': 'QB Rankings', 'url': '/rankings/qb', 'description': 'Quarterback tier rankings'},
      {'title': 'WR Rankings', 'url': '/rankings/wr', 'description': 'Wide receiver analysis'},
      {'title': 'RB Rankings', 'url': '/rankings/rb', 'description': 'Running back projections'},
      {'title': 'TE Rankings', 'url': '/rankings/te', 'description': 'Tight end evaluations'},
    ];
  }

  static List<Map<String, String>> getHubLinks() {
    return [
      {'title': 'Fantasy Hub', 'url': '/fantasy', 'description': 'Fantasy football tools and rankings'},
      {'title': 'GM Hub', 'url': '/gm-hub', 'description': 'NFL GM simulation tools'},
      {'title': 'Data Explorer', 'url': '/data', 'description': 'NFL statistics and historical data'},
    ];
  }

  // FAQ DATA FOR COMPLEX TOOLS
  static List<Map<String, String>> getVORPFAQs() {
    return [
      {
        'question': 'What is VORP in fantasy football?',
        'answer': 'VORP (Value Over Replacement Player) measures how much more valuable a player is compared to a replacement-level player at the same position. It helps identify which players provide the most value relative to what you could get from free agents or late draft picks.'
      },
      {
        'question': 'How is VORP calculated?',
        'answer': 'VORP is calculated by taking a player\'s projected fantasy points and subtracting the projected points of a replacement-level player at that position. The replacement level is typically set at the point where players become widely available (usually around the top 24 players per position).'
      },
      {
        'question': 'Why should I use VORP for fantasy football drafts?',
        'answer': 'VORP helps you identify the most valuable picks at each draft position. Players with high VORP scores provide more advantage over replacement options, making them better draft targets than players who may score more points but are easily replaceable.'
      },
      {
        'question': 'How does position scarcity affect VORP?',
        'answer': 'Positions with fewer quality options (like tight end) often have higher VORP values for top players because the drop-off to replacement level is steeper. This is why elite TEs often have surprisingly high VORP despite lower raw point totals.'
      },
      {
        'question': 'Can I customize VORP calculations for my league?',
        'answer': 'Yes! Our VORP calculator allows you to adjust scoring settings, roster requirements, and league size to generate personalized VORP values that match your specific league format and scoring system.'
      }
    ];
  }

  static List<Map<String, String>> getBigBoardFAQs() {
    return [
      {
        'question': 'What is a fantasy football big board?',
        'answer': 'A big board is a comprehensive ranking of all fantasy-relevant players regardless of position, ordered by their overall value. It helps you identify the best available player at any point in your draft, accounting for positional value and scarcity.'
      },
      {
        'question': 'How do I use custom weights in the big board?',
        'answer': 'Custom weights allow you to adjust how much emphasis is placed on different statistics and metrics. For example, you can increase the weight of rushing yards for RBs or target share for WRs to match your league\'s scoring system and your personal preferences.'
      },
      {
        'question': 'What\'s the difference between consensus and custom rankings?',
        'answer': 'Consensus rankings aggregate expert opinions from multiple sources to create an average ranking. Custom rankings use our advanced algorithms with your personalized weight settings to create rankings tailored to your specific league format and strategy.'
      },
      {
        'question': 'How often are big board rankings updated?',
        'answer': 'Our big board is updated daily during the season and multiple times per week during the offseason. Rankings incorporate the latest news, injury reports, depth chart changes, and statistical performance to keep your draft strategy current.'
      },
      {
        'question': 'Can I export my big board for draft day?',
        'answer': 'Yes! You can export your customized big board as a printable cheat sheet or CSV file. This lets you take your personalized rankings into any draft platform or use them for offline drafts.'
      }
    ];
  }

  static List<Map<String, String>> getMockDraftFAQs() {
    return [
      {
        'question': 'How realistic are the AI opponents in mock drafts?',
        'answer': 'Our AI opponents are trained on thousands of real draft data points and use current ADP (Average Draft Position) data to make realistic picks. They account for team needs, positional runs, and draft trends to simulate authentic draft behavior.'
      },
      {
        'question': 'Can I practice drafts for different platforms?',
        'answer': 'Yes! Our mock draft simulator supports various league formats including ESPN, Yahoo, Sleeper, and custom scoring systems. You can practice for your specific platform and scoring rules to perfect your strategy.'
      },
      {
        'question': 'What draft positions and league sizes are available?',
        'answer': 'You can practice from any draft position (1-20) in leagues ranging from 8 to 20 teams. This covers standard leagues (10-12 teams), competitive leagues (14+ teams), and dynasty formats with larger rosters.'
      },
      {
        'question': 'How do I analyze my mock draft results?',
        'answer': 'After each mock draft, you receive a detailed grade breaking down your team\'s projected performance, positional strength, value picks, and areas for improvement. Use this feedback to refine your draft strategy.'
      },
      {
        'question': 'Can I save and share my mock draft results?',
        'answer': 'Yes! You can save your draft results to track your improvement over time and share your teams with friends or league mates. This helps you identify patterns in your drafting and optimize your strategy.'
      }
    ];
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