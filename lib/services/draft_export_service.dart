// lib/services/draft_export_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../services/draft_pick_grade_service.dart';
import '../utils/constants.dart';
import '../utils/team_logo_utils.dart';

/// Service for exporting draft results in various formats
class DraftExportService {
  /// Generate a CSV of the draft results
  static String generateCsvData({
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
  }) {
    // Prepare data rows
    List<List<dynamic>> rows = [];
    
    // Add header row
    rows.add([
      'Pick',
      'Team',
      'Player',
      'Position',
      'College',
      'Rank',
      'Value Diff',
      'Grade',
    ]);
    
    // Sort by pick number
    final sortedPicks = List<DraftPick>.from(picks)
      ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // Add data rows
    for (final pick in sortedPicks) {
      if (pick.selectedPlayer != null) {
        final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
        final valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
        
        rows.add([
          pick.pickNumber,
          pick.teamName,
          pick.selectedPlayer!.name,
          pick.selectedPlayer!.position,
          pick.selectedPlayer!.school,
          pick.selectedPlayer!.rank,
          valueDiff,
          gradeInfo['letter'],
        ]);
      }
    }
    
    // Convert to CSV
    return const ListToCsvConverter().convert(rows);
  }
  
  /// Generate Markdown table of draft results
  static String generateMarkdownData({
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    required String title,
    String? userTeam,
  }) {
    // Start with title and header
    StringBuffer md = StringBuffer();
    md.writeln('# $title');
    md.writeln('');
    
    // Add date
    final now = DateTime.now();
    md.writeln('*Generated on ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}*');
    md.writeln('');
    
    // Add the table header
    md.writeln('| Pick | Team | Player | Position | College | Grade |');
    md.writeln('|------|------|--------|----------|---------|-------|');
    
    // Sort by pick number
    final sortedPicks = List<DraftPick>.from(picks)
      ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // Group by rounds
    Map<int, List<DraftPick>> roundPicks = {};
    for (final pick in sortedPicks) {
      if (pick.selectedPlayer == null) continue;
      
      int round = int.tryParse(pick.round) ?? 1;
      if (!roundPicks.containsKey(round)) {
        roundPicks[round] = [];
      }
      roundPicks[round]!.add(pick);
    }
    
    // Add data by round
    List<int> rounds = roundPicks.keys.toList()..sort();
    for (int round in rounds) {
      // Add round header
      md.writeln('');
      md.writeln('### Round $round');
      md.writeln('');
      
      // Add round table
      md.writeln('| Pick | Team | Player | Position | College | Grade |');
      md.writeln('|------|------|--------|----------|---------|-------|');
      
      for (final pick in roundPicks[round]!) {
        if (pick.selectedPlayer != null) {
          final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
          final valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
          
          // Highlight user team
          String teamDisplay = pick.teamName;
          if (userTeam != null && pick.teamName == userTeam) {
            teamDisplay = '**${pick.teamName}**';
          }
          
          md.writeln('| ${pick.pickNumber} | $teamDisplay | ${pick.selectedPlayer!.name} | ${pick.selectedPlayer!.position} | ${pick.selectedPlayer!.school} | ${gradeInfo['letter']} |');
        }
      }
    }
    
    // Add footer
    md.writeln('');
    md.writeln('*Generated by NFL Draft Simulator*');
    
    return md.toString();
  }
  
