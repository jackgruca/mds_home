// lib/widgets/data/cross_category_query_builder.dart
import 'package:flutter/material.dart';
import '../../models/data_category.dart';

class CrossCategoryQueryBuilder extends StatefulWidget {
  final List<DataCategoryType> selectedCategories;
  final Function(List<DataCategoryType>) onCategoriesChanged;

  const CrossCategoryQueryBuilder({
    super.key,
    required this.selectedCategories,
    required this.onCategoriesChanged,
  });

  @override
  State<CrossCategoryQueryBuilder> createState() => _CrossCategoryQueryBuilderState();
}

class _CrossCategoryQueryBuilderState extends State<CrossCategoryQueryBuilder> {
  String? _selectedPlayer;
  String? _selectedTeam;
  String? _selectedSeason;
  String? _selectedPosition;

  final List<String> _samplePlayers = [
    'Lamar Jackson', 'Josh Allen', 'Derrick Henry', 'Cooper Kupp', 'Travis Kelce'
  ];
  
  final List<String> _teams = [
    'BAL', 'BUF', 'KC', 'LAR', 'DAL', 'GB', 'NE', 'SF', 'PHI', 'SEA'
  ];
  
  final List<String> _seasons = ['2024', '2023', '2022', '2021', '2020'];
  
  final List<String> _positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DST'];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category selection chips
          _buildCategorySelection(isDarkMode),
          
          if (widget.selectedCategories.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildFiltersSection(isDarkMode),
          ],
          
          if (widget.selectedCategories.length >= 2) ...[
            const SizedBox(height: 20),
            _buildQueryExamplesSection(isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySelection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Data Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DataCategory.allCategories.map((category) {
            final isSelected = widget.selectedCategories.contains(category.type);
            
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected ? Colors.white : category.color,
                  ),
                  const SizedBox(width: 6),
                  Text(category.name),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newCategories = List<DataCategoryType>.from(widget.selectedCategories);
                if (selected) {
                  newCategories.add(category.type);
                } else {
                  newCategories.remove(category.type);
                }
                widget.onCategoriesChanged(newCategories);
              },
              backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
              selectedColor: category.color,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (isDarkMode ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apply Filters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        // Filters in a responsive layout
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildFilterDropdown(
              'Player',
              _selectedPlayer,
              _samplePlayers,
              (value) => setState(() => _selectedPlayer = value),
              isDarkMode,
            ),
            _buildFilterDropdown(
              'Team',
              _selectedTeam,
              _teams,
              (value) => setState(() => _selectedTeam = value),
              isDarkMode,
            ),
            _buildFilterDropdown(
              'Season',
              _selectedSeason,
              _seasons,
              (value) => setState(() => _selectedSeason = value),
              isDarkMode,
            ),
            _buildFilterDropdown(
              'Position',
              _selectedPosition,
              _positions,
              (value) => setState(() => _selectedPosition = value),
              isDarkMode,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: widget.selectedCategories.isNotEmpty 
                  ? () => _executeQuery() 
                  : null,
              icon: const Icon(Icons.search),
              label: const Text('Execute Query'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear All'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
    bool isDarkMode,
  ) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            ),
            hint: Text(
              'Any $label',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildQueryExamplesSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Query Examples',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your current selection will analyze:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.selectedCategories.map((categoryType) {
                final category = DataCategory.getCategoryByType(categoryType);
                if (category == null) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        category.icon,
                        size: 16,
                        color: category.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${category.name}: ${category.description}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  void _executeQuery() {
    // Create a DataQuery object with current selections
    final query = DataQuery(
      selectedCategories: widget.selectedCategories,
      filters: {},
      playerFilter: _selectedPlayer,
      teamFilter: _selectedTeam,
      seasonFilter: _selectedSeason,
      positionFilter: _selectedPosition,
    );
    
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Multi-Category Query'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories: ${widget.selectedCategories.length}'),
            Text('Player: ${_selectedPlayer ?? "Any"}'),
            Text('Team: ${_selectedTeam ?? "Any"}'),
            Text('Season: ${_selectedSeason ?? "Any"}'),
            Text('Position: ${_selectedPosition ?? "Any"}'),
            const SizedBox(height: 16),
            const Text(
              'This would execute a cross-category query with your selections.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedPlayer = null;
      _selectedTeam = null;
      _selectedSeason = null;
      _selectedPosition = null;
    });
    widget.onCategoriesChanged([]);
  }
}