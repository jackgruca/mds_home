import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme_aware_colors.dart';
import '../../utils/theme_config.dart';
import '../../services/rankings/ranking_cell_shading_service.dart';

enum MdsTableStyle {
  standard,    // Basic clean table with alternating rows
  premium,     // Enhanced with gradients, shadows, and animations (like Fantasy Big Board)
  analytics,   // Compact with emphasis on data density
  comparison,  // For side-by-side comparisons
}

enum MdsTableDensity {
  compact,     // 36px row height
  standard,    // 48px row height  
  comfortable, // 56px row height (like Fantasy Big Board)
}

class MdsTableColumn {
  final String key;
  final String label;
  final bool sortable;
  final bool numeric;
  final bool enablePercentileShading;
  final double? width;
  final Widget Function(dynamic value, int rowIndex, double? percentile)? cellBuilder;
  final TextAlign? textAlign;
  final String? tooltip;
  final bool isDoubleField; // For proper decimal formatting

  const MdsTableColumn({
    required this.key,
    required this.label,
    this.sortable = true,
    this.numeric = false,
    this.enablePercentileShading = false,
    this.width,
    this.cellBuilder,
    this.textAlign,
    this.tooltip,
    this.isDoubleField = false,
  });
}

class MdsTableRow {
  final String id;
  final Map<String, dynamic> data;
  final bool highlighted;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const MdsTableRow({
    required this.id,
    required this.data,
    this.highlighted = false,
    this.backgroundColor,
    this.onTap,
  });
}

class MdsTable extends StatefulWidget {
  final List<MdsTableColumn> columns;
  final List<MdsTableRow> rows;
  final MdsTableStyle style;
  final MdsTableDensity density;
  final String? sortColumn;
  final bool sortAscending;
  final Function(String column, bool ascending)? onSort;
  final bool showBorder;
  final EdgeInsets? padding;
  final bool enableHapticFeedback;

  const MdsTable({
    super.key,
    required this.columns,
    required this.rows,
    this.style = MdsTableStyle.premium,
    this.density = MdsTableDensity.comfortable,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.showBorder = true,
    this.padding,
    this.enableHapticFeedback = true,
  });

  @override
  State<MdsTable> createState() => _MdsTableState();
}

class _MdsTableState extends State<MdsTable> {
  late Map<String, Map<String, double>> _percentileCache;

  @override
  void initState() {
    super.initState();
    _calculatePercentiles();
  }

