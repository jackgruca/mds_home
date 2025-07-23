import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../models/draft/draft_player.dart';
import '../../services/draft/csv_draft_service.dart';
import '../../utils/theme_config.dart';
import '../../utils/theme_aware_colors.dart';
import '../../utils/seo_helper.dart';

class DraftBigBoardScreen extends StatefulWidget {
  const DraftBigBoardScreen({super.key});

  @override
  State<DraftBigBoardScreen> createState() => _DraftBigBoardScreenState();
}

class _DraftBigBoardScreenState extends State<DraftBigBoardScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<DraftPlayer> _players = [];
  List<DraftPlayer> _filteredPlayers = [];
  List<DraftPlayer> _cachedVisiblePlayers = [];
  int? _sortColumnIndex;
  final bool _sortAscending = true;
  final CSVDraftService _csvService = CSVDraftService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _lastSearchQuery = '';
  String _lastPositionFilter = '';
  int _lastCurrentPage = -1;
  Timer? _searchDebounce;
  String _positionFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Pagination variables
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  int _totalRecords = 0;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchPlayers();
    
    // Update SEO for Draft Big Board
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForBigBoard();
      SEOHelper.updateToolStructuredData(
        toolName: '2026 NFL Draft Big Board',
        description: 'Comprehensive 2026 NFL Draft prospect rankings from multiple sources',
        url: 'https://sticktothemodel.com/draft/big-board',
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchPlayers() async {
    setState(() => _isLoading = true);

    try {
      print('DraftBigBoardScreen: Starting to fetch players...');
      final players = await _csvService.fetchDraftPlayers();
      print('DraftBigBoardScreen: Received ${players.length} players from service');
      setState(() {
        _players = players;
        _filteredPlayers = players;
        _sortData('Consensus Rank', true); // Initial sort by consensus rank
        _resetPagination(); // Reset pagination for fresh data
        _updateVisiblePlayers(); // Initialize visible players cache
        _isLoading = false;
      });
      print('DraftBigBoardScreen: State updated, _players.length = ${_players.length}');
      _animationController.forward();
    } catch (e) {
      print('DraftBigBoardScreen: Error fetching players: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading draft prospects: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _filterPlayers(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
        _resetPagination();
        _updateVisiblePlayers();
      });
    });
  }

  void _updateVisiblePlayers() {
    // Only use cache if search, position filter, current page, and players haven't changed
    if (_searchQuery == _lastSearchQuery && 
        _positionFilter == _lastPositionFilter && 
        _currentPage == _lastCurrentPage && 
        _cachedVisiblePlayers.isNotEmpty &&
        _players.isNotEmpty) {
      return; // Use cached results
    }
    
    // Filter all players first
    final allFilteredPlayers = _players.where((player) {
      final matchesSearch = _searchQuery.isEmpty ||
        player.name.toLowerCase().contains(_searchQuery) ||
        player.position.toLowerCase().contains(_searchQuery) ||
        player.school.toLowerCase().contains(_searchQuery) ||
        player.rank.toString().contains(_searchQuery);
      final matchesPosition = _positionFilter == 'All' || player.position == _positionFilter;
      return matchesSearch && matchesPosition;
    }).toList();
    
    // Update pagination info
    _totalRecords = allFilteredPlayers.length;
    final totalPages = (_totalRecords / _rowsPerPage).ceil();
    
    // Ensure current page is valid
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    
    // Calculate pagination
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _totalRecords);
    _hasNextPage = endIndex < _totalRecords;
    
    // Get current page data
    _cachedVisiblePlayers = allFilteredPlayers.sublist(
      startIndex, 
      endIndex,
    );
    
    _lastSearchQuery = _searchQuery;
    _lastPositionFilter = _positionFilter;
    _lastCurrentPage = _currentPage;
  }
  
  List<DraftPlayer> get _visiblePlayers {
    if (_cachedVisiblePlayers.isEmpty && _players.isNotEmpty) {
      _updateVisiblePlayers();
    }
    return _cachedVisiblePlayers;
  }

  void _goToNextPage() {
    if (_hasNextPage) {
      setState(() {
        _currentPage++;
        _updateVisiblePlayers();
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _updateVisiblePlayers();
      });
    }
  }

  void _resetPagination() {
    _currentPage = 0;
    _totalRecords = 0;
    _hasNextPage = false;
    _lastCurrentPage = -1; // Reset cache tracker
  }

  void _sortData(String column, bool ascending) {
    _filteredPlayers.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (column) {
        case 'Name':
          aValue = a.name;
          bValue = b.name;
          break;
        case 'Position':
          aValue = a.position;
          bValue = b.position;
          break;
        case 'School':
          aValue = a.school;
          bValue = b.school;
          break;
        case 'MDD Rank':
          aValue = a.additionalRanks['MDD Rank'];
          bValue = b.additionalRanks['MDD Rank'];
          break;
        case 'Tank Rank':
          aValue = a.additionalRanks['Tank Rank'];
          bValue = b.additionalRanks['Tank Rank'];
          break;
        case 'Buzz Rank':
          aValue = a.additionalRanks['Buzz Rank'];
          bValue = b.additionalRanks['Buzz Rank'];
          break;
        case 'Average Rank':
          aValue = a.additionalRanks['Average Rank'];
          bValue = b.additionalRanks['Average Rank'];
          break;
        case 'Consensus Rank':
          aValue = a.rank; // Main rank is consensus
          bValue = b.rank;
          break;
        default:
          aValue = a.name;
          bValue = b.name;
      }
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? 1 : -1;
      if (bValue == null) return ascending ? -1 : 1;
      if (aValue is num && bValue is num) {
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      return ascending ? aValue.toString().compareTo(bValue.toString()) : bValue.toString().compareTo(aValue.toString());
    });
  }

  Widget _buildPlayerCard(DraftPlayer player, int index) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeConfig.gold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.darkNavy.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            // Could add player detail dialog here
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with rank, name, position
                Row(
                  children: [
                    // Consensus rank badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThemeConfig.gold,
                            ThemeConfig.gold.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConfig.gold.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '#${player.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Player info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.brightness == Brightness.dark 
                                ? Colors.white 
                                : ThemeConfig.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Position badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getPositionColor(player.position).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getPositionColor(player.position),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  player.position,
                                  style: TextStyle(
                                    color: _getPositionColor(player.position),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // School name
                              if (player.school.isNotEmpty) ...[
                                Text(
                                  player.school,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 20),
                
                // Rankings grid
                _buildRankingsGrid(player, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingsGrid(DraftPlayer player, ThemeData theme) {
    final rankings = [
      {'label': 'MDD', 'value': player.additionalRanks['MDD Rank']},
      {'label': 'Tank', 'value': player.additionalRanks['Tank Rank']},
      {'label': 'Buzz', 'value': player.additionalRanks['Buzz Rank']},
      {'label': 'Average', 'value': player.additionalRanks['Average Rank']},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Draft Rankings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark 
                ? Colors.white 
                : ThemeConfig.darkNavy,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: rankings.map((ranking) {
              final value = ranking['value'];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: value != null 
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value != null 
                      ? ThemeConfig.darkNavy.withOpacity(0.2)
                      : theme.dividerColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ranking['label'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value != null ? _formatRankValue(value) : '-',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: value != null 
                          ? (theme.brightness == Brightness.dark 
                              ? Colors.white 
                              : ThemeConfig.darkNavy)
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatRankValue(dynamic value) {
    if (value == null) return '-';
    if (value is double) {
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'QB':
        return Colors.red.shade600;
      case 'RB':
        return Colors.green.shade600;
      case 'WR':
        return Colors.blue.shade600;
      case 'TE':
        return Colors.orange.shade600;
      case 'OT':
      case 'IOL':
        return Colors.purple.shade600;
      case 'DL':
      case 'EDGE':
        return Colors.brown.shade600;
      case 'LB':
        return Colors.indigo.shade600;
      case 'CB':
      case 'S':
        return Colors.teal.shade600;
      case 'K':
      case 'P':
      case 'LS':
        return Colors.pink.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);
    final List<String> positions = ['All', 'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'DL', 'EDGE', 'LB', 'CB', 'S', 'K', 'P'];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
        actions: [],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Compact header section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: ThemeConfig.darkNavy.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title row with action buttons
                  Row(
                    children: [
                      // Title section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2026 NFL Draft Big Board',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ThemeConfig.darkNavy,
                              ),
                            ),
                            Text(
                              'Comprehensive prospect rankings from multiple sources',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            elevation: 1,
                            borderRadius: BorderRadius.circular(16),
                            shadowColor: ThemeConfig.gold.withOpacity(0.2),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _fetchPlayers();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeConfig.darkNavy,
                                foregroundColor: ThemeConfig.gold,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Search and filters row
                  Row(
                    children: [
                      // Search bar
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: ThemeConfig.darkNavy.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search prospects...',
                              hintStyle: const TextStyle(fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded, size: 20, color: ThemeConfig.darkNavy.withOpacity(0.7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            onChanged: _filterPlayers,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Position filters
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: positions.map((pos) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: FilterChip(
                                label: Text(pos, style: const TextStyle(fontSize: 12)),
                                selected: _positionFilter == pos,
                                onSelected: (_) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _positionFilter = pos;
                                    _resetPagination();
                                    _updateVisiblePlayers();
                                  });
                                },
                                backgroundColor: theme.colorScheme.surface,
                                selectedColor: ThemeConfig.gold.withOpacity(0.2),
                                checkmarkColor: ThemeConfig.darkNavy,
                                labelStyle: TextStyle(
                                  color: _positionFilter == pos 
                                    ? ThemeConfig.darkNavy 
                                    : theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: _positionFilter == pos 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: _positionFilter == pos 
                                    ? ThemeConfig.gold 
                                    : theme.dividerColor.withOpacity(0.3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.gold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading prospects...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _visiblePlayers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No prospects found',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Use cards on mobile (< 768px), table on web/desktop
                                  final isMobile = constraints.maxWidth < 768;
                                  
                                  if (isMobile) {
                                    return ListView.builder(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      itemCount: _visiblePlayers.length,
                                      itemBuilder: (context, index) {
                                        return _buildPlayerCard(_visiblePlayers[index], index);
                                      },
                                    );
                                  } else {
                                    return _buildTableWithStickyHeader();
                                  }
                                },
                              ),
                            ),
                            _buildPaginationControls(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final theme = Theme.of(context);
    final totalPages = (_totalRecords / _rowsPerPage).ceil().clamp(1, 9999);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            'Page ${_currentPage + 1} of $totalPages. Total: $_totalRecords prospects.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          
          // Navigation buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                child: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _hasNextPage ? _goToNextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableWithStickyHeader() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Sticky header
        Container(
          decoration: BoxDecoration(
            color: ThemeAwareColors.getTableHeaderColor(context),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.transparent),
              headingTextStyle: TextStyle(
                color: ThemeAwareColors.getTableHeaderTextColor(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columnSpacing: 32,
              horizontalMargin: 16,
              dividerThickness: 0,
              columns: _getModernColumns(),
              rows: [], // Empty rows for header only
            ),
          ),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 0, // Hide header in scrollable content
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                showCheckboxColumn: false,
                columnSpacing: 32,
                horizontalMargin: 16,
                dividerThickness: 0,
                columns: _getModernColumns(),
                rows: _getModernRows(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<DataColumn> _getModernColumns() {
    return [
      DataColumn(
        label: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Rank'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Consensus Rank', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
          child: const Text('Player'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Name', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Pos'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Position', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
          child: const Text('School'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('School', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('MDD'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('MDD Rank', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Tank'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Tank Rank', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Buzz'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Buzz Rank', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Avg'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Average Rank', asc));
        },
      ),
    ];
  }

  List<DataRow> _getModernRows() {
    return _visiblePlayers.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      
      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return ThemeConfig.gold.withOpacity(0.1);
          }
          return ThemeAwareColors.getTableRowColor(context, index);
        }),
        cells: [
          // Rank cell with badge
          DataCell(
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeConfig.gold,
                      ThemeConfig.gold.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${player.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          
          // Player name cell
          DataCell(
            Container(
              width: 140,
              alignment: Alignment.centerLeft,
              child: Text(
                player.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : ThemeConfig.darkNavy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Position cell with colored badge
          DataCell(
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getPositionColor(player.position).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getPositionColor(player.position),
                    width: 1,
                  ),
                ),
                child: Text(
                  player.position,
                  style: TextStyle(
                    color: _getPositionColor(player.position),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          
          // School cell
          DataCell(
            Container(
              width: 120,
              alignment: Alignment.centerLeft,
              child: Text(
                player.school,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Ranking cells
          DataCell(_buildRankingCell(player.additionalRanks['MDD Rank'], index, width: 60)),
          DataCell(_buildRankingCell(player.additionalRanks['Tank Rank'], index, width: 60)),
          DataCell(_buildRankingCell(player.additionalRanks['Buzz Rank'], index, width: 60)),
          DataCell(_buildRankingCell(player.additionalRanks['Average Rank'], index, width: 60)),
        ],
      );
    }).toList();
  }

  Widget _buildRankingCell(dynamic value, int index, {double width = 60}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: value != null 
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value != null ? _formatRankValue(value) : '-',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: value != null 
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}