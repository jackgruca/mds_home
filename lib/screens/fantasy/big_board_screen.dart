import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import '../../models/fantasy/player_ranking.dart';
import '../../services/fantasy/csv_rankings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../utils/team_logo_utils.dart';

class BigBoardScreen extends StatefulWidget {
  const BigBoardScreen({super.key});

  @override
  State<BigBoardScreen> createState() => _BigBoardScreenState();
}

class CustomColumn {
  String title;
  Map<String, int> values;
  CustomColumn({required this.title, Map<String, int>? values}) : values = values ?? {};
}

class _BigBoardScreenState extends State<BigBoardScreen> {
  bool _isLoading = true;
  List<PlayerRanking> _rankings = [];
  List<PlayerRanking> _filteredRankings = [];
  int? _sortColumnIndex;
  final bool _sortAscending = true;
  final CSVRankingsService _csvService = CSVRankingsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<CustomColumn> _customColumns = [];
  final bool _customRanksInitialized = false;
  String _positionFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchRankings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRankings() async {
    setState(() => _isLoading = true);

    try {
      final rankings = await _csvService.fetchRankings();
      setState(() {
        _rankings = rankings;
        _filteredRankings = rankings;
        _sortData('Consensus Rank', true); // Initial sort by consensus rank
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rankings: $e')),
        );
      }
    }
  }

