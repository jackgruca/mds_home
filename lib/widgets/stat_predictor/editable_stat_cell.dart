import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/projections/stat_prediction.dart';

class EditableStatCell extends StatefulWidget {
  final StatPrediction prediction;
  final String statName;
  final dynamic currentValue;
  final dynamic predictedValue;
  final String valueType;
  final bool isEditable;
  final Function(StatPrediction, String, dynamic) onValueChanged;

  const EditableStatCell({
    super.key,
    required this.prediction,
    required this.statName,
    required this.currentValue,
    required this.predictedValue,
    required this.valueType,
    required this.isEditable,
    required this.onValueChanged,
  });

  @override
  State<EditableStatCell> createState() => _EditableStatCellState();
}

class _EditableStatCellState extends State<EditableStatCell> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getDisplayValue(widget.predictedValue));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _saveValue();
    }
  }

  String _getDisplayValue(dynamic value) {
    if (value == null) return 'N/A';
    
    switch (widget.valueType) {
      case 'percentage':
        final doubleVal = _toDouble(value);
        return (doubleVal * 100).toStringAsFixed(1);
      case 'double':
        final doubleVal = _toDouble(value);
        return doubleVal.toStringAsFixed(2);
      case 'int':
        final intVal = _toInt(value);
        return intVal.toString();
      default:
        return value.toString();
    }
  }

  String _getFormattedDisplayValue(dynamic value) {
    if (value == null) return 'N/A';
    
    switch (widget.valueType) {
      case 'percentage':
        final doubleVal = _toDouble(value);
        return '${(doubleVal * 100).toStringAsFixed(1)}%';
      case 'double':
        final doubleVal = _toDouble(value);
        return doubleVal.toStringAsFixed(2);
      case 'int':
        final intVal = _toInt(value);
        return intVal.toString();
      default:
        return value.toString();
    }
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _startEditing() {
    if (!widget.isEditable) return;
    
    setState(() {
      _isEditing = true;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _saveValue() {
    final inputText = _controller.text.trim();
    
    try {
      dynamic newValue;
      
      switch (widget.valueType) {
        case 'percentage':
          // Input is expected as percentage (e.g., "25.5" for 25.5%)
          final percentage = double.parse(inputText);
          newValue = percentage / 100; // Convert to decimal
          break;
        case 'double':
          newValue = double.parse(inputText);
          break;
        case 'int':
          newValue = int.parse(inputText);
          break;
        default:
          newValue = inputText;
      }
      
      // Validate the value
      if (_isValidValue(newValue)) {
        widget.onValueChanged(widget.prediction, widget.statName, newValue);
      } else {
        _showValidationError();
        _resetValue();
      }
    } catch (e) {
      _showValidationError();
      _resetValue();
    }
    
    setState(() {
      _isEditing = false;
    });
  }

  bool _isValidValue(dynamic value) {
    switch (widget.statName) {
      case 'tgtShare':
        final doubleVal = _toDouble(value);
        return doubleVal >= 0.0 && doubleVal <= 1.0;
      case 'wrRank':
        final intVal = _toInt(value);
        return intVal >= 1 && intVal <= 10;
      case 'points':
        final doubleVal = _toDouble(value);
        return doubleVal >= 0.0 && doubleVal <= 500.0;
      case 'yards':
        final intVal = _toInt(value);
        return intVal >= 0 && intVal <= 2500;
      case 'touchdowns':
        final intVal = _toInt(value);
        return intVal >= 0 && intVal <= 25;
      case 'receptions':
        final intVal = _toInt(value);
        return intVal >= 0 && intVal <= 200;
      case 'games':
        final intVal = _toInt(value);
        return intVal >= 0 && intVal <= 17;
      default:
        return true;
    }
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid value for ${widget.statName}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetValue() {
    _controller.text = _getDisplayValue(widget.predictedValue);
  }

  void _cancelEditing() {
    _resetValue();
    setState(() {
      _isEditing = false;
    });
  }

  Color _getCellColor() {
    if (!widget.isEditable) return Colors.grey[100]!;
    if (_isEditing) return Colors.blue[50]!;
    if (widget.prediction.isEdited) return Colors.orange[50]!;
    return Colors.transparent;
  }

  TextStyle _getTextStyle() {
    if (!widget.isEditable) {
      return TextStyle(color: Colors.grey[600]);
    }
    
    if (widget.prediction.isEdited) {
      return const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.orange,
      );
    }
    
    return const TextStyle();
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (widget.valueType) {
      case 'percentage':
      case 'double':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ];
      case 'int':
        return [
          FilteringTextInputFormatter.digitsOnly,
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getCellColor(),
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 12),
                inputFormatters: _getInputFormatters(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (_) => _saveValue(),
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _saveValue,
                  child: const Icon(Icons.check, size: 16, color: Colors.green),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: _cancelEditing,
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: widget.isEditable ? _startEditing : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getCellColor(),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getFormattedDisplayValue(widget.predictedValue),
                style: _getTextStyle(),
                textAlign: TextAlign.right,
              ),
            ),
            if (widget.isEditable)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.edit,
                  size: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StatComparisonCell extends StatelessWidget {
  final dynamic currentValue;
  final dynamic predictedValue;
  final String valueType;
  final bool showChange;

  const StatComparisonCell({
    super.key,
    required this.currentValue,
    required this.predictedValue,
    required this.valueType,
    this.showChange = true,
  });

  @override
  Widget build(BuildContext context) {
    final change = _calculateChange();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current value
        Text(
          _getFormattedValue(currentValue),
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        
        // Predicted value (larger, prominent)
        Text(
          _getFormattedValue(predictedValue),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Change indicator
        if (showChange && change != null)
          Text(
            _getChangeText(change),
            style: TextStyle(
              fontSize: 10,
              color: _getChangeColor(change),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  String _getFormattedValue(dynamic value) {
    if (value == null) return 'N/A';
    
    switch (valueType) {
      case 'percentage':
        final doubleVal = _toDouble(value);
        return '${(doubleVal * 100).toStringAsFixed(1)}%';
      case 'double':
        final doubleVal = _toDouble(value);
        return doubleVal.toStringAsFixed(1);
      case 'int':
        final intVal = _toInt(value);
        return intVal.toString();
      default:
        return value.toString();
    }
  }

  double? _calculateChange() {
    if (currentValue == null || predictedValue == null) return null;
    
    final current = _toDouble(currentValue);
    final predicted = _toDouble(predictedValue);
    
    if (current == 0) return null;
    
    return ((predicted - current) / current) * 100;
  }

  String _getChangeText(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  Color _getChangeColor(double change) {
    if (change > 5) return Colors.green;
    if (change < -5) return Colors.red;
    return Colors.grey;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}