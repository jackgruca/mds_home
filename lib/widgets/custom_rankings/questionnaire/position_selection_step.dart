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
    final positions = _getPositions();
    return Column(
      children: positions
          .map((position) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildPositionCard(context, position),
              ))
          .toList(),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final positions = _getPositions();
    return Row(
      children: positions
          .map((position) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildPositionCard(context, position),
                ),
              ))
          .toList(),
    );
  }

  List<Map<String, dynamic>> _getPositions() {
    return [
      {
        'position': 'QB',
        'name': 'Quarterback',
        'icon': Icons.sports_football,
        'image': 'assets/images/FF/josh.png',
        'description': 'Passing yards, TDs, rushing upside',
        'sampleAttributes': ['Passing Yards/Game', 'Passing TDs', 'Rushing Yards', 'Previous PPG'],
      },
      {
        'position': 'RB',
        'name': 'Running Back',
        'icon': Icons.directions_run,
        'image': 'assets/images/FF/saquon.png',
        'description': 'Rushing volume, receiving work, goal line',
        'sampleAttributes': ['Rushing Yards/Game', 'Target Share', 'Snap %', 'Previous PPG'],
      },
      {
        'position': 'WR',
        'name': 'Wide Receiver',
        'icon': Icons.sports,
        'image': 'assets/images/FF/jamarr.png',
        'description': 'Target share, air yards, red zone usage',
        'sampleAttributes': ['Target Share', 'Receiving Yards/Game', 'Red Zone Targets', 'Air Yards'],
      },
      {
        'position': 'TE',
        'name': 'Tight End',
        'icon': Icons.sports_handball,
        'image': 'assets/images/FF/kittle.png',
        'description': 'Target share, red zone role, snap count',
        'sampleAttributes': ['Target Share', 'Red Zone Targets', 'Snap %', 'Previous PPG'],
      },
    ];
  }


  Widget _buildPositionCard(BuildContext context, Map<String, dynamic> position) {
    final theme = Theme.of(context);
    final isSelected = selectedPosition == position['position'];
    
    return GestureDetector(
      onTap: () => onPositionSelected(position['position'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
            ? (Theme.of(context).brightness == Brightness.dark 
                ? ThemeConfig.darkNavy 
                : Theme.of(context).colorScheme.primary.withOpacity(0.05)) 
            : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected 
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? ThemeConfig.gold 
                  : Theme.of(context).colorScheme.primary) 
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Position name at top
              Text(
                position['position'] as String,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                    ? (Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.primary) 
                    : (Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : ThemeConfig.darkNavy),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                position['name'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Player image in the middle
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    position['image'] as String,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: 120,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          position['icon'] as IconData,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Sample attributes at bottom
              Text(
                'Sample Attributes:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: (position['sampleAttributes'] as List<String>)
                    .map((attr) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? (Theme.of(context).brightness == Brightness.dark 
                                  ? ThemeConfig.gold.withOpacity(0.2) 
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.1)) 
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected ? Border.all(
                              color: Theme.of(context).brightness == Brightness.dark 
                                ? ThemeConfig.gold.withOpacity(0.5) 
                                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ) : null,
                          ),
                          child: Text(
                            attr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected 
                                ? (Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Theme.of(context).colorScheme.primary) 
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}