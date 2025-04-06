// lib/widgets/common/export_button_widget.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/draft_export_service.dart';
import '../../models/draft_pick.dart';
import '../../models/team_need.dart';
import '../../models/trade_package.dart';
import '../../utils/theme_config.dart'; // Import theme for consistency

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../../services/draft_export_service.dart';
import '../../models/draft_pick.dart';
import '../../models/team_need.dart';
import '../../models/trade_package.dart';
import '../../utils/theme_config.dart';

/// Widget for exporting draft results with an enhanced design
class ExportButtonWidget extends StatelessWidget {
  final List<DraftPick> completedPicks;
  final List<TeamNeed> teamNeeds;
  final String? userTeam;
  final List<TradePackage> executedTrades;
  final String? filterTeam;
  final GlobalKey? shareableCardKey; // Add this
  
  const ExportButtonWidget({
    super.key,
    required this.completedPicks,
    required this.teamNeeds,
    this.userTeam,
    required this.executedTrades,
    this.filterTeam,
    this.shareableCardKey, // Add this
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
            
            // Add the shareable image option
            _buildExportOption(
              context,
              icon: Icons.image,
              title: 'Shareable Image',
              subtitle: 'Create a shareable image for social media',
              onTap: () {
                Navigator.pop(context);
                _exportAsImage(context);
              },
            ),
            
            const Divider(height: 16),
            
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
                const Divider(height: 16),
            
            _buildExportOption(
              context,
              icon: Icons.content_copy,
              title: 'Copy to Clipboard',
              subtitle: 'Copy formatted results for sharing via text',
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(context);
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

  Future<void> _exportAsImage(BuildContext context) async {
  if (shareableCardKey == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to generate image')),
    );
    return;
  }

  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  try {
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
            const Text('Generating shareable image...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Wait for snackbar to appear
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Find the RenderRepaintBoundary for the shareable card
    final RenderRepaintBoundary boundary = 
        shareableCardKey!.currentContext!.findRenderObject() as RenderRepaintBoundary;
    
    // Capture the image
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('Failed to capture image');
    }
    
    // Convert to bytes
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    
    // Share the image
    if (kIsWeb) {  // Use kIsWeb instead of isWeb
      // For web, use a different method
      await _shareImageOnWeb(pngBytes);
    } else {
      // For mobile, save to temporary file and share
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/draft_results.png');
      await file.writeAsBytes(pngBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my NFL mock draft results from StickToTheModel!',
      );
      
      // Also save to gallery
      await ImageGallerySaver.saveImage(pngBytes);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft results image saved to your gallery'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating image: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}  

// Method for web platforms
Future<void> _shareImageOnWeb(Uint8List pngBytes) async {
  // This is a simplistic implementation for web
  // In a real app, you'd need to use a proper web sharing API
  // or implement a server-side solution
  
  // For now, we'll just display a message
  print('Web sharing not fully implemented: would share ${pngBytes.length} bytes');
  
  // In a real implementation, you might:
  // 1. Upload the image to your server
  // 2. Get a shareable URL
  // 3. Display it to the user for copying
  // 4. Or use the Web Share API if available
}

Future<void> _copyToClipboard(BuildContext context) async {
  final formattedText = DraftExportService.generateFormattedClipboardText(
    completedPicks,
    userTeam,
  );
  
  await Clipboard.setData(ClipboardData(text: formattedText));
  
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft results copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
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