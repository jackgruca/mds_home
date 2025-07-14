import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/models/custom_rankings/enhanced_attribute_library.dart';

class AttributeSelectionStep extends StatelessWidget {
  final String position;
  final List<EnhancedRankingAttribute> selectedAttributes;
  final Function(List<EnhancedRankingAttribute>) onAttributesChanged;

  const AttributeSelectionStep({
    super.key,
    required this.position,
    required this.selectedAttributes,
    required this.onAttributesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableAttributes = EnhancedAttributeLibrary.getAttributesForPosition(position);
    final groupedAttributes = _groupAttributesByCategory(availableAttributes);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Attributes for $position Rankings',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the statistics that are most important for ranking ${position}s. You can select multiple attributes from different categories.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildSelectionSummary(context),
          const SizedBox(height: 16),
          _buildSelectAllButtons(context, availableAttributes),
          const SizedBox(height: 24),
          ...groupedAttributes.entries.map((entry) => 
            _buildCategorySection(context, entry.key, entry.value)
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

  Widget _buildSelectionSummary(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selectedAttributes.isNotEmpty 
          ? ThemeConfig.successGreen.withValues(alpha: 0.1)
          : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selectedAttributes.isNotEmpty 
            ? ThemeConfig.successGreen.withValues(alpha: 0.3)
            : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selectedAttributes.isNotEmpty ? Icons.check_circle : Icons.info_outline,
            color: selectedAttributes.isNotEmpty 
              ? ThemeConfig.successGreen
              : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedAttributes.isNotEmpty 
                    ? '${selectedAttributes.length} attribute${selectedAttributes.length == 1 ? '' : 's'} selected'
                    : 'No attributes selected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selectedAttributes.isNotEmpty 
                      ? ThemeConfig.successGreen
                      : Colors.grey.shade600,
                  ),
                ),
                if (selectedAttributes.isNotEmpty)
                  Text(
                    selectedAttributes.map((attr) => attr.displayName).join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String category, List<EnhancedRankingAttribute> attributes) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    attributes.first.categoryEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _selectAllInCategory(attributes),
                child: const Text('Select All'),
              )
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: attributes.map((attr) => _buildAttributeCard(context, attr)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeCard(BuildContext context, EnhancedRankingAttribute attribute) {
    final theme = Theme.of(context);
    final isSelected = selectedAttributes.any((attr) => attr.id == attribute.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _toggleAttribute(attribute),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? ThemeConfig.darkNavy.withValues(alpha: 0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? ThemeConfig.darkNavy : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? ThemeConfig.darkNavy : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          attribute.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? ThemeConfig.darkNavy : null,
                          ),
                        ),
                        if (attribute.unit != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              attribute.unit!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (attribute.hasRealData)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: ThemeConfig.successGreen,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'REAL',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (attribute.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          attribute.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectAllButtons(BuildContext context, List<EnhancedRankingAttribute> availableAttributes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => onAttributesChanged(List.from(availableAttributes)),
          child: const Text('Select All'),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => onAttributesChanged([]),
          child: const Text('Deselect All'),
        ),
      ],
    );
  }

  void _selectAllInCategory(List<EnhancedRankingAttribute> categoryAttributes) {
    final List<EnhancedRankingAttribute> newSelected = List.from(selectedAttributes);
    for (final attr in categoryAttributes) {
      if (!newSelected.any((selectedAttr) => selectedAttr.id == attr.id)) {
        newSelected.add(attr);
      }
    }
    onAttributesChanged(newSelected);
  }

  void _toggleAttribute(EnhancedRankingAttribute attribute) {
    final List<EnhancedRankingAttribute> newSelected = List.from(selectedAttributes);
    
    if (selectedAttributes.any((attr) => attr.id == attribute.id)) {
      newSelected.removeWhere((attr) => attr.id == attribute.id);
    } else {
      newSelected.add(attribute);
    }
    
    onAttributesChanged(newSelected);
  }
}