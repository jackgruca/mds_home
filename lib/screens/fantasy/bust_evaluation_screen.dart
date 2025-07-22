import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../models/bust_evaluation.dart';
import '../../services/bust_evaluation_service.dart';
import '../../utils/theme_config.dart';
import '../../utils/theme_aware_colors.dart';
import '../../utils/team_logo_utils.dart';
import 'dart:math' as math;

class BustEvaluationScreen extends StatefulWidget {
  const BustEvaluationScreen({super.key});

  @override
  State<BustEvaluationScreen> createState() => _BustEvaluationScreenState();
}

class _BustEvaluationScreenState extends State<BustEvaluationScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<BustEvaluationPlayer> _searchResults = [];
  List<BustEvaluationPlayer> _featuredPlayers = [];
  BustEvaluationPlayer? _selectedPlayer;
  List<BustTimelineData> _playerTimeline = [];
  
  bool _isSearching = false;
  bool _isLoadingPlayer = false;
  bool _isLoadingFeatured = true;
  
  String _selectedPosition = 'All';
  String _selectedCategory = 'All';
  int _selectedRound = 0; // 0 means all rounds
  
  late AnimationController _searchAnimationController;
  late AnimationController _playerCardController;
  late Animation<double> _searchAnimation;
  late Animation<double> _playerCardAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFeaturedPlayers();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _playerCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOut),
    );
    _playerCardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _playerCardController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    _playerCardController.dispose();
    super.dispose();
  }

  Future<void> _loadFeaturedPlayers() async {
    setState(() => _isLoadingFeatured = true);
    try {
      final controversial = await BustEvaluationService.getRandomControversialPlayers();
      setState(() {
        _featuredPlayers = controversial;
        _isLoadingFeatured = false;
      });
    } catch (e) {
      setState(() => _isLoadingFeatured = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading featured players: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _searchAnimationController.reverse();
      return;
    }

    if (!_isSearching) {
      setState(() => _isSearching = true);
      _searchAnimationController.forward();
    }

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await BustEvaluationService.searchPlayers(query);
      
      // Apply filters
      final filteredResults = results.where((player) {
        if (_selectedPosition != 'All' && player.position != _selectedPosition) return false;
        if (_selectedCategory != 'All' && player.bustCategory != _selectedCategory) return false;
        if (_selectedRound != 0 && player.draftRound != _selectedRound) return false;
        return true;
      }).toList();

      setState(() => _searchResults = filteredResults);
    } catch (e) {
      print('Search error: $e');
    }
  }

  Future<void> _selectPlayer(BustEvaluationPlayer player) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoadingPlayer = true);
    
    try {
      final timeline = await BustEvaluationService.getPlayerTimeline(player.gsisId);
      
      setState(() {
        _selectedPlayer = player;
        _playerTimeline = timeline;
        _isLoadingPlayer = false;
      });
      _playerCardController.forward();
    } catch (e) {
      setState(() => _isLoadingPlayer = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading player data: $e')),
        );
      }
    }
  }

  Future<void> _selectRandomPlayer() async {
    HapticFeedback.lightImpact();
    if (_featuredPlayers.isNotEmpty) {
      final random = math.Random();
      final player = _featuredPlayers[random.nextInt(_featuredPlayers.length)];
      await _selectPlayer(player);
    }
  }

  void _clearSelection() {
    setState(() => _selectedPlayer = null);
    _playerCardController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              shadowColor: ThemeConfig.gold.withOpacity(0.3),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showDialog(context: context, builder: (_) => const AuthDialog());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Sign In / Sign Up'),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 800),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchSection(),
            _buildFilters(),
            Expanded(
              child: _selectedPlayer != null 
                  ? _buildPlayerAnalysis()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConfig.darkNavy,
            ThemeConfig.darkNavy.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeConfig.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: ThemeConfig.gold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bust or Brilliant?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Evaluate NFL draft picks vs. expectations',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search any drafted player (2010-2024)...',
                                  prefixIcon: Icon(Icons.search, color: ThemeAwareColors.getSecondaryTextColor(context)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                                  fillColor: ThemeAwareColors.getSearchBarFillColor(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectRandomPlayer,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Random Player'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.gold,
                    foregroundColor: ThemeConfig.darkNavy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeConfig.darkNavy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isSearching ? 80 : 0,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildFilterDropdown('Position', _selectedPosition, 
                    ['All', 'QB', 'RB', 'WR', 'TE'], (value) => setState(() => _selectedPosition = value!))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterDropdown('Category', _selectedCategory,
                    ['All', 'Steal', 'Met Expectations', 'Disappointing', 'Bust'], 
                    (value) => setState(() => _selectedCategory = value!))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterDropdown('Round', _selectedRound == 0 ? 'All' : 'Round $_selectedRound',
                    ['All', 'Round 1', 'Round 2', 'Round 3', 'Round 4', 'Round 5', 'Round 6', 'Round 7'],
                    (value) => setState(() => _selectedRound = value == 'All' ? 0 : int.parse(value!.split(' ')[1])))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeAwareColors.getCardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeAwareColors.getDividerColor(context)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: (newValue) {
          onChanged(newValue);
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching && _searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: ThemeAwareColors.getSecondaryTextColor(context)),
            const SizedBox(height: 16),
            Text('No players found', style: TextStyle(fontSize: 18, color: ThemeAwareColors.getSecondaryTextColor(context))),
            Text('Try adjusting your search or filters', style: TextStyle(color: ThemeAwareColors.getSecondaryTextColor(context))),
          ],
        ),
      );
    }

    if (_isSearching && _searchResults.isNotEmpty) {
      return _buildPlayerGrid(_searchResults, 'Search Results');
    }

    // Show featured players when not searching
    if (_isLoadingFeatured) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildPlayerGrid(_featuredPlayers, 'Featured Controversial Picks');
  }

  Widget _buildPlayerGrid(List<BustEvaluationPlayer> players, String title) {
    // Group players by position
    final Map<String, List<BustEvaluationPlayer>> playersByPosition = {
      'QB': [],
      'RB': [],
      'WR': [],
      'TE': [],
    };
    
    for (final player in players) {
      if (playersByPosition.containsKey(player.position)) {
        playersByPosition[player.position]!.add(player);
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QB Column
                  Expanded(child: _buildPositionColumn('QB', playersByPosition['QB']!)),
                  const SizedBox(width: 8),
                  // RB Column  
                  Expanded(child: _buildPositionColumn('RB', playersByPosition['RB']!)),
                  const SizedBox(width: 8),
                  // WR Column
                  Expanded(child: _buildPositionColumn('WR', playersByPosition['WR']!)),
                  const SizedBox(width: 8),
                  // TE Column
                  Expanded(child: _buildPositionColumn('TE', playersByPosition['TE']!)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionColumn(String position, List<BustEvaluationPlayer> players) {
    return Column(
      children: [
        // Position header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _getPositionColor(position),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            position,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Players in this position
        ...players.map((player) => _buildCompactPlayerCard(player)),
      ],
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'QB':
        return Colors.purple;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCompactPlayerCard(BustEvaluationPlayer player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _selectPlayer(player),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeAwareColors.getCardColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getBustCategoryColor(player.bustCategory),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player name and team
              Row(
                children: [
                  if (player.team.isNotEmpty) ...[
                    TeamLogoUtils.buildNFLTeamLogo(player.team, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      player.playerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Draft info
              Text(
                player.draftRoundDisplay,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              // Career span
              Text(
                player.careerSpanDisplay,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white60 
                      : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              // Category badge and score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getBustCategoryColor(player.bustCategory),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      player.bustCategory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (player.performanceScore != null)
                    Text(
                      '${(player.performanceScore! * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getBustCategoryColor(player.bustCategory),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerAnalysis() {
    if (_selectedPlayer == null) return const SizedBox();
    
    return AnimatedBuilder(
      animation: _playerCardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _playerCardAnimation.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPlayerHeader(),
                const SizedBox(height: 16),
                _buildStatsComparison(),
                const SizedBox(height: 16),
                _buildTransparencySection(),
                const SizedBox(height: 16),
                _buildVerdictCard(),
                const SizedBox(height: 16),
                _buildTimelineChart(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerHeader() {
    final player = _selectedPlayer!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeAwareColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (player.team.isNotEmpty) ...[
            TeamLogoUtils.buildNFLTeamLogo(player.team, size: 48),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode 
                        ? ThemeConfig.darkNavy.withOpacity(0.9) // Darker in dark mode
                        : ThemeConfig.darkNavy, // Keep dark in light mode
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.position} • ${player.draftRoundDisplay} (${player.rookieYear})',
                  style: TextStyle(
                    fontSize: 16,
                    color: ThemeAwareColors.getSecondaryTextColor(context),
                  ),
                ),
                Text(
                  '${player.seasonsPlayed} seasons • ${player.careerSpanDisplay}',
                  style: TextStyle(
                    fontSize: 14,
                    color: ThemeAwareColors.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearSelection,
            icon: Icon(
              Icons.close,
              color: isDarkMode ? ThemeConfig.gold : ThemeConfig.darkNavy,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDarkMode 
                  ? ThemeConfig.darkNavy.withOpacity(0.8) // Dark navy background in dark mode
                  : ThemeConfig.gold.withOpacity(0.1), // Light gold background in light mode
              side: isDarkMode 
                  ? BorderSide(color: ThemeConfig.gold.withOpacity(0.3), width: 1)
                  : BorderSide(color: ThemeConfig.darkNavy.withOpacity(0.2), width: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsComparison() {
    final player = _selectedPlayer!;
    final leftStats = player.getLeftSideStats();
    final rightStats = player.getRightSideStats();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeAwareColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeAwareColors.getDividerColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      Text(
              'Career Stats vs Expectations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeAwareColors.getOnSurfaceColor(context),
              ),
            ),
          const SizedBox(height: 16),
          
          // For QB and RB, show left/right split
          if (player.position == 'QB' || player.position == 'RB') ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.position == 'QB' ? 'Passing Stats' : 'Rushing Stats',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ThemeConfig.brightRed,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...leftStats.map((stat) => _buildStatRow(stat)).toList(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right side stats  
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.position == 'QB' ? 'Rushing Stats' : 'Receiving Stats',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ThemeConfig.brightRed,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...rightStats.map((stat) => _buildStatRow(stat)).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // For WR/TE, show single column
            ...leftStats.map((stat) => _buildStatRow(stat)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTransparencySection() {
    final player = _selectedPlayer!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeAwareColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeAwareColors.getDividerColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: ThemeConfig.brightRed,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'How This Works',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            player.peerDescription,
            style: TextStyle(
              fontSize: 14,
              color: ThemeAwareColors.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            player.expectationSource,
            style: TextStyle(
              fontSize: 14,
              color: ThemeAwareColors.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Similar Draft Picks:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: BustEvaluationService.getSimilarPlayerStats(player),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                // Fallback to hardcoded examples
                final examples = player.getSimilarPlayerExamples();
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: examples.map((example) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeAwareColors.getDividerColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      example,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                );
              }
              
              final similarPlayers = snapshot.data!;
              return Column(
                children: similarPlayers.map((p) => _buildSimilarPlayerCard(p['player'] as BustEvaluationPlayer)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarPlayerCard(BustEvaluationPlayer player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeAwareColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeAwareColors.getDividerColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player header info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.playerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeAwareColors.getOnSurfaceColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.position} • R${player.draftRound} (${player.rookieYear}) • ${player.seasonsPlayed} seasons',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeAwareColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              // Performance badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(player.bustCategory).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getCategoryColor(player.bustCategory)),
                ),
                child: Text(
                  player.bustCategory,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(player.bustCategory),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Key stats with percentages
          const Text(
            'Key Performance Metrics',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ThemeConfig.brightRed,
            ),
          ),
          const SizedBox(height: 8),
          
          // Stats grid with icons and percentages
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildPlayerStatChips(player),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerStatChips(BustEvaluationPlayer player) {
    final chips = <Widget>[];
    final leftStats = player.getLeftSideStats();
    final rightStats = player.getRightSideStats();
    final allStats = [...leftStats, ...rightStats];
    
    // Show top 4 most relevant stats for the position
    final relevantStats = _getRelevantStatsForPosition(player.position, allStats);
    
    for (final stat in relevantStats.take(4)) {
      if (stat.ratio != null) {
        chips.add(_buildStatChip(stat));
      }
    }
    
    return chips;
  }

  List<BustStatComparison> _getRelevantStatsForPosition(String position, List<BustStatComparison> stats) {
    switch (position) {
      case 'QB':
        // Prioritize pass yards, pass TDs, INTs, rush yards
        return stats.where((s) => [
          'Passing Yards', 'Passing TDs', 'Interceptions', 'Rushing Yards'
        ].contains(s.label)).toList();
      case 'RB':
        // Prioritize rush yards, rush TDs, rec yards, carries
        return stats.where((s) => [
          'Rushing Yards', 'Rushing TDs', 'Receiving Yards', 'Carries'
        ].contains(s.label)).toList();
      case 'WR':
      case 'TE':
        // Prioritize rec yards, receptions, rec TDs, targets
        return stats.where((s) => [
          'Receiving Yards', 'Receptions', 'Receiving TDs', 'Targets'
        ].contains(s.label)).toList();
      default:
        return stats.take(4).toList();
    }
  }

  Widget _buildStatChip(BustStatComparison stat) {
    final percentage = stat.percentage;
    final isGood = stat.isOverPerforming;
    final color = stat.isSignificantlyOver 
        ? Colors.green 
        : stat.isSignificantlyUnder 
            ? Colors.red 
            : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatIcon(stat.label),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${stat.label.split(' ').first}: ${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatIcon(String statLabel) {
    switch (statLabel) {
      case 'Passing Yards':
      case 'Passing TDs':
      case 'Pass Attempts':
        return Icons.sports_football;
      case 'Rushing Yards':
      case 'Rushing TDs':
      case 'Carries':
      case 'Rush Attempts':
        return Icons.directions_run;
      case 'Receiving Yards':
      case 'Receiving TDs':
      case 'Receptions':
      case 'Targets':
        return Icons.sports_handball;
      case 'Interceptions':
      case 'Fumbles':
        return Icons.warning;
      default:
        return Icons.analytics;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Steal':
        return Colors.green;
      case 'Met Expectations':
        return Colors.blue;
      case 'Disappointing':
        return Colors.orange;
      case 'Bust':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildVerdictCard() {
    final player = _selectedPlayer!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getBustCategoryColor(player.bustCategory),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                player.bustEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${player.bustCategory.toUpperCase()} VERDICT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getVerdictDescription(player),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          if (player.performanceScore != null) ...[
            const SizedBox(height: 12),
            Text(
              'Performance Score: ${(player.performanceScore! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineChart() {
    if (_playerTimeline.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Career Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _playerTimeline.length,
              itemBuilder: (context, index) {
                final data = _playerTimeline[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getBustCategoryColor(data.bustCategory),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Y${data.seasonsPlayed}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.leagueYear.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getBustCategoryColor(String category) {
    switch (category) {
      case 'Steal':
        return Colors.green;
      case 'Met Expectations':
        return Colors.blue;
      case 'Disappointing':
        return Colors.orange;
      case 'Bust':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getVerdictDescription(BustEvaluationPlayer player) {
    switch (player.bustCategory) {
      case 'Steal':
        return 'Significantly outperformed draft expectations. Excellent value pick.';
      case 'Met Expectations':
        return 'Performed close to peer averages for their draft position.';
      case 'Disappointing':
        return 'Underperformed expectations but not a complete failure.';
      case 'Bust':
        return 'Significantly underperformed draft expectations. Poor value.';
      default:
        return 'Insufficient data to make a determination.';
    }
  }

  Widget _buildStatRow(BustStatComparison stat) {
    final ratio = stat.ratio ?? 1.0;
    final color = stat.isSignificantlyOver 
        ? Colors.green 
        : stat.isSignificantlyUnder 
            ? Colors.red 
            : Colors.orange;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                stat.percentageDisplay,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actual: ${stat.actual.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Expected: ${stat.expected.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: (ratio).clamp(0.0, 2.0) / 2.0,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 