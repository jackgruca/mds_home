// lib/services/draft_export_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';

class DraftExportService {
  /// Share draft results via platform-specific methods
  static Future<void> shareDraftResults({
  required BuildContext context,
  required List<DraftPick> picks,
  required List<TeamNeed> teamNeeds,
  required String title,
  String? userTeam,
  List<TradePackage> trades = const [],
  bool isWeb = false,
}) async {
  // Generate HTML content
  String htmlContent = _generateHtmlContent(
    picks: picks,
    teamNeeds: teamNeeds,
    title: title,
    userTeam: userTeam,
    trades: trades,
    showAllTeams: true,
  );

  if (isWeb) {
    _openInNewTab(htmlContent);
  } else {
    // Check if mobile to optimize sharing approach
    final isMobile = Platform.isAndroid || Platform.isIOS;
    
    if (isMobile) {
      // For mobile, prefer text content for better app sharing
      String plainText = generateFormattedClipboardText(picks, userTeam);
      
      // Create a temporary HTML file for advanced users who want that option
      final tempDir = await getTemporaryDirectory();
      final htmlFile = await File('${tempDir.path}/draft_results.html').writeAsString(htmlContent);
      
      // Share both text and file
      await Share.shareXFiles(
        [XFile(htmlFile.path)],
        text: plainText,
        subject: 'NFL Draft Results',
      );
    } else {
      // For desktop, prefer HTML file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/draft_results.html').writeAsString(htmlContent);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'StickToTheModel Draft Results',
      );
    }
  }
}
  // Update the method that renders pick cards in HTML

// Add this method to draft_export_service.dart
  /// Export first round
  static Future<void> exportFirstRound({
    required BuildContext context,
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    String? userTeam,
    bool isWeb = false,
  }) async {
    // Filter first round picks
    final firstRoundPicks = picks.where((pick) => pick.round == '1').toList();
    
    // Generate HTML content for first round
    String htmlContent = _generateHtmlContent(
      picks: firstRoundPicks,
      teamNeeds: teamNeeds,
      title: 'First Round Results',
      userTeam: userTeam,
      showRoundSummary: true,
      showTwoColumnLayout: true,
    );

    if (isWeb) {
      _openInNewTab(htmlContent);
    } else {
      // Handle mobile export
      try {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/first_round_results.html').writeAsString(htmlContent);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'NFL Draft First Round Results',
        );
      } catch (e) {
        // If sharing fails, fallback to clipboard
        await Clipboard.setData(ClipboardData(text: _generatePlainText(firstRoundPicks, userTeam)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('First round results copied to clipboard (plain text)')),
        );
      }
    }
  }

  /// Export team picks
  static Future<void> exportTeamPicks({
    required BuildContext context,
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    required String team,
    List<TradePackage> trades = const [],
    bool isWeb = false,
  }) async {
    // Filter picks for selected team
    final teamPicks = picks.where((pick) => pick.teamName == team).toList();
    
    // Filter trades involving selected team
    final teamTrades = trades.where(
      (trade) => trade.teamOffering == team || trade.teamReceiving == team
    ).toList();
    
    // Generate HTML content for team picks
    String htmlContent = _generateHtmlContent(
      picks: teamPicks,
      teamNeeds: teamNeeds,
      title: '$team Draft Results',
      userTeam: team,
      trades: teamTrades,
      showTeamSummary: true,
      showPickCards: true,  // Add this new parameter
    );

    if (isWeb) {
      _openInNewTab(htmlContent);
    } else {
      // Handle mobile export
      try {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/${team.replaceAll(' ', '_')}_draft_results.html').writeAsString(htmlContent);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '$team Draft Results',
        );
      } catch (e) {
        // If sharing fails, fallback to clipboard
        await Clipboard.setData(ClipboardData(text: _generatePlainText(teamPicks, team)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team draft results copied to clipboard (plain text)')),
        );
      }
    }
  }

