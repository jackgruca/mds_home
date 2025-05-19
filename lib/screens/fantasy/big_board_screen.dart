import 'package:flutter/material.dart';
import '../../models/fantasy/player_ranking.dart';
import '../../services/fantasy/csv_rankings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

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
  bool _sortAscending = true;
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
        (player.additionalRanks['FantasyPro']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['CBS']?.toString() ?? '').contains(_searchQuery) ||
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
        case 'ESPN Rank':
          aValue = a.rank;
          bValue = b.rank;
          break;
        case 'FantasyPro Rank':
          aValue = a.additionalRanks['FantasyPro'];
          bValue = b.additionalRanks['FantasyPro'];
          break;
        case 'CBS Rank':
          aValue = a.additionalRanks['CBS'];
          bValue = b.additionalRanks['CBS'];
          break;
        case 'Consensus':
          aValue = a.additionalRanks['Consensus'];
          bValue = b.additionalRanks['Consensus'];
          break;
        case 'Consensus Rank':
          aValue = a.additionalRanks['Consensus Rank'];
          bValue = b.additionalRanks['Consensus Rank'];
          break;
        case 'Custom Rank':
          aValue = _customColumns.last.values[a.id];
          bValue = _customColumns.last.values[b.id];
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
        final consensusRank = player.additionalRanks['Consensus Rank'];
        if (consensusRank != null) {
          newCol.values[player.id] = consensusRank;
        }
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

  @override
  Widget build(BuildContext context) {
    final Color headerColor = Colors.blue.shade700;
    final Color evenRowColor = Colors.blue.shade50;
    const Color oddRowColor = Colors.white;
    const headerTextStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    final cellTextStyle = TextStyle(
      color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.white 
          : Colors.black87,
    );

    final List<String> positions = ['All', 'QB', 'RB', 'WR', 'TE', 'K', 'D/ST'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fantasy Big Board'),
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
                    ElevatedButton(
                      onPressed: _onAddCustomColumn,
                      child: const Text('Add Custom Column'),
                    ),
                    if (_customColumns.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _onUpdateRanks,
                        child: const Text('Update Ranks'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _onImportCSV,
                        child: const Text('Import CSV'),
                      ),
                    ],
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
                          headingTextStyle: headerTextStyle,
                          dataRowHeight: 44,
                          showCheckboxColumn: false,
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          border: TableBorder.all(
                            color: Colors.white,
                            width: 0.5,
                            style: BorderStyle.solid,
                          ),
                          columns: [
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: const Text('Name'),
                              ),
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortColumnIndex = columnIndex;
                                  _sortAscending = ascending;
                                  _sortData('Name', ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: const Text('Position'),
                              ),
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortColumnIndex = columnIndex;
                                  _sortAscending = ascending;
                                  _sortData('Position', ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: const Text('ESPN Rank'),
                              ),
                              numeric: true,
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortColumnIndex = columnIndex;
                                  _sortAscending = ascending;
                                  _sortData('ESPN Rank', ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: const Text('FantasyPro Rank'),
                              ),
                              numeric: true,
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortColumnIndex = columnIndex;
                                  _sortAscending = ascending;
                                  _sortData('FantasyPro Rank', ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: const Text('CBS Rank'),
                              ),
                              numeric: true,
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortColumnIndex = columnIndex;
                                  _sortAscending = ascending;
                                  _sortData('CBS Rank', ascending);
                                });
                              },
                            ),
                            // Custom columns
                            ..._customColumns.asMap().entries.map((entry) {
                              final colIndex = entry.key;
                              final col = entry.value;
                              return DataColumn(
                                label: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Text(col.title),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () => _onRemoveCustomColumn(colIndex),
                                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                                numeric: true,
                                onSort: (columnIndex, ascending) {
                                  setState(() {
                                    _sortColumnIndex = columnIndex;
                                    _sortAscending = ascending;
                                    _sortData(col.title, ascending);
                                  });
                                },
                              );
                            }),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: const Text('Consensus'),
                              ),
                              numeric: true,
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortColumnIndex = columnIndex;
                                  _sortAscending = ascending;
                                  _sortData('Consensus', ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: const Text('Consensus Rank'),
                              ),
                              numeric: true,
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortColumnIndex = columnIndex;
                                  _sortAscending = ascending;
                                  _sortData('Consensus Rank', ascending);
                                });
                              },
                            ),
                          ],
                          rows: _visibleRankings.asMap().entries.map((entry) {
                            final int rowIndex = entry.key;
                            final PlayerRanking player = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.all(
                                rowIndex.isEven ? evenRowColor : oddRowColor
                              ),
                              cells: [
                                DataCell(Text(player.name, style: cellTextStyle)),
                                DataCell(Text(player.position, style: cellTextStyle)),
                                DataCell(Text(player.rank > 0 ? player.rank.toString() : '-', style: cellTextStyle)),
                                DataCell(Text(
                                  (player.additionalRanks['FantasyPro'] != null) ? player.additionalRanks['FantasyPro'].toString() : '-',
                                  style: cellTextStyle
                                )),
                                DataCell(Text(
                                  (player.additionalRanks['CBS'] != null) ? player.additionalRanks['CBS'].toString() : '-',
                                  style: cellTextStyle
                                )),
                                // Custom columns
                                ..._customColumns.asMap().entries.map((colEntry) {
                                  final colIndex = colEntry.key;
                                  final col = colEntry.value;
                                  final customRank = col.values[player.id];
                                  return DataCell(
                                    GestureDetector(
                                      onTap: () => _editCustomRank(context, player.id, customRank, colIndex),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            customRank != null ? customRank.toString() : '-',
                                            style: cellTextStyle.copyWith(
                                              decoration: TextDecoration.underline,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                DataCell(Text(
                                  (player.additionalRanks['Consensus'] != null) ? player.additionalRanks['Consensus'].toString() : '-',
                                  style: cellTextStyle
                                )),
                                DataCell(Text(
                                  (player.additionalRanks['Consensus Rank'] != null) ? player.additionalRanks['Consensus Rank'].toString() : '-',
                                  style: cellTextStyle
                                )),
                              ],
                            );
                          }).toList(),
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