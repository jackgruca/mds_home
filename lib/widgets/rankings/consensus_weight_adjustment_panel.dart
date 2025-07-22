import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/consensus_weight_config.dart';
import '../../utils/theme_config.dart';

class ConsensusWeightAdjustmentPanel extends StatefulWidget {
  final String position;
  final ConsensusWeightConfig currentWeights;
  final Function(ConsensusWeightConfig) onWeightsChanged;
  final VoidCallback? onReset;
  final VoidCallback? onClose;
  final bool isVisible;

  const ConsensusWeightAdjustmentPanel({
    super.key,
    required this.position,
    required this.currentWeights,
    required this.onWeightsChanged,
    this.onReset,
    this.onClose,
    required this.isVisible,
  });

  @override
  State<ConsensusWeightAdjustmentPanel> createState() => _ConsensusWeightAdjustmentPanelState();
}

class _ConsensusWeightAdjustmentPanelState extends State<ConsensusWeightAdjustmentPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late ConsensusWeightConfig _workingWeights;
  Timer? _updateDebounce;
  
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
  void didUpdateWidget(ConsensusWeightAdjustmentPanel oldWidget) {
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
    _updateDebounce?.cancel();
    super.dispose();
  }

  void _updatePlatformWeight(String platform, double value) {
    setState(() {
      _workingWeights = _workingWeights.updateWeight(platform, value);
    });
    
    // Debounce the parent notification to prevent rapid updates
    _updateDebounce?.cancel();
    _updateDebounce = Timer(const Duration(milliseconds: 150), () {
      widget.onWeightsChanged(_workingWeights);
    });
  }

  void _toggleCustomRankings(bool enabled) {
    setState(() {
      if (enabled) {
        _workingWeights = _workingWeights.enableCustomRankings(0.125);
      } else {
        _workingWeights = _workingWeights.disableCustomRankings();
      }
    });
    
    widget.onWeightsChanged(_workingWeights);
  }

  void _updateCustomRankingsWeight(double value) {
    setState(() {
      _workingWeights = _workingWeights.updateWeight('My Custom Rankings', value);
    });
    
    // Debounce the parent notification to prevent rapid updates
    _updateDebounce?.cancel();
    _updateDebounce = Timer(const Duration(milliseconds: 150), () {
      widget.onWeightsChanged(_workingWeights);
    });
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
            width: 320,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consensus Weights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Customize Platform & Custom Rankings',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
              if (_workingWeights.includeCustomRankings) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeConfig.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CUSTOM ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
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
          'Platform Rankings:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Adjust the weight of each ranking platform:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        
        // Platform weight sliders
        ..._workingWeights.platformWeights.entries.map((entry) {
          return _buildWeightSlider(entry.key, entry.value, false);
        }).toList(),
        
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // Custom Rankings Section
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Custom Rankings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Include your personal rankings in consensus',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _workingWeights.includeCustomRankings,
              onChanged: _toggleCustomRankings,
              activeColor: ThemeConfig.gold,
            ),
          ],
        ),
        
        if (_workingWeights.includeCustomRankings) ...[
          const SizedBox(height: 16),
          _buildWeightSlider('My Custom Rankings', _workingWeights.customRankingsWeight, true),
        ],
      ],
    );
  }

  Widget _buildWeightSlider(String variable, double value, bool isCustom) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCustom ? ThemeConfig.gold.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCustom ? ThemeConfig.gold.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    variable,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCustom ? ThemeConfig.darkNavy : Colors.black87,
                    ),
                  ),
                  if (isCustom) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: ThemeConfig.gold,
                    ),
                  ],
                ],
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
              activeTrackColor: isCustom ? ThemeConfig.gold : _getWeightColor(value),
              inactiveTrackColor: (isCustom ? ThemeConfig.gold : _getWeightColor(value)).withOpacity(0.3),
              thumbColor: isCustom ? ThemeConfig.gold : _getWeightColor(value),
              overlayColor: (isCustom ? ThemeConfig.gold : _getWeightColor(value)).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 0.30,
              divisions: 60,
              onChanged: (newValue) {
                if (isCustom) {
                  _updateCustomRankingsWeight(newValue);
                } else {
                  _updatePlatformWeight(variable, newValue);
                }
              },
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
            'Tip: Enable custom rankings to include your personal player rankings in the consensus calculation.',
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