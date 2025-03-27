// lib/widgets/common/export_button_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/draft_export_service.dart';
import '../../models/draft_pick.dart';
import '../../models/team_need.dart';
import '../../models/trade_package.dart';

/// Widget for exporting draft results
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
    return ElevatedButton.icon(
      icon: const Icon(Icons.share, size: 18),
      label: const Text('Export'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        title: Row(
          children: [
            Icon(Icons.share, 
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700
            ),
            const SizedBox(width: 10),
            const Text('Export Draft Results'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose what you want to export:',
              style: TextStyle(fontWeight: FontWeight.bold),
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
            const Divider(),
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
              const Divider(),
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
              const Divider(),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportFullDraft(BuildContext context) async {
    try {
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
          const SnackBar(content: Text('Draft results exported successfully'))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting draft results: $e'))
        );
      }
    }
  }

  Future<void> _exportFirstRound(BuildContext context) async {
    try {
      await DraftExportService.exportFirstRound(
        context: context,
        picks: completedPicks,
        teamNeeds: teamNeeds,
        userTeam: userTeam,
        isWeb: kIsWeb,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting first round: $e'))
        );
      }
    }
  }

  Future<void> _exportTeamPicks(BuildContext context, String team) async {
    try {
      await DraftExportService.exportTeamPicks(
        context: context,
        picks: completedPicks,
        teamNeeds: teamNeeds,
        team: team,
        trades: executedTrades,
        isWeb: kIsWeb,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting team picks: $e'))
        );
      }
    }
  }
}