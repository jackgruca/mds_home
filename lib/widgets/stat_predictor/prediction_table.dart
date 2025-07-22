import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/projections/stat_prediction.dart';
import 'tier_indicator.dart';

class PredictionTable extends StatefulWidget {
  final List<StatPrediction> predictions;
  final Function(StatPrediction, String, dynamic) onValueChanged;
  final Function(StatPrediction) onResetPlayer;

  const PredictionTable({
    super.key,
    required this.predictions,
    required this.onValueChanged,
    required this.onResetPlayer,
  });

  @override
  State<PredictionTable> createState() => _PredictionTableState();
}

class _PredictionTableState extends State<PredictionTable> {
  String _sortColumn = 'team';
  bool _sortAscending = true;
  late List<StatPrediction> _sortedPredictions;
  
  // Available years (can be expanded for historical data)
  final List<String> _availableYears = ['2024', '2025'];
  final List<String> _editableYears = ['2025']; // Only 2025 is editable

  @override
  void initState() {
    super.initState();
    _sortedPredictions = List.from(widget.predictions);
    _sortData();
  }

  @override
  void didUpdateWidget(PredictionTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.predictions != oldWidget.predictions) {
      _sortedPredictions = List.from(widget.predictions);
      _sortData();
    }
  }

  void _sort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
      _sortData();
    });
  }

  void _sortData() {
    _sortedPredictions.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortColumn) {
        case 'team':
          aValue = a.team;
          bValue = b.team;
          break;
        case 'playerName':
          aValue = a.playerName;
          bValue = b.playerName;
          break;
        case 'position':
          aValue = a.position;
          bValue = b.position;
          break;
        case 'tgtShare_2024':
          aValue = a.tgtShare;
          bValue = b.tgtShare;
          break;
        case 'tgtShare_2025':
          aValue = a.nyTgtShare;
          bValue = b.nyTgtShare;
          break;
        case 'wrRank_2024':
          aValue = a.wrRank;
          bValue = b.wrRank;
          break;
        case 'wrRank_2025':
          aValue = a.nyWrRank;
          bValue = b.nyWrRank;
          break;
        default:
          aValue = a.playerName;
          bValue = b.playerName;
      }

      // For team sorting, add secondary sort by 2025 target share
      if (_sortColumn == 'team') {
        final teamComparison = aValue.toString().compareTo(bValue.toString());
        if (teamComparison == 0) {
          return b.nyTgtShare.compareTo(a.nyTgtShare);
        }
        return _sortAscending ? teamComparison : -teamComparison;
      }

      if (aValue is num && bValue is num) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else {
        return _sortAscending
            ? aValue.toString().compareTo(bValue.toString())
            : bValue.toString().compareTo(aValue.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.predictions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No predictions found', style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Try adjusting your filters', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom grouped header
          _buildGroupedHeader(),
          // Data table with simplified columns
          SingleChildScrollView(
            child: DataTable(
              sortColumnIndex: null, // We'll handle sorting differently
              columns: _buildDataColumns(),
              rows: _buildDataRows(),
              columnSpacing: 8,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 48,
              headingRowHeight: 0, // Hide original header since we have custom
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedHeader() {
    // Calculate exact widths to match DataTable columns with column spacing
    const double columnSpacing = 8.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Fixed columns (Team, Player, Position) - match DataCell widths
            _buildHeaderCell('Team', 80, isFixed: true, canSort: true, sortKey: 'team'),
            SizedBox(width: columnSpacing),
            _buildHeaderCell('Player', 140, isFixed: true, canSort: true, sortKey: 'playerName'),
            SizedBox(width: columnSpacing),
            _buildHeaderCell('Pos', 50, isFixed: true, canSort: true, sortKey: 'position'),
            SizedBox(width: columnSpacing),
            
            // Grouped stat columns
            _buildGroupedStatHeader('Target Share', 160, 'tgtShare'),
            SizedBox(width: columnSpacing),
            _buildGroupedStatHeader('Team Rank', 160, 'wrRank'),
            SizedBox(width: columnSpacing),
            _buildGroupedStatHeader('Fantasy Points', 160, 'points'),
            SizedBox(width: columnSpacing),
            _buildGroupedStatHeader('Rec Yards', 160, 'yards'),
            SizedBox(width: columnSpacing),
            _buildGroupedStatHeader('Rec TDs', 160, 'tds'),
            SizedBox(width: columnSpacing),
            _buildGroupedStatHeader('Pass Off Tier', 160, 'passOffTier'),
            SizedBox(width: columnSpacing),
            _buildGroupedStatHeader('QB Tier', 160, 'qbTier'),
            SizedBox(width: columnSpacing),
            _buildGroupedStatHeader('Run Off Tier', 160, 'runOffTier'),
            SizedBox(width: columnSpacing),
            
            // Actions
            _buildHeaderCell('Actions', 80, isFixed: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, {bool isFixed = false, bool canSort = false, String? sortKey}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: canSort 
        ? InkWell(
            onTap: sortKey != null ? () => _sort(sortKey, _sortColumn != sortKey || !_sortAscending) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (sortKey != null && _sortColumn == sortKey)
                  Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: Colors.blue,
                  ),
              ],
            ),
          )
        : Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
    );
  }

  Widget _buildGroupedStatHeader(String statName, double width, String statKey) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Main stat name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Text(
              statName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Year subheaders
          Row(
            children: _availableYears.map((year) {
              final isEditable = _editableYears.contains(year);
              final sortKey = '${statKey}_$year';
              
              return Expanded(
                child: InkWell(
                  onTap: () => _sort(sortKey, _sortColumn != sortKey || !_sortAscending),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isEditable ? Colors.blue.shade50 : Colors.transparent,
                      border: year != _availableYears.last ? Border(right: BorderSide(color: Colors.grey.shade300, width: 0.5)) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          year,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isEditable ? Colors.blue.shade700 : Colors.black87,
                          ),
                        ),
                        if (isEditable) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.edit, size: 10, color: Colors.blue.shade600),
                        ],
                        if (_sortColumn == sortKey) ...[
                          const SizedBox(width: 2),
                          Icon(
                            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildDataColumns() {
    // Simplified columns since we have custom header
    return [
      const DataColumn(label: SizedBox.shrink()), // Team
      const DataColumn(label: SizedBox.shrink()), // Player
      const DataColumn(label: SizedBox.shrink()), // Position
      const DataColumn(label: SizedBox.shrink()), // Target Share
      const DataColumn(label: SizedBox.shrink()), // Team Rank
      const DataColumn(label: SizedBox.shrink()), // Fantasy Points
      const DataColumn(label: SizedBox.shrink()), // Rec Yards
      const DataColumn(label: SizedBox.shrink()), // Rec TDs
      const DataColumn(label: SizedBox.shrink()), // Pass Off Tier
      const DataColumn(label: SizedBox.shrink()), // QB Tier
      const DataColumn(label: SizedBox.shrink()), // Run Off Tier
      const DataColumn(label: SizedBox.shrink()), // Actions
    ];
  }

  List<DataRow> _buildDataRows() {
    return _sortedPredictions.map((prediction) {
      return DataRow(
        color: prediction.isEdited ? MaterialStateProperty.all(Colors.orange.shade50) : null,
        cells: [
          // Team
          DataCell(
            Container(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTeamColor(prediction.team),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  prediction.team,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          // Player
          DataCell(
            Container(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    prediction.playerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (prediction.isEdited)
                    const Text(
                      'Modified',
                      style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ),
          
          // Position
          DataCell(
            Container(
              width: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: prediction.position == 'WR' ? Colors.blue : Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  prediction.position,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          // Target Share (2024 | 2025)
          DataCell(
            Container(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${(prediction.tgtShare * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildEditableCell(
                      prediction, 'tgtShare', prediction.nyTgtShare, 
                      (v) => '${(v * 100).toStringAsFixed(1)}%', Colors.blue, true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Team Rank (2024 | 2025)
          DataCell(
            Container(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prediction.wrRank.toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildEditableCell(
                      prediction, 'wrRank', prediction.nyWrRank, 
                      (v) => v.toString(), Colors.blue, true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Fantasy Points (2024 | 2025)
          DataCell(
            Container(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prediction.points.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: Text(
                      prediction.nyPoints.toStringAsFixed(1),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Rec Yards (2024 | 2025)
          DataCell(
            Container(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prediction.numYards.toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: Text(
                      prediction.nySeasonYards.toString(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Rec TDs (2024 | 2025)
          DataCell(
            Container(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prediction.numTD.toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: Text(
                      prediction.nyNumTD.toString(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Pass Off Tier (2024 | 2025)
          DataCell(
            Container(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: TierIndicator(tier: prediction.passOffenseTier, tierType: 'passOffense', compact: true),
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildEditableTierCell(
                      prediction, 'passOffTier', prediction.passOffenseTier, Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // QB Tier (2024 | 2025)
          DataCell(
            Container(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: TierIndicator(tier: prediction.qbTier, tierType: 'qb', compact: true),
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildEditableTierCell(
                      prediction, 'qbTier', prediction.qbTier, Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Run Off Tier (2024 | 2025) - Note: Using passOffTier as placeholder since runOffTier not in current model
          DataCell(
            Container(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: TierIndicator(tier: 3, tierType: 'runOffense', compact: true), // Placeholder
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildEditableTierCell(
                      prediction, 'runOffTier', 3, Colors.blue, // Placeholder
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          DataCell(
            Container(
              width: 80,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prediction.isEdited)
                    Tooltip(
                      message: 'Reset',
                      child: InkWell(
                        onTap: () => widget.onResetPlayer(prediction),
                        child: const Icon(Icons.refresh, size: 14, color: Colors.orange),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Details',
                    child: InkWell(
                      onTap: () => _showPlayerDetails(context, prediction),
                      child: const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildEditableCell(
    StatPrediction prediction, String statKey, dynamic value, 
    String Function(dynamic) formatter, Color color, bool enabled,
  ) {
    if (!enabled) {
      return Text(
        formatter(value),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        textAlign: TextAlign.center,
      );
    }
    
    return InkWell(
      onTap: () => _showEditDialog(prediction, statKey, value, formatter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: prediction.isEdited ? Colors.orange.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Text(
          formatter(value),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEditableTierCell(StatPrediction prediction, String statKey, int? tier, Color color) {
    return InkWell(
      onTap: () => _showTierEditDialog(prediction, statKey, tier),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: prediction.isEdited ? Colors.orange.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Center(
          child: TierIndicator(tier: tier, tierType: statKey.replaceAll('Tier', ''), compact: true),
        ),
      ),
    );
  }

  void _showEditDialog(StatPrediction prediction, String statKey, dynamic value, String Function(dynamic) formatter) {
    final controller = TextEditingController();
    String displayValue = statKey == 'tgtShare' 
        ? (value * 100).toStringAsFixed(1) 
        : value.toString();
    controller.text = displayValue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${_getStatDisplayName(statKey)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${prediction.playerName} (${prediction.team})'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                labelText: _getStatDisplayName(statKey),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              try {
                dynamic newValue = statKey == 'tgtShare' 
                    ? double.parse(controller.text) / 100 
                    : (statKey == 'wrRank' ? int.parse(controller.text) : double.parse(controller.text));
                
                widget.onValueChanged(prediction, 'ny${statKey.replaceFirst(statKey[0], statKey[0].toUpperCase())}', newValue);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid value'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTierEditDialog(StatPrediction prediction, String statKey, int? currentTier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${_getStatDisplayName(statKey)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${prediction.playerName} (${prediction.team})'),
            const SizedBox(height: 16),
            const Text('Select Tier:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5].map((tier) => 
                ElevatedButton(
                  onPressed: () {
                    widget.onValueChanged(prediction, 'ny${statKey.replaceFirst(statKey[0], statKey[0].toUpperCase())}', tier);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTier == tier ? Colors.blue : null,
                  ),
                  child: Text('T$tier'),
                ),
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  String _getStatDisplayName(String statKey) {
    switch (statKey) {
      case 'tgtShare': return 'Target Share (%)';
      case 'wrRank': return 'Team Rank';
      case 'passOffTier': return 'Pass Offense Tier';
      case 'qbTier': return 'QB Tier';
      case 'runOffTier': return 'Run Offense Tier';
      default: return statKey;
    }
  }

  void _showPlayerDetails(BuildContext context, StatPrediction prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prediction.playerName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Position: ${prediction.position}'),
              Text('Team: ${prediction.team}'),
              const SizedBox(height: 16),
              const Text('2024 Stats:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Target Share: ${(prediction.tgtShare * 100).toStringAsFixed(1)}%'),
              Text('Team Rank: ${prediction.wrRank}'),
              Text('Fantasy Points: ${prediction.points.toStringAsFixed(1)}'),
              const SizedBox(height: 8),
              const Text('2025 Projections:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Target Share: ${(prediction.nyTgtShare * 100).toStringAsFixed(1)}%'),
              Text('Team Rank: ${prediction.nyWrRank}'),
              Text('Fantasy Points: ${prediction.nyPoints.toStringAsFixed(1)}'),
              const SizedBox(height: 8),
              if (prediction.isEdited)
                const Text('This player has custom modifications', 
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (prediction.isEdited)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onResetPlayer(prediction);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.orange)),
            ),
        ],
      ),
    );
  }

  Color _getTeamColor(String team) {
    final teamColors = {
      'KC': Colors.red.shade700, 'BAL': Colors.purple.shade800, 'BUF': Colors.blue.shade700,
      'MIA': Colors.teal.shade600, 'CIN': Colors.orange.shade700, 'PIT': Colors.yellow.shade700,
      'CLE': Colors.brown.shade700, 'HOU': Colors.blue.shade900, 'IND': Colors.blue.shade800,
      'JAX': Colors.teal.shade800, 'TEN': Colors.blue.shade600, 'DAL': Colors.blue.shade800,
      'PHI': Colors.green.shade700, 'NYG': Colors.blue.shade700, 'WAS': Colors.red.shade800,
      'SF': Colors.red.shade700, 'SEA': Colors.blue.shade800, 'LAR': Colors.blue.shade700,
      'ARI': Colors.red.shade800, 'GB': Colors.green.shade700, 'MIN': Colors.purple.shade700,
      'CHI': Colors.blue.shade800, 'DET': Colors.blue.shade600, 'TB': Colors.red.shade700,
      'NO': Colors.yellow.shade800, 'ATL': Colors.red.shade700, 'CAR': Colors.blue.shade700,
      'LV': Colors.black87, 'LAC': Colors.blue.shade600, 'DEN': Colors.orange.shade700,
    };
    return teamColors[team] ?? Colors.grey.shade600;
  }
}