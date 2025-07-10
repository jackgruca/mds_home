import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';

class PositionSelectionStep extends StatelessWidget {
  final String? selectedPosition;
  final Function(String) onPositionSelected;

  const PositionSelectionStep({
    super.key,
    required this.selectedPosition,
    required this.onPositionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Position to Rank',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which position you want to create custom rankings for. Each position has specific attributes that matter most for fantasy performance.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          _buildPositionGrid(context),
        ],
      ),
    );
  }

  Widget _buildPositionGrid(BuildContext context) {
    final positions = [
      {
        'position': 'QB',
        'name': 'Quarterback',
        'icon': Icons.sports_football,
        'description': 'Passing yards, TDs, rushing upside',
        'sampleAttributes': ['Passing Yards/Game', 'Passing TDs', 'Rushing Yards', 'Previous PPG'],
      },
      {
        'position': 'RB',
        'name': 'Running Back',
        'icon': Icons.directions_run,
        'description': 'Rushing volume, receiving work, goal line',
        'sampleAttributes': ['Rushing Yards/Game', 'Target Share', 'Snap %', 'Previous PPG'],
      },
      {
        'position': 'WR',
        'name': 'Wide Receiver',
        'icon': Icons.sports,
        'description': 'Target share, air yards, red zone usage',
        'sampleAttributes': ['Target Share', 'Receiving Yards/Game', 'Red Zone Targets', 'Air Yards'],
      },
      {
        'position': 'TE',
        'name': 'Tight End',
        'icon': Icons.sports_handball,
        'description': 'Target share, red zone role, snap count',
        'sampleAttributes': ['Target Share', 'Red Zone Targets', 'Snap %', 'Previous PPG'],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final position = positions[index];
        return _buildPositionCard(context, position);
      },
    );
  }

  Widget _buildPositionCard(BuildContext context, Map<String, dynamic> position) {
    final theme = Theme.of(context);
    final isSelected = selectedPosition == position['position'];
    
    return GestureDetector(
      onTap: () => onPositionSelected(position['position'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? ThemeConfig.darkNavy.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? ThemeConfig.darkNavy : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? ThemeConfig.darkNavy : ThemeConfig.brightRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      position['icon'] as IconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position['position'] as String,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? ThemeConfig.darkNavy : null,
                        ),
                      ),
                      Text(
                        position['name'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                position['description'] as String,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Sample attributes:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: (position['sampleAttributes'] as List<String>)
                    .take(3)
                    .map((attr) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? ThemeConfig.gold.withValues(alpha: 0.2) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        attr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    )).toList(),
              ),
              if ((position['sampleAttributes'] as List<String>).length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${(position['sampleAttributes'] as List<String>).length - 3} more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}