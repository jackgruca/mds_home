import 'package:flutter/material.dart';
import '../../models/custom_weight_config.dart';
import '../../utils/theme_config.dart';

class WeightAdjustmentPanel extends StatefulWidget {
  final String position;
  final CustomWeightConfig currentWeights;
  final Function(CustomWeightConfig) onWeightsChanged;
  final VoidCallback? onReset;
  final bool isVisible;

  const WeightAdjustmentPanel({
    super.key,
    required this.position,
    required this.currentWeights,
    required this.onWeightsChanged,
    this.onReset,
    required this.isVisible,
  });

  @override
  State<WeightAdjustmentPanel> createState() => _WeightAdjustmentPanelState();
}

class _WeightAdjustmentPanelState extends State<WeightAdjustmentPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late CustomWeightConfig _workingWeights;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -300.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _workingWeights = widget.currentWeights;
    
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(WeightAdjustmentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
    
    if (widget.currentWeights != oldWidget.currentWeights) {
      setState(() {
        _workingWeights = widget.currentWeights;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateWeight(String variable, double value) {
    setState(() {
      final updatedWeights = Map<String, double>.from(_workingWeights.weights);
      updatedWeights[variable] = value;
      _workingWeights = _workingWeights.copyWith(weights: updatedWeights);
    });
    
    // Notify parent immediately for live updates
    widget.onWeightsChanged(_workingWeights);
  }

  void _resetToDefaults() {
    if (widget.onReset != null) {
      widget.onReset!();
    }
  }

  void _normalizeWeights() {
    final normalized = _workingWeights.normalize();
    setState(() {
      _workingWeights = normalized;
    });
    widget.onWeightsChanged(normalized);
  }

  Color _getWeightColor(double weight) {
    if (weight >= 0.15) return Colors.red.shade600;
    if (weight >= 0.10) return Colors.orange.shade600;
    if (weight >= 0.05) return Colors.blue.shade600;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Container(
            width: 300,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(child: _buildWeightControls()),
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConfig.darkNavy,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customize Rankings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.position.toUpperCase()} Weight Adjustment',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _workingWeights.isNormalized 
                  ? Colors.green.shade600 
                  : Colors.blue.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Total: ${(_workingWeights.totalWeight * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightControls() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Adjust the weight of each factor in the ranking calculation:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ..._workingWeights.weights.entries.map((entry) {
          return _buildWeightSlider(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildWeightSlider(String variable, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                variable,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getWeightColor(value),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(value * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getWeightColor(value),
              inactiveTrackColor: _getWeightColor(value).withOpacity(0.3),
              thumbColor: _getWeightColor(value),
              overlayColor: _getWeightColor(value).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 0.30,
              divisions: 60,
              onChanged: (newValue) => _updateWeight(variable, newValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_workingWeights.isNormalized)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: _normalizeWeights,
                icon: const Icon(Icons.balance, size: 16),
                label: const Text('Normalize to 100%'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset to Defaults'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.darkNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Higher weights give more influence to that statistic in the ranking.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}