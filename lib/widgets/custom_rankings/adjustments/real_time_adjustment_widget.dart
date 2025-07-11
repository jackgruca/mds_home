import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/services/custom_rankings/enhanced_calculation_engine.dart';
import 'attribute_manager_widget.dart';
import 'scenario_testing_widget.dart';

class RealTimeAdjustmentWidget extends StatefulWidget {
  final String position;
  final List<EnhancedRankingAttribute> initialAttributes;
  final List<CustomRankingResult> initialResults;
  final Function(List<CustomRankingResult>, List<EnhancedRankingAttribute>) onRankingsUpdated;

  const RealTimeAdjustmentWidget({
    super.key,
    required this.position,
    required this.initialAttributes,
    required this.initialResults,
    required this.onRankingsUpdated,
  });

  @override
  State<RealTimeAdjustmentWidget> createState() => _RealTimeAdjustmentWidgetState();
}

class _RealTimeAdjustmentWidgetState extends State<RealTimeAdjustmentWidget> 
    with TickerProviderStateMixin {
  late List<EnhancedRankingAttribute> _currentAttributes;
  late List<CustomRankingResult> _currentResults;
  final EnhancedCalculationEngine _engine = EnhancedCalculationEngine();
  bool _isCalculating = false;
  
  // History for undo/redo
  final List<List<EnhancedRankingAttribute>> _history = [];
  int _historyIndex = -1;
  
  // Tab controller for adjustment modes
  late TabController _adjustmentTabController;
  
  @override
  void initState() {
    super.initState();
    _adjustmentTabController = TabController(length: 3, vsync: this);
    _currentAttributes = List.from(widget.initialAttributes);
    _currentResults = List.from(widget.initialResults);
    _saveToHistory();
  }
  
  @override
  void dispose() {
    _adjustmentTabController.dispose();
    super.dispose();
  }


  void _saveToHistory() {
    // Remove any future history if we're not at the end
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    // Add current state to history
    _history.add(_currentAttributes.map((attr) => attr.copyWith()).toList());
    _historyIndex++;
    
    // Limit history size
    if (_history.length > 20) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _currentAttributes = _history[_historyIndex].map((attr) => attr.copyWith()).toList();
      });
      _recalculateRankings();
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _currentAttributes = _history[_historyIndex].map((attr) => attr.copyWith()).toList();
      });
      _recalculateRankings();
    }
  }

  Future<void> _recalculateRankings() async {
    if (_isCalculating) return;
    
    setState(() {
      _isCalculating = true;
    });

    try {
      final questionnaireId = DateTime.now().millisecondsSinceEpoch.toString();
      final results = await _engine.calculateRankings(
        questionnaireId: questionnaireId,
        position: widget.position,
        attributes: _currentAttributes,
      );

      setState(() {
        _currentResults = results;
        _isCalculating = false;
      });

      widget.onRankingsUpdated(_currentResults, _currentAttributes);
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  void _updateAttributeWeight(String attributeId, double newWeight) {
    setState(() {
      final index = _currentAttributes.indexWhere((attr) => attr.id == attributeId);
      if (index >= 0) {
        _currentAttributes[index] = _currentAttributes[index].copyWith(weight: newWeight);
      }
    });
    
    // Auto-normalize weights to sum to 100%
    _normalizeWeights();
    _saveToHistory();
    _recalculateRankings();
  }

  void _normalizeWeights() {
    final totalWeight = _currentAttributes.fold(0.0, (sum, attr) => sum + attr.weight);
    if (totalWeight > 0) {
      for (int i = 0; i < _currentAttributes.length; i++) {
        _currentAttributes[i] = _currentAttributes[i].copyWith(
          weight: _currentAttributes[i].weight / totalWeight
        );
      }
    }
  }

  void _resetToEqual() {
    if (_currentAttributes.isEmpty) return;
    
    final equalWeight = 1.0 / _currentAttributes.length;
    setState(() {
      _currentAttributes = _currentAttributes.map((attr) => 
        attr.copyWith(weight: equalWeight)
      ).toList();
    });
    
    _saveToHistory();
    _recalculateRankings();
  }

  void _clearWeights() {
    setState(() {
      _currentAttributes = _currentAttributes.map((attr) => 
        attr.copyWith(weight: 0.0)
      ).toList();
    });
    
    _saveToHistory();
    _recalculateRankings();
  }

  void _onAttributesChanged(List<EnhancedRankingAttribute> newAttributes) {
    setState(() {
      _currentAttributes = newAttributes;
    });
    _saveToHistory();
    _recalculateRankings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalWeight = _currentAttributes.fold(0.0, (sum, attr) => sum + attr.weight);
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: TabBar(
            controller: _adjustmentTabController,
            tabs: const [
              Tab(text: 'Adjust Weights', icon: Icon(Icons.tune)),
              Tab(text: 'Manage Attributes', icon: Icon(Icons.add_circle)),
              Tab(text: 'What-If Scenarios', icon: Icon(Icons.science)),
            ],
          ),
        ),
        if (_isCalculating) _buildLoadingIndicator(),
        Expanded(
          child: TabBarView(
            controller: _adjustmentTabController,
            children: [
              _buildWeightAdjustmentTab(context, totalWeight),
              _buildAttributeManagerTab(context),
              _buildScenarioTestingTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightAdjustmentTab(BuildContext context, double totalWeight) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, totalWeight),
          _buildQuickActions(context),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _currentAttributes.length,
              itemBuilder: (context, index) => _buildAttributeSlider(
                context, 
                _currentAttributes[index]
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeManagerTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AttributeManagerWidget(
        position: widget.position,
        currentAttributes: _currentAttributes,
        onAttributesChanged: _onAttributesChanged,
      ),
    );
  }

  Widget _buildScenarioTestingTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ScenarioTestingWidget(
        position: widget.position,
        baseAttributes: _currentAttributes,
        baseResults: _currentResults,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double totalWeight) {
    final theme = Theme.of(context);
    final canUndo = _historyIndex > 0;
    final canRedo = _historyIndex < _history.length - 1;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: ThemeConfig.darkNavy),
              const SizedBox(width: 8),
              Text(
                'Real-Time Adjustments',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: canUndo ? _undo : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: canRedo ? _redo : null,
                tooltip: 'Redo',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeConfig.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ThemeConfig.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: ThemeConfig.successGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Weights automatically balance to 100% as you adjust',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Center(
        child: SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            backgroundColor: Colors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.darkNavy),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetToEqual,
              icon: const Icon(Icons.balance, size: 16),
              label: const Text('Equal Weights'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeConfig.darkNavy,
                side: const BorderSide(color: ThemeConfig.darkNavy),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearWeights,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeSlider(BuildContext context, EnhancedRankingAttribute attribute) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                attribute.categoryEmoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attribute.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      attribute.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeConfig.darkNavy,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(attribute.weight * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ThemeConfig.darkNavy,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: ThemeConfig.darkNavy,
              overlayColor: ThemeConfig.darkNavy.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: attribute.weight,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (value) {
                _updateAttributeWeight(attribute.id, value);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0% - Not Important',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '100% - Most Important',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tip: Higher weights mean this attribute has more impact on rankings. All weights automatically balance to 100%.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}