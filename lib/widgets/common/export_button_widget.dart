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
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import '../draft/shareable_draft_card.dart';

/// Widget for exporting draft results with an enhanced design
// lib/widgets/common/export_button_widget.dart
class ExportButtonWidget extends StatelessWidget {
  final List<DraftPick> completedPicks;
  final List<TeamNeed> teamNeeds;
  final String? userTeam;
  final List<TradePackage> executedTrades;
  final String? filterTeam;
  final GlobalKey? shareableCardKey;
  
  const ExportButtonWidget({
    super.key,
    required this.completedPicks,
    required this.teamNeeds,
    this.userTeam,
    required this.executedTrades,
    this.filterTeam,
    this.shareableCardKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Export Button
        PopupMenuButton<String>(
          tooltip: 'Export Options',
          offset: const Offset(0, 40),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download, size: 18),
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
            onPressed: null, // Not used since PopupMenuButton handles tap
          ),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            // Download Image Options
            PopupMenuItem<String>(
              value: 'download_header',
              enabled: false,
              child: _buildPopupHeader(context, 'Download Image', Icons.image),
            ),
            PopupMenuItem<String>(
              value: 'download_your_picks',
              child: _buildPopupItem(context, 'Your Picks', Icons.person),
            ),
            PopupMenuItem<String>(
              value: 'download_first_round',
              child: _buildPopupItem(context, 'First Round', Icons.looks_one),
            ),
            PopupMenuItem<String>(
              value: 'download_full_draft',
              child: _buildPopupItem(context, 'Full Draft', Icons.list_alt),
            ),
            
            // Divider
            const PopupMenuDivider(),
            
            // Export As Options
            PopupMenuItem<String>(
              value: 'export_header',
              enabled: false,
              child: _buildPopupHeader(context, 'Export As', Icons.share),
            ),
            PopupMenuItem<String>(
              value: 'export_html',
              child: _buildPopupItem(context, 'Web Page (HTML)', Icons.web),
            ),
            PopupMenuItem<String>(
              value: 'export_clipboard',
              child: _buildPopupItem(context, 'Text to Clipboard', Icons.text_fields),
            ),
          ],
          onSelected: (value) => _handleExportAction(value, context),
        ),
        
        const SizedBox(width: 8), // Space between buttons
        
        // Copy Image Button - Separate Button
        PopupMenuButton<String>(
          tooltip: 'Copy Image Options',
          offset: const Offset(0, 40),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.content_copy, size: 18),
            label: const Text('Copy Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.indigo : Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: null, // Not used since PopupMenuButton handles tap
          ),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'copy_your_picks',
              child: _buildPopupItem(context, 'Your Picks', Icons.person),
            ),
            PopupMenuItem<String>(
              value: 'copy_first_round',
              child: _buildPopupItem(context, 'First Round', Icons.looks_one),
            ),
            PopupMenuItem<String>(
              value: 'copy_full_draft',
              child: _buildPopupItem(context, 'Full Draft', Icons.list_alt),
            ),
          ],
          onSelected: (value) => _handleCopyAction(value, context),
        ),
      ],
    );
  }

  Widget _buildPopupHeader(BuildContext context, String title, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon, 
        color: Theme.of(context).primaryColor,
        size: 20,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  Widget _buildPopupItem(BuildContext context, String title, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        size: 18,
        color: Theme.of(context).brightness == Brightness.dark ? 
          Colors.white70 : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  void _handleExportAction(String action, BuildContext context) {
    if (action.startsWith('download_')) {
      _handleDownloadImage(action.replaceFirst('download_', ''), context);
    } else if (action == 'export_html') {
      _exportFullDraft(context);
    } else if (action == 'export_clipboard') {
      _copyToClipboard(context);
    }
  }
  
  // Update the _handleCopyAction method in export_button_widget.dart
void _handleCopyAction(String action, BuildContext context) {
  final exportMode = _getExportMode(action.replaceFirst('copy_', ''));
  
  // Skip dialog and directly attempt to copy to clipboard
  _captureAndCopyImage(context, exportMode);
}

  Future<void> _handleDownloadImage(String mode, BuildContext context) async {
    final exportMode = _getExportMode(mode);
    await _captureAndSaveImage(context, exportMode);
  }

  String _getExportMode(String mode) {
    switch (mode) {
      case 'your_picks':
        return 'your_picks';
      case 'first_round':
        return 'first_round';
      case 'full_draft':
      default:
        return 'full_draft';
    }
  }

  // Separate methods for save vs copy
  Future<void> _captureAndSaveImage(BuildContext context, String exportMode) async {
    await _captureImage(context, exportMode, false);
  }
  
  Future<void> _captureAndCopyImage(BuildContext context, String exportMode) async {
    await _captureImage(context, exportMode, true);
  }

  // Common image capture logic
  // Update the _captureImage method in export_button_widget.dart
Future<void> _captureImage(BuildContext context, String exportMode, bool forClipboard) async {
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
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(forClipboard ? 'Copying to clipboard...' : 'Generating image...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Wait for the UI to settle
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Create a temporary GlobalKey
    final GlobalKey repaintKey = GlobalKey();
    
    // Determine proper size based on export mode
    double cardWidth = 900.0; // Wider for better quality
    double cardHeight;
    
    if (exportMode == "first_round") {
      cardHeight = 900.0; // Taller for first round
    } else if (exportMode == "your_picks") {
      // Height based on number of picks
      int pickCount = completedPicks.where((p) => 
        p.teamName == (filterTeam == "All Teams" ? userTeam : filterTeam) && 
        p.selectedPlayer != null
      ).length;
      cardHeight = min(900.0, 200.0 + (pickCount * 120.0));
    } else {
      cardHeight = 900.0; // Default height
    }
    
    // Create a container in overlay to host our widget with fixed dimensions
    final overlayState = Overlay.of(context);
    
    // Create the temporary card with explicit size constraints
    final card = Material(
      color: Colors.transparent,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        child: RepaintBoundary(
          key: repaintKey,
          child: ShareableDraftCard(
            picks: completedPicks,
            userTeam: filterTeam == "All Teams" ? userTeam : filterTeam,
            teamNeeds: teamNeeds,
            exportMode: exportMode,
            cardKey: repaintKey,
          ),
        ),
      ),
    );
    
    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 20,
        top: 20,
        child: card,
      ),
    );
    
    // Add to overlay
    overlayState.insert(overlayEntry);
    
    // Wait for rendering to complete - longer wait for more complex content
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      // Find the RenderRepaintBoundary
      final RenderRepaintBoundary? boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        throw Exception('Could not find the card to render');
      }
      
      // Use HIGHER pixel ratio for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      // Remove overlay
      overlayEntry.remove();
      
      if (byteData == null) {
        throw Exception('Failed to capture image');
      }
      
      // Convert to bytes
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      if (forClipboard) {
        await _enhancedCopyToClipboard(pngBytes, context);
      } else {
        await _saveImage(pngBytes, context, exportMode);
      }
    } catch (e) {
      // Make sure to remove overlay on error
      overlayEntry.remove();
      rethrow;
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

// Update the _enhancedCopyToClipboard method in export_button_widget.dart
Future<void> _enhancedCopyToClipboard(Uint8List imageBytes, BuildContext context) async {
  try {
    if (kIsWeb) {
      // Try to use a more direct approach for web
      final blob = html.Blob([imageBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Try a more direct clipboard approach using the Clipboard API
      // This uses a newer method that works in more browsers
      final jsCode = '''
        (async function() {
          try {
            const response = await fetch("$url");
            const blob = await response.blob();
            
            // Try modern clipboard API
            if (navigator.clipboard && navigator.clipboard.write) {
              try {
                const item = new ClipboardItem({"image/png": blob});
                await navigator.clipboard.write([item]);
                return "success";
              } catch(e) {
                console.error("Clipboard API failed:", e);
              }
            }
            
            // If we can't use the Clipboard API directly
            // Open in new tab but make it user-friendly
            const newTab = window.open();
            if (newTab) {
              newTab.document.body.style.margin = "0";
              newTab.document.body.style.padding = "0";
              newTab.document.body.style.backgroundColor = "#f1f1f1";
              newTab.document.title = "Right-click to copy image";
              
              const img = newTab.document.createElement("img");
              img.src = "$url";
              img.style.display = "block";
              img.style.margin = "0 auto";
              img.style.maxWidth = "100%";
              img.style.boxShadow = "0 4px 10px rgba(0,0,0,0.1)";
              
              const instructions = newTab.document.createElement("div");
              instructions.textContent = "Right-click the image above and select 'Copy Image'";
              instructions.style.textAlign = "center";
              instructions.style.padding = "15px";
              instructions.style.fontFamily = "sans-serif";
              
              newTab.document.body.appendChild(img);
              newTab.document.body.appendChild(instructions);
              
              return "newtab";
            }
            return "error";
          } catch(e) {
            console.error("Error:", e);
            return "error";
          }
        })();
      ''';
      final result = await js_util.promiseToFuture(js.context.callMethod('eval', [jsCode])) as String?;
      
      if (result == "success" && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image copied to clipboard successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (result == "newtab" && context.mounted) {
        // Don't show a snackbar for new tab - it's obvious to the user
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image opened in new tab for copying'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Clean up URL
      Future.delayed(const Duration(seconds: 10), () {
        html.Url.revokeObjectUrl(url);
      });
    } else {
      // For mobile platforms, use platform-specific clipboard operations
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_clipboard_image.png');
      await file.writeAsBytes(imageBytes);
      
      // Try using Share.shareXFiles for sharing
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my NFL Draft results',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image shared successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing image: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

  // Helper for web clipboard API
  Future<bool> _tryWebClipboardAPI(String imageUrl, BuildContext context) async {
    try {
      // Try navigator.clipboard.write API with ClipboardItem
      // Note: This has limited browser support - primarily Chrome
      final jsCode = '''
        async function copyImageToClipboard() {
          try {
            const response = await fetch("$imageUrl");
            const blob = await response.blob();
            await navigator.clipboard.write([
              new ClipboardItem({
                [blob.type]: blob
              })
            ]);
            return true;
          } catch (err) {
            console.error("Copy failed: ", err);
            return false;
          }
        }
        copyImageToClipboard();
      ''';
      final result = js.context.callMethod('eval', [jsCode]) as bool?;
      
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image copied to clipboard successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Web clipboard API error: $e');
      return false;
    }
  }

  // Helper for instruction steps
  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage(Uint8List imageBytes, BuildContext context, String exportMode) async {
    try {
      String fileName;
      switch (exportMode) {
        case 'your_picks':
          fileName = '${userTeam ?? "team"}_picks.png';
          break;
        case 'first_round':
          fileName = 'first_round_picks.png';
          break;
        default:
          fileName = 'draft_results.png';
      }
      
      if (kIsWeb) {
        // For web, download via anchor click
        final blob = html.Blob([imageBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        
        // Clean up
        Future.delayed(const Duration(milliseconds: 100), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        // For mobile platforms
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(imageBytes);
        
        // Save to gallery on mobile
        final result = await ImageGallerySaver.saveFile(file.path);
        
        // Also offer to share
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out my NFL mock draft results!',
        );
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // Existing methods
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
}