  /// Generate a plain text summary of the draft results
  static String generateTextSummary({
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    String? userTeam,
    List<TradePackage>? trades,
  }) {
    StringBuffer text = StringBuffer();
    text.writeln('NFL DRAFT SIMULATOR RESULTS');
    text.writeln('=========================');
    text.writeln('');
    
    // Add date
    final now = DateTime.now();
    text.writeln('Generated on ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
    text.writeln('');
    
    // Sort by pick number
    final sortedPicks = List<DraftPick>.from(picks)
      ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // Group by teams
    Map<String, List<DraftPick>> teamPicks = {};
    for (final pick in sortedPicks) {
      if (pick.selectedPlayer == null) continue;
      
      if (!teamPicks.containsKey(pick.teamName)) {
        teamPicks[pick.teamName] = [];
      }
      teamPicks[pick.teamName]!.add(pick);
    }
    
    // If user team is specified, show it first
    if (userTeam != null && teamPicks.containsKey(userTeam)) {
      text.writeln('YOUR TEAM: $userTeam');
      text.writeln('-----------------');
      
      for (final pick in teamPicks[userTeam]!) {
        if (pick.selectedPlayer != null) {
          final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
          final diff = pick.pickNumber - pick.selectedPlayer!.rank;
          String diffText = diff >= 0 ? '+$diff' : '$diff';
          
          text.writeln('Pick #${pick.pickNumber}: ${pick.selectedPlayer!.name}, ${pick.selectedPlayer!.position}, ${pick.selectedPlayer!.school}');
          text.writeln('  Rank: #${pick.selectedPlayer!.rank} ($diffText) | Grade: ${gradeInfo['letter']}');
        }
      }
      
      // Add trades involving user team
      if (trades != null && trades.isNotEmpty) {
        final userTrades = trades.where((t) => 
          t.teamOffering == userTeam || t.teamReceiving == userTeam).toList();
        
        if (userTrades.isNotEmpty) {
          text.writeln('');
          text.writeln('TRADES:');
          for (final trade in userTrades) {
            text.writeln('- ${trade.tradeDescription}');
          }
        }
      }
      
      text.writeln('');
      text.writeln('FULL DRAFT:');
      text.writeln('===========');
    }
    
    // Add all picks by round
    int maxRound = sortedPicks.map((p) => int.tryParse(p.round) ?? 1).reduce((a, b) => a > b ? a : b);
    
    for (int round = 1; round <= maxRound; round++) {
      text.writeln('');
      text.writeln('ROUND $round');
      text.writeln('--------');
      
      final roundPicks = sortedPicks.where((p) => 
        int.tryParse(p.round) == round && p.selectedPlayer != null).toList();
      
      for (final pick in roundPicks) {
        final diff = pick.pickNumber - pick.selectedPlayer!.rank;
        String diffText = diff >= 0 ? '+$diff' : '$diff';
        
        final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
        
        String teamIndicator = (pick.teamName == userTeam) ? '*' : '';
        text.writeln('${pick.pickNumber}. $teamIndicator${pick.teamName}: ${pick.selectedPlayer!.name}, ${pick.selectedPlayer!.position}, ${pick.selectedPlayer!.school} (#${pick.selectedPlayer!.rank}, $diffText) - Grade: ${gradeInfo['letter']}');
      }
    }
    
    // Add footer
    text.writeln('');
    text.writeln('Generated by NFL Draft Simulator - https://nfldraftsim.com');
    
    return text.toString();
  }
  
  /// Generate a HTML summary for web sharing
  static String generateHtmlSummary({
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    String? userTeam,
    List<TradePackage>? trades,
  }) {
    StringBuffer html = StringBuffer();
    
    // Add HTML header and styles
    html.writeln('<!DOCTYPE html>');
    html.writeln('<html lang="en">');
    html.writeln('<head>');
    html.writeln('  <meta charset="UTF-8">');
    html.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    html.writeln('  <title>NFL Draft Simulator Results</title>');
    html.writeln('  <style>');
    html.writeln('    body { font-family: Arial, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; }');
    html.writeln('    h1, h2, h3 { color: #003594; }');
    html.writeln('    .header { text-align: center; margin-bottom: 30px; }');
    html.writeln('    .round-header { background-color: #003594; color: white; padding: 10px; border-radius: 5px; margin-top: 30px; }');
    html.writeln('    table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }');
    html.writeln('    th { background-color: #f2f2f2; text-align: left; padding: 10px; }');
    html.writeln('    td { padding: 10px; border-bottom: 1px solid #ddd; }');
    html.writeln('    .user-team { background-color: #e6f7ff; font-weight: bold; }');
    html.writeln('    .grade-A\\+ { color: #2e7d32; font-weight: bold; }');
    html.writeln('    .grade-A { color: #388e3c; font-weight: bold; }');
    html.writeln('    .grade-B\\+ { color: #1976d2; font-weight: bold; }');
    html.writeln('    .grade-B { color: #1e88e5; font-weight: bold; }');
    html.writeln('    .grade-C\\+ { color: #f57c00; font-weight: bold; }');
    html.writeln('    .grade-C { color: #fb8c00; font-weight: bold; }');
    html.writeln('    .grade-D { color: #e53935; font-weight: bold; }');
    html.writeln('    .grade-F { color: #c62828; font-weight: bold; }');
    html.writeln('    .positive { color: green; }');
    html.writeln('    .negative { color: red; }');
    html.writeln('    .footer { text-align: center; margin-top: 30px; font-size: 14px; color: #666; }');
    html.writeln('  </style>');
    html.writeln('</head>');
    html.writeln('<body>');
    
    // Add header
    html.writeln('  <div class="header">');
    html.writeln('    <h1>NFL Draft Simulator Results</h1>');
    final now = DateTime.now();
    html.writeln('    <p>Generated on ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}</p>');
    html.writeln('  </div>');
    
    // Sort by pick number
    final sortedPicks = List<DraftPick>.from(picks)
      ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // If user team is specified, show it first
    if (userTeam != null) {
      final userPicks = sortedPicks.where((p) => 
        p.teamName == userTeam && p.selectedPlayer != null).toList();
      
      if (userPicks.isNotEmpty) {
        html.writeln('  <h2>Your Team: $userTeam</h2>');
        html.writeln('  <table>');
        html.writeln('    <thead>');
        html.writeln('      <tr>');
        html.writeln('        <th>Pick</th>');
        html.writeln('        <th>Player</th>');
        html.writeln('        <th>Position</th>');
        html.writeln('        <th>College</th>');
        html.writeln('        <th>Rank</th>');
        html.writeln('        <th>Value</th>');
        html.writeln('        <th>Grade</th>');
        html.writeln('      </tr>');
        html.writeln('    </thead>');
        html.writeln('    <tbody>');
        
        for (final pick in userPicks) {
          if (pick.selectedPlayer != null) {
            final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
            final diff = pick.pickNumber - pick.selectedPlayer!.rank;
            final valueCssClass = diff >= 0 ? 'positive' : 'negative';
            final gradeCssClass = 'grade-${gradeInfo['letter'].replaceAll('+', '\\+')}';
            
            html.writeln('      <tr class="user-team">');
            html.writeln('        <td>#${pick.pickNumber}</td>');
            html.writeln('        <td>${pick.selectedPlayer!.name}</td>');
            html.writeln('        <td>${pick.selectedPlayer!.position}</td>');
            html.writeln('        <td>${pick.selectedPlayer!.school}</td>');
            html.writeln('        <td>#${pick.selectedPlayer!.rank}</td>');
            html.writeln('        <td class="$valueCssClass">${diff >= 0 ? '+$diff' : diff}</td>');
            html.writeln('        <td class="$gradeCssClass">${gradeInfo['letter']}</td>');
            html.writeln('      </tr>');
          }
        }
        
        html.writeln('    </tbody>');
        html.writeln('  </table>');
        
        // Add trades involving user team
        if (trades != null && trades.isNotEmpty) {
          final userTrades = trades.where((t) => 
            t.teamOffering == userTeam || t.teamReceiving == userTeam).toList();
          
          if (userTrades.isNotEmpty) {
            html.writeln('  <h3>Trades</h3>');
            html.writeln('  <ul>');
            for (final trade in userTrades) {
              html.writeln('    <li>${trade.tradeDescription}</li>');
            }
            html.writeln('  </ul>');
          }
        }
      }
    }
    
    // Add all picks by round
    int maxRound = sortedPicks.map((p) => int.tryParse(p.round) ?? 1).reduce((a, b) => a > b ? a : b);
    
    for (int round = 1; round <= maxRound; round++) {
      html.writeln('  <h2 class="round-header">Round $round</h2>');
      html.writeln('  <table>');
      html.writeln('    <thead>');
      html.writeln('      <tr>');
      html.writeln('        <th>Pick</th>');
      html.writeln('        <th>Team</th>');
      html.writeln('        <th>Player</th>');
      html.writeln('        <th>Position</th>');
      html.writeln('        <th>College</th>');
      html.writeln('        <th>Rank</th>');
      html.writeln('        <th>Value</th>');
      html.writeln('        <th>Grade</th>');
      html.writeln('      </tr>');
      html.writeln('    </thead>');
      html.writeln('    <tbody>');
      
      final roundPicks = sortedPicks.where((p) => 
        int.tryParse(p.round) == round && p.selectedPlayer != null).toList();
      
      for (final pick in roundPicks) {
        if (pick.selectedPlayer != null) {
          final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
          final diff = pick.pickNumber - pick.selectedPlayer!.rank;
          final valueCssClass = diff >= 0 ? 'positive' : 'negative';
          final gradeCssClass = 'grade-${gradeInfo['letter'].replaceAll('+', '\\+')}';
          final isUserTeam = pick.teamName == userTeam;
          
          html.writeln('      <tr${isUserTeam ? ' class="user-team"' : ''}>');
          html.writeln('        <td>#${pick.pickNumber}</td>');
          html.writeln('        <td>${pick.teamName}</td>');
          html.writeln('        <td>${pick.selectedPlayer!.name}</td>');
          html.writeln('        <td>${pick.selectedPlayer!.position}</td>');
          html.writeln('        <td>${pick.selectedPlayer!.school}</td>');
          html.writeln('        <td>#${pick.selectedPlayer!.rank}</td>');
          html.writeln('        <td class="$valueCssClass">${diff >= 0 ? '+$diff' : diff}</td>');
          html.writeln('        <td class="$gradeCssClass">${gradeInfo['letter']}</td>');
          html.writeln('      </tr>');
        }
      }
      
      html.writeln('    </tbody>');
      html.writeln('  </table>');
    }
    
    // Add footer
    html.writeln('  <div class="footer">');
    html.writeln('    <p>Generated by NFL Draft Simulator</p>');
    html.writeln('  </div>');
    
    html.writeln('</body>');
    html.writeln('</html>');
    
    return html.toString();
  }
  
  /// Share draft results via various methods
  static Future<void> shareDraftResults({
    required BuildContext context,
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    required String title,
    String? userTeam,
    List<TradePackage>? trades,
    bool isWeb = false,
  }) async {
    if (isWeb) {
      await _shareOnWeb(
        picks: picks,
        teamNeeds: teamNeeds,
        title: title,
        userTeam: userTeam,
        trades: trades,
      );
    } else {
      await _shareOnMobile(
        context: context,
        picks: picks,
        teamNeeds: teamNeeds,
        title: title,
        userTeam: userTeam,
        trades: trades,
      );
    }
  }
  
  /// Export draft results for web
  static Future<void> _shareOnWeb({
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    required String title,
    String? userTeam,
    List<TradePackage>? trades,
  }) async {
    // Create an HTML string with the draft data
    final htmlContent = generateHtmlSummary(
      picks: picks, 
      teamNeeds: teamNeeds,
      userTeam: userTeam,
      trades: trades,
    );
    
    // Create a Blob containing the HTML data
    final blob = html.Blob([htmlContent], 'text/html');
    
    // Create a URL for the Blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create an anchor element with download attribute
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'nfl_draft_results.html')
      ..setAttribute('target', '_blank');
      
    // Add the anchor to the document body
    html.document.body?.append(anchor);
    
    // Simulate a click on the anchor to start the download
    anchor.click();
    
    // Clean up by removing the anchor and revoking the URL
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
  
  /// Share draft results on mobile
  static Future<void> _shareOnMobile({
    required BuildContext context,
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    required String title,
    String? userTeam,
    List<TradePackage>? trades,
  }) async {
    // Generate a text summary for sharing
    final textSummary = generateTextSummary(
      picks: picks,
      teamNeeds: teamNeeds,
      userTeam: userTeam,
      trades: trades,
    );
    
    // Get temporary directory to store files
    final directory = await getTemporaryDirectory();
    
    // Create text file
    final textFile = File('${directory.path}/draft_results.txt');
    await textFile.writeAsString(textSummary);
    
    // Create CSV file
    final csvData = generateCsvData(picks: picks, teamNeeds: teamNeeds);
    final csvFile = File('${directory.path}/draft_results.csv');
    await csvFile.writeAsString(csvData);
    
    // Share files
    await Share.shareFiles(
      [textFile.path, csvFile.path],
      subject: 'NFL Draft Simulator Results',
      text: 'Check out my NFL Draft results!',
    );
  }
  
  /// Export just the first round or specific rounds
  static Future<void> exportFirstRound({
    required BuildContext context,
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    String? userTeam,
    bool isWeb = false,
  }) async {
    // Filter picks for just the first round
    final firstRoundPicks = picks.where((pick) => 
      pick.selectedPlayer != null && int.tryParse(pick.round) == 1).toList();
    
    if (firstRoundPicks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No picks made in the first round yet'))
      );
      return;
    }
    
    await shareDraftResults(
      context: context,
      picks: firstRoundPicks,
      teamNeeds: teamNeeds,
      title: 'NFL Draft Simulator - First Round Results',
      userTeam: userTeam,
      isWeb: isWeb,
    );
  }
  
  /// Export team picks
  static Future<void> exportTeamPicks({
    required BuildContext context,
    required List<DraftPick> picks,
    required List<TeamNeed> teamNeeds,
    required String team,
    List<TradePackage>? trades,
    bool isWeb = false,
  }) async {
    // Filter picks for just the specified team
    final teamPicks = picks.where((pick) => 
      pick.selectedPlayer != null && pick.teamName == team).toList();
    
    if (teamPicks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No picks made by $team yet'))
      );
      return;
    }
    
    // Filter trades for just those involving this team
    final teamTrades = trades?.where((trade) => 
      trade.teamOffering == team || trade.teamReceiving == team).toList();
    
    await shareDraftResults(
      context: context,
      picks: teamPicks,
      teamNeeds: teamNeeds,
      title: 'NFL Draft Simulator - $team Draft Results',
      userTeam: team,
      trades: teamTrades,
      isWeb: isWeb,
    );
  }
  
  /// Create a screenshot of a widget
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      // Wait for any pending operations to complete
      await Future.delayed(const Duration(milliseconds: 20));
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }
}