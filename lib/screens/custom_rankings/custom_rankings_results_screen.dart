import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/services/custom_rankings/enhanced_calculation_engine.dart';
import 'package:mds_home/services/custom_rankings/ranking_export_service.dart';
import '../../widgets/custom_rankings/results/ranking_table_widget.dart';
import '../../widgets/custom_rankings/results/ranking_analysis_widget.dart';
import '../../widgets/custom_rankings/results/attribute_impact_widget.dart';
import '../../widgets/custom_rankings/adjustments/real_time_adjustment_widget.dart';

class CustomRankingsResultsScreen extends StatefulWidget {
  final String position;
  final List<EnhancedRankingAttribute> attributes;
  final String rankingName;
  final List<CustomRankingResult> results;

  const CustomRankingsResultsScreen({
    super.key,
    required this.position,
    required this.attributes,
    required this.rankingName,
    required this.results,
  });

  @override
  State<CustomRankingsResultsScreen> createState() => _CustomRankingsResultsScreenState();
}

class _CustomRankingsResultsScreenState extends State<CustomRankingsResultsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<RankingAnalysis> _analysisFuture;
  late Future<List<AttributeImpact>> _impactFuture;
  
  // Current state for real-time updates
  late List<CustomRankingResult> _currentResults;
  late List<EnhancedRankingAttribute> _currentAttributes;
  bool _showAdjustments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize current state
    _currentResults = List.from(widget.results);
    _currentAttributes = List.from(widget.attributes);
    
    _updateAnalysis();
  }
  
  void _updateAnalysis() {
    final engine = EnhancedCalculationEngine();
    _analysisFuture = engine.analyzeRankings(_currentResults);
    _impactFuture = engine.analyzeAttributeImpact(_currentResults, _currentAttributes);
  }
  
  void _onRankingsUpdated(List<CustomRankingResult> newResults, List<EnhancedRankingAttribute> newAttributes) {
    setState(() {
      _currentResults = newResults;
      _currentAttributes = newAttributes;
    });
    _updateAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rankingName.isNotEmpty 
            ? widget.rankingName 
            : 'Custom ${widget.position} Rankings'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            onSelected: _shareRankings,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'methodology',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Share Methodology'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'url',
                child: Row(
                  children: [
                    Icon(Icons.link),
                    SizedBox(width: 8),
                    Text('Copy Results Link'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: _exportRankings,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export to CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 8),
                    Text('Export to JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'html',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Generate Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rankings', icon: Icon(Icons.list)),
            Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
            Tab(text: 'Attributes', icon: Icon(Icons.tune)),
            Tab(text: 'Adjust', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: ResponsiveLayoutBuilder(
        mobile: (context) => _buildMobileLayout(),
        desktop: (context) => _buildDesktopLayout(),
      ),
      floatingActionButton: ResponsiveLayoutBuilder(
        mobile: (context) => FloatingActionButton(
          onPressed: () => _adjustWeights(),
          backgroundColor: ThemeConfig.darkNavy,
          foregroundColor: Colors.white,
          child: const Icon(Icons.tune),
        ),
        desktop: (context) => FloatingActionButton.extended(
          onPressed: () => _adjustWeights(),
          icon: const Icon(Icons.tune),
          label: const Text('Adjust Weights'),
          backgroundColor: ThemeConfig.darkNavy,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSummaryHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRankingsTab(),
              _buildAnalysisTab(),
              _buildAttributesTab(),
              _buildAdjustmentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildSummaryHeader(),
              Expanded(child: _buildRankingsTab()),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Analysis'),
                    Tab(text: 'Attributes'),
                    Tab(text: 'Adjust'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAnalysisTab(),
                      _buildAttributesTab(),
                      _buildAdjustmentsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.darkNavy.withValues(alpha: 0.1),
            ThemeConfig.gold.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sports_football,
            size: 32,
            color: ThemeConfig.darkNavy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.position} Rankings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currentResults.length} players • ${_currentAttributes.length} attributes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<RankingAnalysis>(
            future: _analysisFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final analysis = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Quality: ${analysis.hasGoodSeparation && analysis.isWellDistributed ? 'Excellent' : 'Good'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: analysis.hasGoodSeparation && analysis.isWellDistributed 
                            ? ThemeConfig.successGreen 
                            : ThemeConfig.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tiers: ${analysis.hasGoodSeparation ? 'Clear' : 'Similar'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsTab() {
    return RankingTableWidget(
      results: _currentResults,
      attributes: _currentAttributes,
      onPlayerTap: (result) => _showPlayerDetails(result),
    );
  }

  Widget _buildAnalysisTab() {
    return FutureBuilder<RankingAnalysis>(
      future: _analysisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        if (snapshot.hasData) {
          return RankingAnalysisWidget(
            analysis: snapshot.data!,
            results: _currentResults,
          );
        }
        
        return const Center(child: Text('No analysis available'));
      },
    );
  }

  Widget _buildAttributesTab() {
    return FutureBuilder<List<AttributeImpact>>(
      future: _impactFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        if (snapshot.hasData) {
          return AttributeImpactWidget(
            impacts: snapshot.data!,
            onAttributeAdjust: (attribute) => _adjustAttribute(attribute),
          );
        }
        
        return const Center(child: Text('No attribute data available'));
      },
    );
  }

  Widget _buildAdjustmentsTab() {
    return RealTimeAdjustmentWidget(
      position: widget.position,
      initialAttributes: _currentAttributes,
      initialResults: _currentResults,
      onRankingsUpdated: _onRankingsUpdated,
    );
  }

  void _showPlayerDetails(CustomRankingResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.playerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rank: #${result.rank}'),
            Text('Total Score: ${result.formattedScore}'),
            Text('Team: ${result.team}'),
            const SizedBox(height: 16),
            const Text('Attribute Scores:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...result.attributeScores.entries.map((entry) {
              final attr = _currentAttributes.firstWhere(
                (a) => a.id == entry.key,
                orElse: () => EnhancedRankingAttribute(
                  id: entry.key,
                  name: entry.key,
                  displayName: entry.key,
                  category: 'Unknown',
                  position: widget.position,
                  weight: 0.0,
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('${attr.displayName}: ${entry.value.toStringAsFixed(3)}'),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _adjustWeights() {
    // On mobile, switch to adjust tab
    // On desktop, show inline adjustments
    setState(() {
      _tabController.animateTo(3); // Switch to adjustments tab
    });
  }

  void _adjustAttribute(EnhancedRankingAttribute attribute) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adjust ${attribute.displayName} - Feature coming soon!'),
      ),
    );
  }

  Future<void> _shareRankings(String action) async {
    try {
      switch (action) {
        case 'methodology':
          final methodology = RankingExportService.generateMethodologySummary(
            attributes: _currentAttributes,
            rankingName: widget.rankingName.isNotEmpty 
                ? widget.rankingName 
                : 'Custom ${widget.position} Rankings',
            position: widget.position,
          );
          
          final methodologyText = '''
${methodology['name']}
Position: ${methodology['position']}
Total Attributes: ${methodology['totalAttributes']}
Primary Focus: ${methodology['primaryFocus']}

Attribute Breakdown:
${(methodology['attributes'] as List).map((attr) => 
  '• ${attr['name']}: ${attr['weightPercentage']}% (${attr['category']})'
).join('\n')}

Category Weights:
${(methodology['categoryBreakdown'] as Map).entries.map((entry) => 
  '• ${entry.key}: ${entry.value}%'
).join('\n')}
          ''';
          
          // For web, copy to clipboard
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Ranking Methodology'),
                content: SingleChildScrollView(
                  child: SelectableText(methodologyText),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
          break;
          
        case 'url':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Results URL copied to clipboard (feature in development)'),
            ),
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _exportRankings(String format) async {
    try {
      final rankingName = widget.rankingName.isNotEmpty 
          ? widget.rankingName 
          : 'Custom ${widget.position} Rankings';
      
      switch (format) {
        case 'csv':
          await RankingExportService.exportToCsv(
            results: _currentResults,
            attributes: _currentAttributes,
            rankingName: rankingName,
          );
          break;
          
        case 'json':
          await RankingExportService.exportToJson(
            results: _currentResults,
            attributes: _currentAttributes,
            rankingName: rankingName,
          );
          break;
          
        case 'html':
          final analysis = await _analysisFuture;
          await RankingExportService.exportToHtmlReport(
            results: _currentResults,
            attributes: _currentAttributes,
            rankingName: rankingName,
            position: widget.position,
            analysis: analysis,
          );
          break;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rankings exported as ${format.toUpperCase()}'),
            backgroundColor: ThemeConfig.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}