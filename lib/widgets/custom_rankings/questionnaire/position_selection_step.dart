import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';

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
          ResponsiveLayoutBuilder(
            mobile: (context) => _buildMobileLayout(context),
            desktop: (context) => _buildDesktopLayout(context),
          )
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return _buildPositionGrid(context, crossAxisCount: 2, childAspectRatio: 0.8);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final positions = _getPositions();
    return Center(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: positions
            .map((position) => SizedBox(
                  width: 300,
                  child: _buildPositionCard(context, position),
                ))
            .toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _getPositions() {
    return [
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
  }

  Widget _buildPositionGrid(BuildContext context, {required int crossAxisCount, required double childAspectRatio}) {
    final positions = _getPositions();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
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
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : ThemeConfig.brightRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      position['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position['position'] as String,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Theme.of(context).colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          position['name'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Sample attributes:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (position['sampleAttributes'] as List<String>)
                    .map((attr) => Chip(
                          label: Text(attr),
                          backgroundColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                          )
                        )
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}