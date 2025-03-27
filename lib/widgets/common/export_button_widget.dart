// lib/widgets/common/export_button_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/draft_export_service.dart';
import '../../models/draft_pick.dart';
import '../../models/team_need.dart';
import '../../models/trade_package.dart';
import '../../utils/theme_config.dart'; // Import theme for consistency

/// Widget for exporting draft results with an enhanced design
class ExportButtonWidget extends StatelessWidget {
  final List<DraftPick> completedPicks;
  final List<TeamNeed> teamNeeds;
  final String? userTeam;
  final List<TradePackage> executedTrades;
  final String? filterTeam;
  
  const ExportButtonWidget({
    super.key,
    required this.completedPicks,
    required this.teamNeeds,
    this.userTeam,
    required this.executedTrades,
    this.filterTeam,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme info to match app's visual design
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return ElevatedButton.icon(
      icon: const Icon(Icons.share, size: 18),
      label: const Text('Export'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        _showExportDialog(context);
      },
    );
  }
  
  void _showExportDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(Icons.share, 
              color: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Export Draft Results',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose what you want to export:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildExportOption(
                context,
                icon: Icons.list_alt,
                title: 'Full Draft',
                subtitle: 'Export all rounds and picks',
                onTap: () {
                  Navigator.pop(context);
                  _exportFullDraft(context);
                },
              ),
              const Divider(height: 16),
              _buildExportOption(
                context,
                icon: Icons.looks_one,
                title: 'First Round Only',
                subtitle: 'Export just the first round picks',
                onTap: () {
                  Navigator.pop(context);
                  _exportFirstRound(context);
                },
              ),
              if (userTeam != null) ...[
                const Divider(height: 16),
                _buildExportOption(
                  context,
                  icon: Icons.person,
                  title: 'Your Picks',
                  subtitle: 'Export only your team\'s picks',
                  onTap: () {
                    Navigator.pop(context);
                    _exportTeamPicks(context, userTeam!);
                  },
                ),
              ],
              if (filterTeam != null && filterTeam != userTeam && filterTeam != "All Teams") ...[
                const Divider(height: 16),
                _buildExportOption(
                  context,
                  icon: Icons.groups,
                  title: '$filterTeam Picks',
                  subtitle: 'Export only $filterTeam\'s picks',
                  onTap: () {
                    Navigator.pop(context);
                    _exportTeamPicks(context, filterTeam!);
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportFullDraft(BuildContext context) async {
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Preparing draft results...'),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Use enhanced export service
      await DraftExportService.shareDraftResults(
        context: context,
        picks: completedPicks,
        teamNeeds: teamNeeds,
        title: 'NFL Draft Simulator Results',
        userTeam: userTeam,
        trades: executedTrades,
        isWeb: kIsWeb,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft results exported successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting draft results: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _exportFirstRound(BuildContext context) async {
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Preparing first round results...'),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Use enhanced export service with first round layout
      await DraftExportService.exportFirstRound(
        context: context,
        picks: completedPicks,
        teamNeeds: teamNeeds,
        userTeam: userTeam,
        isWeb: kIsWeb,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('First round results exported successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting first round: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _exportTeamPicks(BuildContext context, String team) async {
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('Preparing $team draft results...'),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Use enhanced export service with team summary
      await DraftExportService.exportTeamPicks(
        context: context,
        picks: completedPicks,
        teamNeeds: teamNeeds,
        team: team,
        trades: executedTrades,
        isWeb: kIsWeb,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$team picks exported successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting team picks: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}