  @override
  void didUpdateWidget(MdsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows || oldWidget.columns != widget.columns) {
      _calculatePercentiles();
    }
  }

  void _calculatePercentiles() {
    // Get columns that need percentile shading
    final shadingColumns = widget.columns
        .where((col) => col.enablePercentileShading && col.numeric)
        .map((col) => col.key)
        .toList();

    // Convert rows to format expected by RankingCellShadingService
    final rankings = widget.rows.map((row) => row.data).toList();
    
    // Use the same percentile calculation as WR Rankings
    _percentileCache = RankingCellShadingService.calculatePercentiles(rankings, shadingColumns);
  }

  @override
  Widget build(BuildContext context) {
    final decoration = _getTableDecoration();
    final borderRadius = _getBorderRadius();

    Widget table = DataTable(
      headingRowColor: WidgetStateProperty.all(_getHeaderColor()),
      headingTextStyle: _getHeaderTextStyle(),
      dataRowMinHeight: _getRowHeight(),
      dataRowMaxHeight: _getRowHeight(),
      showCheckboxColumn: false,
      sortColumnIndex: _getSortColumnIndex(),
      sortAscending: widget.sortAscending,
      columnSpacing: _getColumnSpacing(),
      horizontalMargin: _getHorizontalMargin(),
      dividerThickness: widget.style == MdsTableStyle.premium ? 0 : 0.5,
      border: widget.showBorder ? _getTableBorder() : null,
      columns: _buildColumns(),
      rows: _buildRows(),
    );

    if (widget.style == MdsTableStyle.premium) {
      table = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: table,
      );
    }

    Widget container = Container(
      margin: widget.padding ?? _getDefaultMargin(),
      decoration: decoration,
      child: decoration != null 
          ? ClipRRect(
              borderRadius: borderRadius,
              child: table,
            )
          : table,
    );

    if (widget.style == MdsTableStyle.premium) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: container,
      );
    }

    return container;
  }

  BoxDecoration? _getTableDecoration() {
    switch (widget.style) {
      case MdsTableStyle.premium:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ThemeConfig.gold.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.darkNavy.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case MdsTableStyle.comparison:
        return BoxDecoration(
          color: ThemeAwareColors.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case MdsTableStyle.analytics:
        return BoxDecoration(
          color: ThemeAwareColors.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeAwareColors.getDividerColor(context),
            width: 1,
          ),
        );
      default:
        return null;
    }
  }

  BorderRadius _getBorderRadius() {
    switch (widget.style) {
      case MdsTableStyle.premium:
        return BorderRadius.circular(16);
      case MdsTableStyle.comparison:
        return BorderRadius.circular(12);
      default:
        return BorderRadius.circular(8);
    }
  }

  Color _getHeaderColor() {
    switch (widget.style) {
      case MdsTableStyle.comparison:
        return ThemeConfig.darkNavy;
      case MdsTableStyle.analytics:
        return Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey.shade800 
          : Colors.grey.shade200;
      default:
        return ThemeAwareColors.getTableHeaderColor(context);
    }
  }

  TextStyle _getHeaderTextStyle() {
    switch (widget.style) {
      case MdsTableStyle.premium:
        return TextStyle(
          color: ThemeAwareColors.getTableHeaderTextColor(context),
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        );
      case MdsTableStyle.comparison:
        return const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        );
      default:
        return TextStyle(
          color: ThemeAwareColors.getTableHeaderTextColor(context),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        );
    }
  }

  double _getRowHeight() {
    switch (widget.density) {
      case MdsTableDensity.compact:
        return 36;
      case MdsTableDensity.comfortable:
        return 56;
      default:
        return 48;
    }
  }

  double _getColumnSpacing() {
    switch (widget.style) {
      case MdsTableStyle.premium:
        return 8; // Much more compact for narrower headers
      case MdsTableStyle.comparison:
        return 12;
      case MdsTableStyle.analytics:
        return 6;
      default:
        return 8;
    }
  }

  double _getHorizontalMargin() {
    switch (widget.style) {
      case MdsTableStyle.premium:
        return 8; // Reduced margin for more compact layout
      case MdsTableStyle.analytics:
        return 6;
      default:
        return 8;
    }
  }

  EdgeInsets _getDefaultMargin() {
    switch (widget.style) {
      case MdsTableStyle.premium:
        return const EdgeInsets.all(16);
      case MdsTableStyle.analytics:
        return const EdgeInsets.all(8);
      default:
        return const EdgeInsets.all(12);
    }
  }

  TableBorder? _getTableBorder() {
    switch (widget.style) {
      case MdsTableStyle.analytics:
        return TableBorder.all(
          color: ThemeAwareColors.getDividerColor(context),
          width: 0.5,
        );
      default:
        return null;
    }
  }

  int? _getSortColumnIndex() {
    if (widget.sortColumn == null) return null;
    final index = widget.columns.indexWhere((col) => col.key == widget.sortColumn);
    return index >= 0 ? index : null;
  }

  List<DataColumn> _buildColumns() {
    return widget.columns.map((column) {
      return DataColumn(
        label: Expanded( // Use Expanded to fill available width
          child: Center( // Then center within that width
            child: Text(
              column.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        numeric: false, // Always false to prevent DataTable's right-alignment
        tooltip: column.tooltip,
        onSort: column.sortable && widget.onSort != null
            ? (columnIndex, ascending) {
                if (widget.enableHapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                widget.onSort!(column.key, ascending);
              }
            : null,
      );
    }).toList();
  }

  List<DataRow> _buildRows() {
    return widget.rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;

      return DataRow(
        color: _getRowColor(index, row),
        cells: widget.columns.map((column) {
          final value = row.data[column.key];

          if (column.cellBuilder != null) {
            return DataCell(column.cellBuilder!(value, index, null));
          }

          return DataCell(_buildDefaultCell(column, value, index));
        }).toList(),
        onSelectChanged: row.onTap != null ? (_) => row.onTap!() : null,
      );
    }).toList();
  }

  WidgetStateProperty<Color?> _getRowColor(int index, MdsTableRow row) {
    return WidgetStateProperty.resolveWith<Color?>((states) {
      if (row.backgroundColor != null) return row.backgroundColor;
      if (row.highlighted) {
        return ThemeConfig.gold.withOpacity(0.1);
      }
      return ThemeAwareColors.getTableRowColor(context, index);
    });
  }

  Widget _buildDefaultCell(MdsTableColumn column, dynamic value, int rowIndex) {
    // Use density cell highlighting if percentile shading is enabled
    if (column.enablePercentileShading && column.numeric) {
      // Check if value is numeric or can be parsed as numeric
      bool isNumericValue = false;
      if (value is num) {
        isNumericValue = true;
      } else if (value is String && value != 'N/A' && value.isNotEmpty) {
        // Try to parse string as number
        final cleaned = value.replaceAll(',', '').trim();
        final parsed = double.tryParse(cleaned);
        isNumericValue = parsed != null && parsed.isFinite;
      }
      
      if (isNumericValue) {
        // Return density cell directly - it has its own left alignment
        return RankingCellShadingService.buildDensityCell(
          column: column.key,
          value: value,
          rankValue: value,
          showRanks: false,
          percentileCache: _percentileCache,
          formatValue: (val, col) => _formatValue(column, val),
          width: double.infinity, // Use full cell width
          height: _getRowHeight() - 4, // Slightly smaller for padding
        );
      }
    }

    // Default cell for non-numeric or non-percentile columns (including strings)
    String displayValue = _formatValue(column, value);

    return Align(
      alignment: Alignment.centerLeft, // Force left alignment
      child: Padding(
        padding: const EdgeInsets.only(left: 6, right: 2), // Match density cell padding
        child: Text(
          displayValue,
          style: const TextStyle(fontSize: 11), // Match density cell font size
          textAlign: TextAlign.left, // Text is left-aligned
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  String _formatValue(MdsTableColumn column, dynamic value) {
    if (value == null || value == '') return 'N/A';
    
    // If it's already a number, format based on column type
    if (value is num && column.numeric) {
      if (column.isDoubleField) {
        return value.toStringAsFixed(2);
      } else {
        return value.toInt().toString();
      }
    }
    
    // If it's a string but should be numeric, try to format properly
    if (value is String && column.numeric) {
      final cleaned = value.replaceAll(',', '').trim();
      final parsed = double.tryParse(cleaned);
      if (parsed != null && parsed.isFinite) {
        if (column.isDoubleField) {
          return parsed.toStringAsFixed(2);
        } else if (parsed == parsed.roundToDouble()) {
          // It's a whole number, show without decimals
          return parsed.toInt().toString();
        } else {
          // Has decimals, keep them
          return value.toString();
        }
      }
    }
    
    return value.toString();
  }
}

// Specialized cell widgets for common use cases
class MdsTableRankCell extends StatelessWidget {
  final int rank;
  final Color? backgroundColor;

  const MdsTableRankCell({
    super.key,
    required this.rank,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? ThemeConfig.gold,
            (backgroundColor ?? ThemeConfig.gold).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class MdsTablePercentileCell extends StatelessWidget {
  final double value;
  final double? percentile;
  final String Function(double)? formatter;

  const MdsTablePercentileCell({
    super.key,
    required this.value,
    this.percentile,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    TextStyle textStyle = const TextStyle(fontSize: 14);

    if (percentile != null) {
      backgroundColor = Color.fromRGBO(
        100, 140, 240, 
        0.1 + (percentile! * 0.85)
      );
      
      if (percentile! > 0.85) {
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
      }
    }

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        formatter?.call(value) ?? value.toStringAsFixed(1),
        style: textStyle,
      ),
    );
  }
}

class MdsTableTeamCell extends StatelessWidget {
  final String teamCode;
  final String? playerName;
  final Widget Function(String)? logoBuilder;

  const MdsTableTeamCell({
    super.key,
    required this.teamCode,
    this.playerName,
    this.logoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (logoBuilder != null) logoBuilder!(teamCode),
        if (logoBuilder != null) const SizedBox(width: 8),
        Text(
          playerName ?? teamCode,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class MdsTableTierCell extends StatelessWidget {
  final int tier;
  final Color Function(int)? colorBuilder;

  const MdsTableTierCell({
    super.key,
    required this.tier,
    this.colorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorBuilder?.call(tier) ?? ThemeConfig.darkNavy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$tier',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
} 