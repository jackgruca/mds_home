// lib/widgets/common/export_button_widget.dart
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:html' as html;
import 'dart:js' as js;

import '../../models/draft_pick.dart';
import '../../models/team_need.dart';
import '../../models/trade_package.dart';
import '../../utils/theme_config.dart';
import '../draft/shareable_draft_card.dart';

/// Widget for copying draft results as images
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
    return PopupMenuButton<String>(
      tooltip: 'Copy Image Options',
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.shade700,
            width: 2.0,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.content_copy,
              size: 18,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'Copy Draft Image',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
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

  // Handle copy action immediately when selected from dropdown
  void _handleCopyAction(String action, BuildContext context) {
    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, 
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text('Copying image to clipboard...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final exportMode = _getExportMode(action.replaceFirst('copy_', ''));
    
    // Direct capture and copy
    _captureAndCopyImage(context, exportMode);
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

  // The main method that handles capturing and copying the image
  Future<void> _captureAndCopyImage(BuildContext context, String exportMode) async {
    if (shareableCardKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate image')),
      );
      return;
    }

    try {
      // Create a temporary GlobalKey
      final GlobalKey repaintKey = GlobalKey();
      
      // Calculate proper height based on export mode
      double cardHeight;
      if (exportMode == "your_picks") {
        // For user picks, calculate based on estimated number of picks
        int userPickCount = completedPicks.where((p) => 
          p.teamName == (filterTeam == "All Teams" ? userTeam : filterTeam) && 
          p.selectedPlayer != null
        ).length;
        
        // Make sure we have at least enough height, with a reasonable minimum
        cardHeight = max(250.0, 150.0 + (userPickCount * 80.0));
      } else if (exportMode == "first_round") {
        cardHeight = 900.0; // For first round layout
      } else {
        // For full draft, calculate based on the number of rounds
        Map<String, List<DraftPick>> picksByRound = {};
        for (var pick in completedPicks) {
          if (pick.selectedPlayer != null) {
            if (!picksByRound.containsKey(pick.round)) {
              picksByRound[pick.round] = [];
            }
            picksByRound[pick.round]!.add(pick);
          }
        }
        int numRounds = picksByRound.length;
        
        // Height based on number of rounds (max 7 for NFL draft)
        cardHeight = 200.0 + (numRounds * 100.0);
        cardHeight = min(1200.0, cardHeight); // Cap at 1200px
      }
      
      // Create a temporary card with fixed dimensions
      final card = Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 800,
          height: cardHeight,
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
      
      // Create a container in overlay to host our widget
      final overlayState = Overlay.of(context);
      final OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -2000, // Place offscreen but still render
          top: -2000,
          child: card,
        ),
      );
      
      // Add to overlay
      overlayState.insert(overlayEntry);
      
      // Wait for rendering
      await Future.delayed(const Duration(milliseconds: 300));
      
      try {
        // Find the RenderRepaintBoundary
        final RenderRepaintBoundary? boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        
        if (boundary == null) {
          throw Exception('Could not find the card to render');
        }
        
        // Capture the image with high pixel ratio for quality
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0); // Higher quality
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        // Remove overlay
        overlayEntry.remove();
        
        if (byteData == null) {
          throw Exception('Failed to capture image');
        }
        
        // Convert to bytes
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        // Copy to clipboard
        await _directCopyToClipboard(pngBytes, context);
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

  // Optimized clipboard handling specifically for desktop browsers
  Future<void> _directCopyToClipboard(Uint8List imageBytes, BuildContext context) async {
    try {
      if (kIsWeb) {
        // Create a blob from the image bytes
        final blob = html.Blob([imageBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Detect if on desktop
        final isMobile = html.window.navigator.userAgent.contains('Mobile') || 
                       html.window.navigator.userAgent.contains('Android') ||
                       html.window.navigator.userAgent.contains('iPhone');
        
        if (!isMobile) {
          // Desktop-specific implementation with more reliable clipboard access
          bool success = false;
          
          // Create and append a canvas element to draw the image on
          final result = await js.context.callMethod('eval', ['''
            (async function() {
              try {
                // Create a hidden canvas element
                const canvas = document.createElement('canvas');
                const ctx = canvas.getContext('2d');
                
                // Create an image from our blob URL
                const img = new Image();
                img.crossOrigin = 'anonymous';
                
                // Set up promise to wait for image to load
                const imgLoaded = new Promise((resolve, reject) => {
                  img.onload = resolve;
                  img.onerror = reject;
                  img.src = "$url";
                });
                
                // Wait for image to load
                await imgLoaded;
                
                // Set canvas dimensions to match image
                canvas.width = img.width;
                canvas.height = img.height;
                
                // Draw image to canvas
                ctx.drawImage(img, 0, 0);
                
                // Get data URL from canvas
                const dataUrl = canvas.toDataURL('image/png');
                
                // Copy to clipboard using modern Clipboard API
                if (navigator.clipboard) {
                  try {
                    // Convert base64 to blob
                    const base64Data = dataUrl.split(',')[1];
                    const byteCharacters = atob(base64Data);
                    const byteArrays = [];
                    
                    for (let i = 0; i < byteCharacters.length; i += 512) {
                      const slice = byteCharacters.slice(i, i + 512);
                      const byteNumbers = new Array(slice.length);
                      
                      for (let j = 0; j < slice.length; j++) {
                        byteNumbers[j] = slice.charCodeAt(j);
                      }
                      
                      byteArrays.push(new Uint8Array(byteNumbers));
                    }
                    
                    const imgBlob = new Blob(byteArrays, {type: 'image/png'});
                    
                    // Use ClipboardItem API
                    const clipboardItem = new ClipboardItem({'image/png': imgBlob});
                    await navigator.clipboard.write([clipboardItem]);
                    return "success";
                  } catch (e) {
                    console.error("Clipboard API error: " + e);
                    
                    // Fallback to execCommand for older browsers
                    try {
                      // Create a temporary textarea element
                      const textarea = document.createElement('textarea');
                      textarea.value = dataUrl;
                      document.body.appendChild(textarea);
                      textarea.select();
                      
                      // Execute copy command
                      const successful = document.execCommand('copy');
                      
                      // Clean up
                      document.body.removeChild(textarea);
                      
                      if (successful) {
                        return "legacy_success";
                      } else {
                        return "legacy_failure";
                      }
                    } catch (e2) {
                      console.error("Legacy clipboard error: " + e2);
                      return "all_methods_failed";
                    }
                  }
                } else {
                  return "clipboard_api_unavailable";
                }
              } catch (e) {
                console.error("General error: " + e);
                return "general_error";
              }
            })()
          ''']);
          
          // Check result status
          success = result == "success" || result == "legacy_success";
          
          if (success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image copied to clipboard successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Fallback - use navigator API to directly download without opening a new tab
            js.context.callMethod('eval', ['''
              (function() {
                // Create a temporary button that triggers download
                const downloadLink = document.createElement('a');
                downloadLink.href = "$url";
                downloadLink.download = "draft_image.png";
                
                // Append to document
                document.body.appendChild(downloadLink);
                
                // Trigger click
                downloadLink.click();
                
                // Clean up
                document.body.removeChild(downloadLink);
              })()
            ''']);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Clipboard access denied - Image downloaded instead'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          // Mobile implementation
          try {
            // Try modern Clipboard API first
            final result = await js.context.callMethod('eval', ['''
              (async function() {
                try {
                  const response = await fetch("$url");
                  const blob = await response.blob();
                  const item = new ClipboardItem({"image/png": blob});
                  await navigator.clipboard.write([item]);
                  return "success";
                } catch(e) {
                  console.error("Mobile clipboard API error: " + e);
                  return "error";
                }
              })()
            ''']);
            
            if (result == "success") {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } else {
              // Create a modal with the image for easy manual copying
              js.context.callMethod('eval', ['''
                (function() {
                  // Remove any previous temp elements
                  var oldElem = document.getElementById('tempCopyImage');
                  if (oldElem) oldElem.remove();
                  
                  // Create modal container
                  var modalContainer = document.createElement('div');
                  modalContainer.id = 'tempCopyImage';
                  modalContainer.style.position = 'fixed';
                  modalContainer.style.zIndex = '10000';
                  modalContainer.style.top = '0';
                  modalContainer.style.left = '0';
                  modalContainer.style.width = '100%';
                  modalContainer.style.height = '100%';
                  modalContainer.style.backgroundColor = 'rgba(0,0,0,0.8)';
                  modalContainer.style.display = 'flex';
                  modalContainer.style.flexDirection = 'column';
                  modalContainer.style.alignItems = 'center';
                  modalContainer.style.justifyContent = 'center';
                  
                  // Create image
                  var img = document.createElement('img');
                  img.src = "$url";
                  img.style.maxWidth = '90%';
                  img.style.maxHeight = '70%';
                  img.style.objectFit = 'contain';
                  
                  // Create instruction text
                  var instructions = document.createElement('div');
                  instructions.style.color = 'white';
                  instructions.style.margin = '20px';
                  instructions.style.textAlign = 'center';
                  instructions.style.fontFamily = 'sans-serif';
                  instructions.innerHTML = '<b>Tap and hold on the image to copy</b><br>Tap outside to close';
                  
                  // Add close functionality
                  modalContainer.onclick = function(e) {
                    if (e.target === modalContainer) {
                      modalContainer.remove();
                    }
                  };
                  
                  // Add everything to DOM
                  modalContainer.appendChild(img);
                  modalContainer.appendChild(instructions);
                  document.body.appendChild(modalContainer);
                  
                  // Auto close after 30 seconds
                  setTimeout(function() {
                    var elem = document.getElementById('tempCopyImage');
                    if (elem) elem.remove();
                  }, 30000);
                })();
              ''']);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Press and hold the image to copy it'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          } catch (e) {
            // Final fallback - show the modal anyway
            js.context.callMethod('eval', ['''
              (function() {
                // Remove any previous temp elements
                var oldElem = document.getElementById('tempCopyImage');
                if (oldElem) oldElem.remove();
                
                // Create modal container
                var modalContainer = document.createElement('div');
                modalContainer.id = 'tempCopyImage';
                modalContainer.style.position = 'fixed';
                modalContainer.style.zIndex = '10000';
                modalContainer.style.top = '0';
                modalContainer.style.left = '0';
                modalContainer.style.width = '100%';
                modalContainer.style.height = '100%';
                modalContainer.style.backgroundColor = 'rgba(0,0,0,0.8)';
                modalContainer.style.display = 'flex';
                modalContainer.style.flexDirection = 'column';
                modalContainer.style.alignItems = 'center';
                modalContainer.style.justifyContent = 'center';
                
                // Create image
                var img = document.createElement('img');
                img.src = "$url";
                img.style.maxWidth = '90%';
                img.style.maxHeight = '70%';
                img.style.objectFit = 'contain';
                
                // Create instruction text
                var instructions = document.createElement('div');
                instructions.style.color = 'white';
                instructions.style.margin = '20px';
                instructions.style.textAlign = 'center';
                instructions.style.fontFamily = 'sans-serif';
                instructions.innerHTML = '<b>Tap and hold on the image to copy</b><br>Tap outside to close';
                
                // Add close functionality
                modalContainer.onclick = function(e) {
                  if (e.target === modalContainer) {
                    modalContainer.remove();
                  }
                };
                
                // Add everything to DOM
                modalContainer.appendChild(img);
                modalContainer.appendChild(instructions);
                document.body.appendChild(modalContainer);
                
                // Auto close after 30 seconds
                setTimeout(function() {
                  var elem = document.getElementById('tempCopyImage');
                  if (elem) elem.remove();
                }, 30000);
              })();
            ''']);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press and hold the image to copy it'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
        
        // Clean up URL resource after a delay
        Future.delayed(const Duration(seconds: 30), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        // Native mobile app implementation
        // This isn't a direct clipboard copy, but it's the closest we can get
        // outside the web platform
        
        final tempDir = await Directory.systemTemp.createTemp();
        final file = File('${tempDir.path}/draft_image.png');
        await file.writeAsBytes(imageBytes);
        
        // This will show the share sheet which lets users copy
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out my NFL Draft results',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image ready to share'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}