/// Generate formatted text for clipboard sharing
static String generateFormattedClipboardText(
  List<DraftPick> picks,
  String? userTeam,
  {int maxPicksToShow = 10}
) {
  StringBuffer buffer = StringBuffer();
  
  // Header
  buffer.writeln('🏈 NFL MOCK DRAFT RESULTS 🏈');
  buffer.writeln('via StickToTheModel');
  buffer.writeln('');
  
  // Filter picks with players selected
  final selectedPicks = picks.where((p) => p.selectedPlayer != null).toList();
  
  // Show user team if specified
  if (userTeam != null) {
    buffer.writeln('${userTeam.toUpperCase()} DRAFT:');
    
    // Filter for user team picks
    final userPicks = selectedPicks.where((p) => p.teamName == userTeam).toList();
    
    if (userPicks.isEmpty) {
      buffer.writeln('No picks made by $userTeam');
    } else {
      for (var pick in userPicks) {
        buffer.writeln('#${pick.pickNumber}: ${pick.selectedPlayer!.name} (${pick.selectedPlayer!.position}, ${pick.selectedPlayer!.school})');
      }
    }
    
    buffer.writeln('');
  }
  
  // Top picks overall
  buffer.writeln('TOP ${min(maxPicksToShow, selectedPicks.length)} PICKS:');
  for (int i = 0; i < min(maxPicksToShow, selectedPicks.length); i++) {
    final pick = selectedPicks[i];
    String teamMarker = userTeam != null && pick.teamName == userTeam ? '✓ ' : '';
    buffer.writeln('${i+1}. ${teamMarker}#${pick.pickNumber} ${pick.teamName}: ${pick.selectedPlayer!.name} (${pick.selectedPlayer!.position})');
  }
  
  // Footer
  buffer.writeln('');
  buffer.writeln('Create your own NFL mock draft at yourdomain.com');
  
  return buffer.toString();
}
  /// Open HTML content in a new tab (web only)
  static void _openInNewTab(String htmlContent) {
    // Create a Blob with HTML content
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Open in new tab
    html.window.open(url, '_blank');
    
    // Clean up
    Future.delayed(const Duration(seconds: 1), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  /// Generate plain text for fallback
  static String _generatePlainText(List<DraftPick> picks, String? userTeam) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('NFL DRAFT SIMULATOR RESULTS');
    buffer.writeln('===========================');
    buffer.writeln();
    
    for (var pick in picks) {
      if (pick.selectedPlayer == null) continue;
      
      String teamMarker = userTeam != null && pick.teamName == userTeam ? '* ' : '';
      buffer.writeln('${teamMarker}Pick #${pick.pickNumber} (Round ${pick.round}): ${pick.teamName}');
      buffer.writeln('  ${pick.selectedPlayer!.name}, ${pick.selectedPlayer!.position} (${pick.selectedPlayer!.school})');
      buffer.writeln('  Rank: #${pick.selectedPlayer!.rank} (Value: ${pick.pickNumber - pick.selectedPlayer!.rank})');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// Generate HTML content for export
  static String _generateHtmlContent({
  required List<DraftPick> picks,
  required List<TeamNeed> teamNeeds,
  required String title,
  String? userTeam,
  List<TradePackage> trades = const [],
  bool showAllTeams = false,
  bool showTeamSummary = false,
  bool showRoundSummary = false,
  bool showTwoColumnLayout = false,
  bool showPickCards = false,
}) {
  // Create StringBuffer for HTML content
  StringBuffer html = StringBuffer();
  
  // HTML header with social media meta tags
  html.write('''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta property="og:title" content="NFL Draft Results - StickToTheModel">
  <meta property="og:description" content="${userTeam != null ? '$userTeam' : 'NFL'} Mock Draft Results">
  <meta property="og:type" content="website">
  <title>$title</title>
  <style>
    :root {
      --primary-color: #D50A0A;
      --secondary-color: #002244;
      --accent-color: #FFB612;
      --light-bg: #F8F9FA;
      --dark-bg: #212529;
      --light-text: #333333;
      --dark-text: #FFFFFF;
      --card-bg: #FFFFFF;
      --card-shadow: 0 4px 6px rgba(0,0,0,0.1);
      --border-radius: 12px;
      --grade-a-plus-bg: rgba(76, 175, 80, 0.15);
      --grade-a-plus-color: #2E7D32;
      --grade-a-bg: rgba(76, 175, 80, 0.15);
      --grade-a-color: #388E3C;
      --grade-b-plus-bg: rgba(33, 150, 243, 0.15);
      --grade-b-plus-color: #1976D2;
      --grade-b-bg: rgba(33, 150, 243, 0.15);
      --grade-b-color: #1976D2;
      --grade-c-plus-bg: rgba(255, 152, 0, 0.15);
      --grade-c-plus-color: #F57C00;
      --grade-c-bg: rgba(255, 152, 0, 0.15);
      --grade-c-color: #EF6C00;
      --grade-d-bg: rgba(244, 67, 54, 0.15);
      --grade-d-color: #D32F2F;
      --grade-f-bg: rgba(244, 67, 54, 0.15);
      --grade-f-color: #C62828;
    }
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--light-bg);
      color: var(--light-text);
      line-height: 1.6;
      padding: 0;
      margin: 0;
    }
    
    .container {
      max-width: 800px;
      margin: 0 auto;
      padding: 16px;
    }
    
    .header {
      background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
      color: white;
      padding: 24px;
      border-radius: var(--border-radius) var(--border-radius) 0 0;
      position: relative;
      overflow: hidden;
    }
    
    .header::after {
      content: '';
      position: absolute;
      bottom: 0;
      right: 0;
      width: 100px;
      height: 100px;
      background-color: rgba(255, 255, 255, 0.1);
      border-radius: 50% 0 0 0;
    }
    
    .header h1 {
      font-size: 28px;
      margin: 0;
      font-weight: 800;
    }
    
    .header p {
      margin: 8px 0 0;
      opacity: 0.9;
      font-size: 16px;
    }
    
    .logo {
      position: absolute;
      top: 24px;
      right: 24px;
      font-size: 14px;
      opacity: 0.8;
    }
    
    .content {
      background: var(--card-bg);
      border-radius: 0 0 var(--border-radius) var(--border-radius);
      box-shadow: var(--card-shadow);
      padding: 24px;
      margin-bottom: 24px;
    }
    
    .section-title {
      font-size: 20px;
      font-weight: 700;
      color: var(--secondary-color);
      margin: 0 0 16px 0;
      padding-bottom: 8px;
      border-bottom: 2px solid #EEEEEE;
    }
    
    .pick-card {
      display: flex;
      align-items: center;
      background: var(--card-bg);
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
      margin-bottom: 12px;
      padding: 12px;
      border: 1px solid #EEEEEE;
      transition: transform 0.2s ease, box-shadow 0.2s ease;
    }
    
    .pick-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0,0,0,0.1);
    }
    
    .pick-card.user-team {
      border-left: 4px solid var(--primary-color);
      background-color: rgba(213, 10, 10, 0.03);
    }
    
    .pick-number {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background-color: var(--secondary-color);
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: bold;
      font-size: 14px;
      margin-right: 12px;
      flex-shrink: 0;
    }
    
    .team-logo {
      width: 40px;
      height: 40px;
      margin-right: 12px;
      flex-shrink: 0;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .team-logo img {
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
    }
    
    .pick-details {
      flex-grow: 1;
      min-width: 0;
    }
    
    .player-name {
      font-weight: bold;
      font-size: 16px;
      margin-bottom: 4px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    
    .player-meta {
      display: flex;
      align-items: center;
      font-size: 14px;
      color: #666666;
    }
    
    .position-badge {
      padding: 2px 6px;
      border-radius: 4px;
      color: white;
      font-size: 12px;
      font-weight: bold;
      margin-right: 8px;
    }
    
    .school-logo {
      width: 20px;
      height: 20px;
      margin-right: 6px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .school-logo img {
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
    }
    
    .school-name {
      font-size: 13px;
      margin-right: 8px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 120px;
    }
    
    .grade-badge {
      padding: 4px 10px;
      border-radius: 4px;
      font-weight: bold;
      font-size: 14px;
      text-align: center;
      min-width: 32px;
      margin-left: auto;
    }
    
    .stats-container {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
      gap: 16px;
      margin: 20px 0;
    }
    
    .stat-card {
      background: white;
      border-radius: 8px;
      padding: 16px;
      text-align: center;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
      border: 1px solid #EEEEEE;
    }
    
    .stat-title {
      font-size: 14px;
      color: #666666;
      margin-bottom: 8px;
    }
    
    .stat-value {
      font-size: 24px;
      font-weight: bold;
      color: var(--secondary-color);
    }
    
    .stat-value.positive {
      color: #2E7D32;
    }
    
    .stat-value.negative {
      color: #D32F2F;
    }
    
    .footer {
      text-align: center;
      padding: 20px;
      color: #666666;
      font-size: 14px;
    }
    
    .footer a {
      color: var(--primary-color);
      text-decoration: none;
    }
    
    .footer a:hover {
      text-decoration: underline;
    }
    
    /* Position colors */
    .pos-qb, .pos-rb, .pos-fb { background-color: #0076CE; }
    .pos-wr, .pos-te { background-color: #4CAF50; }
    .pos-ot, .pos-iol, .pos-ol, .pos-g, .pos-c { background-color: #9C27B0; }
    .pos-edge, .pos-dl, .pos-idl, .pos-dt, .pos-de { background-color: #F44336; }
    .pos-lb, .pos-ilb, .pos-olb { background-color: #FF9800; }
    .pos-cb, .pos-s, .pos-fs, .pos-ss { background-color: #009688; }
    
    /* Grades */
    .grade-a-plus, .grade-aplus { 
      background-color: var(--grade-a-plus-bg); 
      color: var(--grade-a-plus-color); 
      border: 1px solid var(--grade-a-plus-color);
    }
    .grade-a { 
      background-color: var(--grade-a-bg); 
      color: var(--grade-a-color); 
      border: 1px solid var(--grade-a-color);
    }
    .grade-b-plus, .grade-bplus { 
      background-color: var(--grade-b-plus-bg); 
      color: var(--grade-b-plus-color); 
      border: 1px solid var(--grade-b-plus-color);
    }
    .grade-b { 
      background-color: var(--grade-b-bg); 
      color: var(--grade-b-color); 
      border: 1px solid var(--grade-b-color);
    }
    .grade-c-plus, .grade-cplus { 
      background-color: var(--grade-c-plus-bg); 
      color: var(--grade-c-plus-color); 
      border: 1px solid var(--grade-c-plus-color);
    }
    .grade-c { 
      background-color: var(--grade-c-bg); 
      color: var(--grade-c-color); 
      border: 1px solid var(--grade-c-color);
    }
    .grade-d { 
      background-color: var(--grade-d-bg); 
      color: var(--grade-d-color); 
      border: 1px solid var(--grade-d-color);
    }
    .grade-f { 
      background-color: var(--grade-f-bg); 
      color: var(--grade-f-color); 
      border: 1px solid var(--grade-f-color);
    }
    
    /* Mobile optimization */
    @media (max-width: 768px) {
      .container {
        padding: 12px;
      }
      
      .header {
        padding: 16px;
      }
      
      .header h1 {
        font-size: 22px;
      }
      
      .content {
        padding: 16px;
      }
      
      .section-title {
        font-size: 18px;
      }
      
      .player-meta {
        flex-wrap: wrap;
      }
      
      .school-name {
        max-width: 80px;
      }
      
      .stats-container {
        grid-template-columns: repeat(2, 1fr);
      }
    }
    
    @media (max-width: 480px) {
      .pick-card {
        padding: 8px;
      }
      
      .player-name {
        font-size: 14px;
      }
      
      .position-badge {
        padding: 1px 4px;
        font-size: 10px;
      }
      
      .school-name {
        display: none;
      }
      
      .grade-badge {
        padding: 2px 6px;
        font-size: 12px;
      }
      
      .stats-container {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>$title</h1>
      <p>${userTeam != null ? "$userTeam's " : ""}NFL Draft Results</p>
      <div class="logo">StickToTheModel</div>
    </div>
    <div class="content">
''');

    // Rest of the method remains similar, but using updated HTML components
    // ...
    
    // Close the HTML document
    html.write('''
    </div>
    <div class="footer">
      <p>Generated by <a href="https://yourdomain.com">StickToTheModel NFL Draft Simulator</a></p>
    </div>
  </div>
</body>
</html>
''');

  return html.toString();
}


  
  
  

}