  void _filterRankings(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<PlayerRanking> get _visibleRankings {
    return _rankings.where((player) {
      final matchesSearch = _searchQuery.isEmpty ||
        player.name.toLowerCase().contains(_searchQuery) ||
        player.position.toLowerCase().contains(_searchQuery) ||
        player.rank.toString().contains(_searchQuery) ||
        (player.additionalRanks['PFF']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['CBS']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['ESPN']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['FFToday']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['FootballGuys']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['Yahoo']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['NFL']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['Consensus']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['Consensus Rank']?.toString() ?? '').contains(_searchQuery) ||
        _customColumns.any((col) => (col.values[player.id]?.toString() ?? '').contains(_searchQuery));
      final matchesPosition = _positionFilter == 'All' || player.position == _positionFilter;
      return matchesSearch && matchesPosition;
    }).toList();
  }

  void _sortData(String column, bool ascending) {
    _filteredRankings.sort((a, b) {
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
        case 'Team':
          aValue = a.team;
          bValue = b.team;
          break;
        case 'ESPN':
          aValue = a.additionalRanks['ESPN'];
          bValue = b.additionalRanks['ESPN'];
          break;
        case 'PFF':
          aValue = a.additionalRanks['PFF'];
          bValue = b.additionalRanks['PFF'];
          break;
        case 'CBS':
          aValue = a.additionalRanks['CBS'];
          bValue = b.additionalRanks['CBS'];
          break;
        case 'FFToday':
          aValue = a.additionalRanks['FFToday'];
          bValue = b.additionalRanks['FFToday'];
          break;
        case 'FootballGuys':
          aValue = a.additionalRanks['FootballGuys'];
          bValue = b.additionalRanks['FootballGuys'];
          break;
        case 'Yahoo':
          aValue = a.additionalRanks['Yahoo'];
          bValue = b.additionalRanks['Yahoo'];
          break;
        case 'NFL':
          aValue = a.additionalRanks['NFL'];
          bValue = b.additionalRanks['NFL'];
          break;
        case 'Consensus':
          aValue = a.additionalRanks['Consensus'];
          bValue = b.additionalRanks['Consensus'];
          break;
        case 'Consensus Rank':
          aValue = a.rank; // Main rank is consensus
          bValue = b.rank;
          break;
        case 'Bye':
          aValue = a.additionalRanks['Bye'];
          bValue = b.additionalRanks['Bye'];
          break;
        default:
          if (_customColumns.any((c) => c.title == column)) {
            final col = _customColumns.firstWhere((c) => c.title == column);
            aValue = col.values[a.id];
            bValue = col.values[b.id];
          } else {
          aValue = a.name;
          bValue = b.name;
          }
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

  void _onAddCustomColumn() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Column'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Column Title'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (title != null && title.isNotEmpty) {
      final newCol = CustomColumn(title: title);
      for (final player in _rankings) {
        final consensusRank = player.rank; // Use main rank now
          newCol.values[player.id] = consensusRank;
      }
      setState(() {
        _customColumns.add(newCol);
      });
    }
  }

  void _onRemoveCustomColumn(int index) {
    setState(() {
      _customColumns.removeAt(index);
    });
  }

  void _editCustomRank(BuildContext context, String id, int? currentValue, int colIndex) async {
    final controller = TextEditingController(text: currentValue?.toString() ?? '');
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set ${_customColumns[colIndex].title}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter custom rank'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                final value = int.tryParse(text);
                Navigator.pop(context, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        _customColumns[colIndex].values[id] = result;
      });
    }
  }

  void _onUpdateRanks() {
    setState(() {
      for (final player in _rankings) {
        final ranks = <num>[];
        if (player.rank > 0) ranks.add(player.rank);
        final fp = player.additionalRanks['FantasyPro'];
        if (fp != null) ranks.add(fp);
        final cbs = player.additionalRanks['CBS'];
        if (cbs != null) ranks.add(cbs);
        for (final col in _customColumns) {
          final val = col.values[player.id];
          if (val != null) ranks.add(val);
        }
        final consensus = ranks.isNotEmpty ? ranks.reduce((a, b) => a + b) / ranks.length : null;
        player.additionalRanks['Consensus'] = consensus;
      }
      final sorted = List<PlayerRanking>.from(_rankings);
      sorted.sort((a, b) {
        final aVal = a.additionalRanks['Consensus'];
        final bVal = b.additionalRanks['Consensus'];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        return (aVal as num).compareTo(bVal as num);
      });
      for (int i = 0; i < sorted.length; i++) {
        sorted[i].additionalRanks['Consensus Rank'] = i + 1;
      }
    });
  }

  Future<void> _onImportCSV() async {
    if (_customColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a custom column first.')),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.bytes != null) {
      final csvString = utf8.decode(result.files.single.bytes!);
      final lines = const LineSplitter().convert(csvString);
      // Expecting: Name,CustomRank
      final Map<String, int> importMap = {};
      for (final line in lines.skip(1)) {
        final parts = line.split(',');
        if (parts.length < 2) continue;
        final name = parts[0].trim();
        final value = int.tryParse(parts[1].trim());
        if (value != null) {
          // Find player by name
          final player = _rankings.where((p) => p.name == name).toList();
          if (player.isNotEmpty) {
            importMap[player.first.id] = value;
          }
        }
      }
      setState(() {
        // Always update the most recently added custom column
        final col = _customColumns.last;
        col.values.addAll(importMap);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom ranks imported!')),
      );
    }
  }

  List<DataColumn> _getColumns() {
    return [
      DataColumn(label: const Text('Name'), onSort: (i, asc) => setState(() => _sortData('Name', asc))),
      DataColumn(label: const Text('Pos'), onSort: (i, asc) => setState(() => _sortData('Position', asc))),
      DataColumn(label: const Text('Team'), onSort: (i, asc) => setState(() => _sortData('Team', asc))),
      DataColumn(label: const Text('Bye'), onSort: (i, asc) => setState(() => _sortData('Bye', asc))),
      DataColumn(label: const Text('PFF'), onSort: (i, asc) => setState(() => _sortData('PFF', asc))),
      DataColumn(label: const Text('CBS'), onSort: (i, asc) => setState(() => _sortData('CBS', asc))),
      DataColumn(label: const Text('ESPN'), onSort: (i, asc) => setState(() => _sortData('ESPN', asc))),
      DataColumn(label: const Text('FFToday'), onSort: (i, asc) => setState(() => _sortData('FFToday', asc))),
      DataColumn(label: const Text('FG'), onSort: (i, asc) => setState(() => _sortData('FootballGuys', asc))),
      DataColumn(label: const Text('Yahoo'), onSort: (i, asc) => setState(() => _sortData('Yahoo', asc))),
      DataColumn(label: const Text('NFL'), onSort: (i, asc) => setState(() => _sortData('NFL', asc))),
      ..._customColumns.map((col) => DataColumn(
            label: Row(
              children: [
                Text(col.title),
                IconButton(
                  icon: const Icon(Icons.delete, size: 16),
                  onPressed: () => _onRemoveCustomColumn(_customColumns.indexOf(col)),
                )
              ],
            ),
            onSort: (i, asc) => setState(() => _sortData(col.title, asc)),
          )),
      DataColumn(label: const Text('Cons. Rk'), onSort: (i, asc) => setState(() => _sortData('Consensus Rank', asc))),
    ];
  }

  List<DataRow> _getRows() {
    return _visibleRankings.map((player) {
      return DataRow(cells: [
        DataCell(Text(player.name)),
        DataCell(Text(player.position)),
        DataCell(
          Row(
            children: [
              if (player.team.isNotEmpty)
                TeamLogoUtils.buildNFLTeamLogo(player.team, size: 20),
              const SizedBox(width: 5),
              Text(player.team),
            ],
          ),
        ),
        DataCell(Text(player.additionalRanks['Bye']?.toString() ?? '-')),
        DataCell(Text(player.additionalRanks['PFF']?.toString() ?? '-')),
        DataCell(Text(player.additionalRanks['CBS']?.toString() ?? '-')),
        DataCell(Text(player.additionalRanks['ESPN']?.toString() ?? '-')),
        DataCell(Text(player.additionalRanks['FFToday']?.toString() ?? '-')),
        DataCell(Text(player.additionalRanks['FootballGuys']?.toString() ?? '-')),
        DataCell(Text(player.additionalRanks['Yahoo']?.toString() ?? '-')),
        DataCell(Text(player.additionalRanks['NFL']?.toString() ?? '-')),
        ..._customColumns.map((col) {
          return DataCell(
            Text(col.values[player.id]?.toString() ?? '-'),
            showEditIcon: true,
            onTap: () => _editCustomRank(context, player.id, col.values[player.id], _customColumns.indexOf(col)),
          );
        }),
        DataCell(Text(player.rank.toString())),
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final Color headerColor = Colors.blue.shade700;
    final Color evenRowColor = Colors.blue.shade50;
    const Color oddRowColor = Colors.white;
    final cellTextStyle = TextStyle(
      color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.white 
          : Colors.black87,
    );

    final List<String> positions = ['All', 'QB', 'RB', 'WR', 'TE', 'K', 'D/ST'];

    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRankings,
            tooltip: 'Refresh Rankings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and custom ranks controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search players...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: _filterRankings,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _onAddCustomColumn,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Column'),
                    ),
                      const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {}, // Was _onUpdateRanks
                      icon: const Icon(Icons.refresh),
                      label: const Text('Update Ranks'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _onImportCSV,
                        child: const Text('Import CSV'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: positions.map((pos) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(pos),
                        selected: _positionFilter == pos,
                        onSelected: (_) {
                          setState(() {
                            _positionFilter = pos;
                          });
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dataTableTheme: const DataTableThemeData(
                            columnSpacing: 0,
                            horizontalMargin: 0,
                            dividerThickness: 0,
                          ),
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(headerColor),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          dataRowHeight: 44,
                          showCheckboxColumn: false,
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          border: TableBorder.all(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid,
                          ),
                          columns: _getColumns(),
                          rows: _getRows(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 