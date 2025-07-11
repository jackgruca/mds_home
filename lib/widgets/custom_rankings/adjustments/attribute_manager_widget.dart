import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/models/custom_rankings/enhanced_attribute_library.dart';

class AttributeManagerWidget extends StatefulWidget {
  final String position;
  final List<EnhancedRankingAttribute> currentAttributes;
  final Function(List<EnhancedRankingAttribute>) onAttributesChanged;

  const AttributeManagerWidget({
    super.key,
    required this.position,
    required this.currentAttributes,
    required this.onAttributesChanged,
  });

  @override
  State<AttributeManagerWidget> createState() => _AttributeManagerWidgetState();
}

class _AttributeManagerWidgetState extends State<AttributeManagerWidget> {
  late List<EnhancedRankingAttribute> _availableAttributes;
  late List<EnhancedRankingAttribute> _selectedAttributes;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _availableAttributes = EnhancedAttributeLibrary.getAttributesForPosition(widget.position);
    _selectedAttributes = List.from(widget.currentAttributes);
  }

  @override
  void didUpdateWidget(AttributeManagerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAttributes != widget.currentAttributes) {
      _selectedAttributes = List.from(widget.currentAttributes);
    }
  }

  List<EnhancedRankingAttribute> get _filteredAvailableAttributes {
    return _availableAttributes.where((attr) {
      final matchesSearch = _searchQuery.isEmpty ||
          attr.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          attr.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final notSelected = !_selectedAttributes.any((selected) => selected.id == attr.id);
      return matchesSearch && notSelected;
    }).toList();
  }

  void _addAttribute(EnhancedRankingAttribute attribute) {
    setState(() {
      // Add with default weight
      final attributeWithWeight = attribute.copyWith(weight: 0.2);
      _selectedAttributes.add(attributeWithWeight);
    });
    widget.onAttributesChanged(_selectedAttributes);
  }

  void _removeAttribute(EnhancedRankingAttribute attribute) {
    setState(() {
      _selectedAttributes.removeWhere((attr) => attr.id == attribute.id);
    });
    widget.onAttributesChanged(_selectedAttributes);
  }

  void _updateAttributeWeight(String attributeId, double weight) {
    setState(() {
      final index = _selectedAttributes.indexWhere((attr) => attr.id == attributeId);
      if (index >= 0) {
        _selectedAttributes[index] = _selectedAttributes[index].copyWith(weight: weight);
      }
    });
    widget.onAttributesChanged(_selectedAttributes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildSearchBar(context),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildSelectedAttributesPanel(context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAvailableAttributesPanel(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        const Icon(Icons.tune, color: ThemeConfig.darkNavy),
        const SizedBox(width: 8),
        Text(
          'Manage Attributes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ThemeConfig.darkNavy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_selectedAttributes.length} selected',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeConfig.darkNavy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search attributes...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ThemeConfig.darkNavy, width: 2),
        ),
      ),
    );
  }

  Widget _buildSelectedAttributesPanel(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeConfig.successGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: ThemeConfig.successGreen),
                const SizedBox(width: 8),
                Text(
                  'Selected Attributes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.successGreen,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedAttributes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No attributes selected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'Add attributes from the right panel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _selectedAttributes.length,
                    itemBuilder: (context, index) => _buildSelectedAttributeCard(
                      context,
                      _selectedAttributes[index],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableAttributesPanel(BuildContext context) {
    final theme = Theme.of(context);
    final groupedAttributes = _groupAttributesByCategory(_filteredAvailableAttributes);
    
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeConfig.darkNavy.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle, color: ThemeConfig.darkNavy),
                const SizedBox(width: 8),
                Text(
                  'Available Attributes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.darkNavy,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredAvailableAttributes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'All attributes selected'
                              : 'No attributes found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: groupedAttributes.entries.map((entry) =>
                        _buildAttributeCategory(context, entry.key, entry.value)
                    ).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAttributeCard(BuildContext context, EnhancedRankingAttribute attribute) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    attribute.categoryEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attribute.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ThemeConfig.darkNavy,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(attribute.weight * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeAttribute(attribute),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: ThemeConfig.darkNavy,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: ThemeConfig.darkNavy,
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: attribute.weight,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) => _updateAttributeWeight(attribute.id, value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeCategory(BuildContext context, String category, List<EnhancedRankingAttribute> attributes) {
    final theme = Theme.of(context);
    
    return ExpansionTile(
      leading: Text(
        attributes.first.categoryEmoji,
        style: const TextStyle(fontSize: 18),
      ),
      title: Text(
        category,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text('${attributes.length} attribute${attributes.length == 1 ? '' : 's'}'),
      children: attributes.map((attr) => _buildAvailableAttributeCard(context, attr)).toList(),
    );
  }

  Widget _buildAvailableAttributeCard(BuildContext context, EnhancedRankingAttribute attribute) {
    final theme = Theme.of(context);
    
    return ListTile(
      title: Text(
        attribute.displayName,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: attribute.description != null
          ? Text(
              attribute.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attribute.hasRealData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: ThemeConfig.successGreen,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'REAL',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle, color: ThemeConfig.darkNavy),
            onPressed: () => _addAttribute(attribute),
          ),
        ],
      ),
    );
  }

  Map<String, List<EnhancedRankingAttribute>> _groupAttributesByCategory(List<EnhancedRankingAttribute> attributes) {
    final Map<String, List<EnhancedRankingAttribute>> grouped = {};
    for (final attr in attributes) {
      if (!grouped.containsKey(attr.category)) {
        grouped[attr.category] = [];
      }
      grouped[attr.category]!.add(attr);
    }
    return grouped;
  }
}