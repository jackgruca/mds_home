import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme_aware_colors.dart';
import '../../utils/theme_config.dart';

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
  late Map<String, Map<dynamic, double>> _columnPercentiles;

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
    _columnPercentiles = {};
    
    // Get columns that need percentile shading
    final shadingColumns = widget.columns
        .where((col) => col.enablePercentileShading && col.numeric)
        .map((col) => col.key)
        .toList();

    for (final columnKey in shadingColumns) {
      final values = widget.rows
          .map((row) => row.data[columnKey])
          .whereType<num>()
          .toList();

      if (values.isNotEmpty) {
        values.sort();
        _columnPercentiles[columnKey] = {};

        for (final row in widget.rows) {
          final value = row.data[columnKey];
          if (value is num) {
            final rank = values.where((v) => v < value).length;
            final count = values.where((v) => v == value).length;
            _columnPercentiles[columnKey]![value] = (rank + 0.5 * count) / values.length;
          }
        }
      }
    }
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
        return 24;
      case MdsTableStyle.comparison:
        return 32;
      case MdsTableStyle.analytics:
        return 8;
      default:
        return 16;
    }
  }

  double _getHorizontalMargin() {
    switch (widget.style) {
      case MdsTableStyle.premium:
        return 20;
      case MdsTableStyle.analytics:
        return 8;
      default:
        return 16;
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
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(column.label),
        ),
        numeric: column.numeric,
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
          final percentile = _columnPercentiles[column.key]?[value];

          if (column.cellBuilder != null) {
            return DataCell(column.cellBuilder!(value, index, percentile));
          }

          return DataCell(_buildDefaultCell(column, value, percentile));
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

  Widget _buildDefaultCell(MdsTableColumn column, dynamic value, double? percentile) {
    Color? backgroundColor;
    TextStyle textStyle = const TextStyle(fontSize: 14);

    // Apply percentile shading if enabled
    if (column.enablePercentileShading && percentile != null && value is num) {
      backgroundColor = Color.fromRGBO(
        100, 140, 240, 
        0.1 + (percentile * 0.85)
      );
      
      if (percentile > 0.85) {
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
      }
    }

    String displayValue = _formatValue(column, value);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      alignment: column.numeric ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        displayValue,
        style: textStyle,
        textAlign: column.textAlign,
      ),
    );
  }

  String _formatValue(MdsTableColumn column, dynamic value) {
    if (value == null) return 'N/A';
    
    if (value is num && column.numeric) {
      if (column.isDoubleField) {
        return value.toStringAsFixed(2);
      } else {
        return value.toInt().toString();
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