// lib/services/draft_export_service.dart
import 'dart:convert';
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
import '../services/draft_pick_grade_service.dart';
import '../utils/constants.dart';

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
      // Handle mobile export
      try {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/draft_results.html').writeAsString(htmlContent);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'StickToTheModel',
        );
      } catch (e) {
        // If sharing fails, fallback to clipboard
        await Clipboard.setData(ClipboardData(text: _generatePlainText(picks, userTeam)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft results copied to clipboard (plain text)')),
        );
      }
    }
  }

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
    // Style colors
    const String primaryColor = '#D50A0A'; // NFL red
    const String secondaryColor = '#002244'; // NFL navy

    // Calculate overall draft stats
    Map<String, dynamic> draftStats = _calculateOverallStats(picks, trades, teamNeeds);
    
    // Sort picks by pick number
    picks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));

    // Build the HTML
    StringBuffer html = StringBuffer();
    
    // HTML header
    html.write('''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
  :root {
    --primary-color: $primaryColor;
    --secondary-color: $secondaryColor;
    --light-bg: #f8f9fa;
    --dark-bg: #343a40;
    --light-text: #212529;
    --dark-text: #f8f9fa;
    --light-border: #dee2e6;
    --highlight-bg: #f0f7ff;
  }
  
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.6;
    color: var(--light-text);
    background-color: var(--light-bg);
    margin: 0;
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
  }
  
  .header {
    background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
    color: white;
    padding: 20px;
    border-radius: 8px 8px 0 0;
    margin-bottom: 20px;
  }
  
  .header h1 {
    margin: 0;
    font-size: 24px;
  }
  
  .header p {
    margin: 8px 0 0;
    opacity: 0.9;
  }
  
  .section {
    background: white;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    padding: 20px;
    margin-bottom: 20px;
  }
  
  .section-title {
    font-size: 18px;
    font-weight: bold;
    color: var(--secondary-color);
    margin-top: 0;
    padding-bottom: 10px;
    border-bottom: 1px solid var(--light-border);
  }
  
  .pick-row {
    display: flex;
    align-items: center;
    padding: 12px;
    border-bottom: 1px solid var(--light-border);
  }
  
  .pick-row:last-child {
    border-bottom: none;
  }
  
  .pick-row.user-team {
    background-color: var(--highlight-bg);
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
  
  .round-1 { background-color: #0076CE; }
  .round-2 { background-color: #4CAF50; }
  .round-3 { background-color: #FF9800; }
  .round-4 { background-color: #9C27B0; }
  .round-5 { background-color: #F44336; }
  .round-6 { background-color: #009688; }
  .round-7 { background-color: #795548; }
  
  .team-logo {
    width: 40px;
    height: 40px;
    margin-right: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    overflow: hidden;
  }
  
  .team-logo img {
    width: 36px;
    height: 36px;
    object-fit: contain;
  }

  .pick-card {
  background-color: white;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.12);
  margin-bottom: 12px;
  overflow: hidden;
  border: 1px solid var(--light-border);
}

.pick-card.user-team {
  border: 1px solid var(--primary-color);
  background-color: var(--highlight-bg);
}

.pick-card-header {
  display: flex;
  align-items: center;
  padding: 10px 12px;
  border-bottom: 1px solid var(--light-border);
}

.pick-number-badge {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  margin-right: 8px;
  flex-shrink: 0;
}

.team-badge {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 10px;
  flex-shrink: 0;
}

.pick-player-name {
  font-weight: bold;
  font-size: 16px;
  flex-grow: 1;
}

.grade-pill {
  padding: 3px 8px;
  border-radius: 30px;
  font-weight: bold;
  font-size: 14px;
  min-width: 28px;
  text-align: center;
}

.pick-card-details {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  gap: 12px;
}

.position-pill {
  padding: 3px 8px;
  border-radius: 4px;
  color: white;
  font-weight: bold;
  font-size: 12px;
}

.school-info {
  display: flex;
  align-items: center;
  font-size: 14px;
  color: #6c757d;
}

.value-text {
  margin-left: auto;
  font-size: 13px;
  font-weight: 500;
}

.team-pick-badge {
  background-color: white;
  border: 1px solid var(--light-border);
  border-radius: 30px;
  padding: 4px 8px;
  font-size: 12px;
  display: flex;
  align-items: center;
}
  
  .pick-details {
    flex-grow: 1;
  }
  
  .player-name {
  font-weight: bold;
  font-size: 16px;
  margin-bottom: 2px;
}
  
  .player-info {
    display: flex;
    align-items: center;
    font-size: 14px;
    color: #6c757d;
  }
  
  .position-badge {
  padding: 3px 6px;
  border-radius: 3px;
  margin-right: 0;
  color: white;
  font-size: 12px;
  font-weight: bold;
  display: inline-block;
}
  
    .school-logo {
    width: 24px;
    height: 24px;
    margin-right: 8px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    overflow: visible;
    vertical-align: middle;
  }

  .school-logo img {
    width: 20px;
    height: 20px;
    object-fit: contain;
    vertical-align: middle;
  }
  
  .school-name {
    margin-right: 10px;
  }
  
  .value-indicator {
    display: flex;
    align-items: center;
    font-size: 13px;
    margin-left: auto;
  }
  
  .value-badge {
    padding: 2px 8px;
    border-radius: 4px;
    font-weight: bold;
    font-size: 12px;
    margin-left: 8px;
  }
  
  .grade-badge {
    display: inline-block !important;
    padding: 4px 10px;
    border-radius: 4px;
    font-weight: bold;
    font-size: 14px;
    margin-left: 10px;
    text-align: center;
    min-width: 28px;
  }

/* Player card styling for first round and full export */
.player-card {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  margin-bottom: 8px;
  overflow: hidden;
  border: 1px solid var(--light-border);
}

.player-card.user-team {
  border: 1px solid var(--primary-color);
}

.player-card-header {
  display: flex;
  align-items: center;
  padding: 8px 10px;
  gap: 8px;
}

.pick-circle {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background-color: #4285F4;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 14px;
  flex-shrink: 0;
}

.team-icon {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.team-icon img {
  width: 24px;
  height: 24px;
  object-fit: contain;
}

.player-card-name {
  font-weight: bold;
  font-size: 16px;
  flex-grow: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.player-card-details {
  display: flex;
  justify-content: space-between;
  padding: 4px 10px 8px;
  border-top: 1px solid #f0f0f0;
}

.player-card-position {
  display: flex;
  align-items: center;
}

.position-pill {
  padding: 4px 8px;
  border-radius: 4px;
  color: white;
  font-weight: bold;
  font-size: 12px;
  display: inline-block;
}

.player-card-school {
  display: flex;
  align-items: center;
  color: #6c757d;
  font-size: 14px;
  gap: 4px;
}

.school-icon {
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.school-icon img {
  width: 18px;
  height: 18px;
  object-fit: contain;
}

.player-card-rank {
  margin-left: auto;
  display: flex;
  align-items: center;
  font-size: 13px;
  white-space: nowrap;
}

/* First round specific grid layout */
.first-round-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  margin-bottom: 20px;
}

@media (min-width: 992px) {
  .first-round-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

/* Condensed player card for first round */
.first-round-card {
  height: 90px;
  display: flex;
  flex-direction: column;
}

.first-round-header {
  padding: 6px 8px;
}

.first-round-details {
  padding: 3px 8px 6px;
}

.value-pill {
  padding: 1px 6px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: bold;
}

.value-pill.positive {
  background-color: rgba(76, 175, 80, 0.15);
  color: #2e7d32;
}

.value-pill.negative {
  background-color: rgba(244, 67, 54, 0.15);
  color: #d32f2f;
}

  /* Player meta layout styles */
.player-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.rank-row {
  display: flex;
  gap: 8px;
}

.school-container {
  display: flex;
  align-items: center;
  gap: 4px;
}

.value-tag {
  font-weight: bold;
}

/* Single row stats styles */
.draft-stats-row {
  display: flex;
  justify-content: space-between;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  margin: 15px 0;
  overflow: hidden;
}

.stat-column {
  flex: 1;
  border-right: 1px solid var(--light-border);
  text-align: center;
  padding: 15px 10px;
}

.stat-column:last-child {
  border-right: none;
}

.stat-item {
  padding: 0;
  box-shadow: none;
  min-width: auto;
}

.stat-title {
  font-size: 14px;
  color: #6c757d;
  margin-bottom: 5px;
}

.stat-value {
  font-size: 20px;
  font-weight: bold;
  color: var(--secondary-color);
}
  
  .pos-qb, .pos-rb, .pos-fb { background-color: #0076CE; }
  .pos-wr, .pos-te { background-color: #4CAF50; }
  .pos-ot, .pos-iol, .pos-ol, .pos-g, .pos-c { background-color: #9C27B0; }
  .pos-edge, .pos-dl, .pos-idl, .pos-dt, .pos-de { background-color: #F44336; }
  .pos-lb, .pos-ilb, .pos-olb { background-color: #FF9800; }
  .pos-cb, .pos-s, .pos-fs, .pos-ss { background-color: #009688; }
  
  /* Grade styling with !important for all variations */
  .grade-a-plus, .grade-aplus { background-color: rgba(76, 175, 80, 0.2) !important; color: #2e7d32 !important; border: 1px solid #2e7d32 !important; }
  .grade-a { background-color: rgba(76, 175, 80, 0.2) !important; color: #388e3c !important; border: 1px solid #388e3c !important; }
  .grade-a-minus, .grade-aminus { background-color: rgba(76, 175, 80, 0.2) !important; color: #388e3c !important; border: 1px solid #388e3c !important; }
  .grade-b-plus, .grade-bplus { background-color: rgba(33, 150, 243, 0.2) !important; color: #1976d2 !important; border: 1px solid #1976d2 !important; }
  .grade-b { background-color: rgba(33, 150, 243, 0.2) !important; color: #1976d2 !important; border: 1px solid #1976d2 !important; }
  .grade-b-minus, .grade-bminus { background-color: rgba(33, 150, 243, 0.2) !important; color: #1976d2 !important; border: 1px solid #1976d2 !important; }
  .grade-c-plus, .grade-cplus { background-color: rgba(255, 152, 0, 0.2) !important; color: #f57c00 !important; border: 1px solid #f57c00 !important; }
  .grade-c { background-color: rgba(255, 152, 0, 0.2) !important; color: #ef6c00 !important; border: 1px solid #ef6c00 !important; }
  .grade-c-minus, .grade-cminus { background-color: rgba(255, 152, 0, 0.2) !important; color: #ef6c00 !important; border: 1px solid #ef6c00 !important; }
  .grade-d-plus, .grade-dplus { background-color: rgba(244, 67, 54, 0.2) !important; color: #d32f2f !important; border: 1px solid #d32f2f !important; }
  .grade-d { background-color: rgba(244, 67, 54, 0.2) !important; color: #d32f2f !important; border: 1px solid #d32f2f !important; }
  .grade-d-minus, .grade-dminus { background-color: rgba(244, 67, 54, 0.2) !important; color: #d32f2f !important; border: 1px solid #d32f2f !important; }
  .grade-f { background-color: rgba(244, 67, 54, 0.2) !important; color: #d32f2f !important; border: 1px solid #d32f2f !important; }

  .value-positive { color: #2e7d32; }
  .value-negative { color: #d32f2f; }
  
  .first-round-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
  }
  
  .column {
    display: flex;
    flex-direction: column;
  }
  
  .grid-divider {
    width: 1px;
    background-color: var(--light-border);
    margin: 0 10px;
  }
  
  .compact-pick {
    display: flex;
    align-items: center;
    padding: 8px;
    border-radius: 4px;
    border: 1px solid var(--light-border);
    margin-bottom: 8px;
    background-color: white;
  }
  
  .compact-pick.user-team {
    background-color: var(--highlight-bg);
  }
  
  .compact-number {
    width: 24px;
    height: 24px;
    border-radius: 50%;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 12px;
    margin-right: 8px;
  }
  
  .compact-details {
    flex-grow: 1;
    font-size: 13px;
  }
  
  .compact-name {
    font-weight: bold;
    margin-bottom: 2px;
  }
  
  .player-meta {
    display: flex;
    align-items: center;
    margin-top: 2px;
  }
  
  .compact-position {
    display: inline-block;
    padding: 1px 4px;
    border-radius: 2px;
    color: white;
    font-size: 10px;
    margin-right: 4px;
  }
  
  .compact-school {
    font-size: 11px;
    color: #6c757d;
    display: flex;
    align-items: center;
  }
  
  .draft-stats {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    gap: 10px;
    margin-top: 15px;
    margin-bottom: 15px;
  }
  
  .stat-item {
    flex: 1;
    background-color: white;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    padding: 10px 15px;
    min-width: 100px;
    text-align: center;
  }
  
  .stat-title {
    font-size: 14px;
    color: #6c757d;
    margin-bottom: 5px;
  }
  
  .stat-value {
    font-size: 20px;
    font-weight: bold;
    color: var(--secondary-color);
  }
  
  .stat-value.positive {
    color: #2e7d32;
  }
  
  .stat-value.negative {
    color: #d32f2f;
  }
  
  .grade-summary {
    background: linear-gradient(135deg, #f0f2f5, #e9ecef);
    padding: 15px;
    border-radius: 8px;
    border-left: 4px solid var(--secondary-color);
    margin-bottom: 20px;
  }
  
  .team-grade {
    font-size: 28px;
    font-weight: bold;
    margin-right: 15px;
    display: none; /* Hide this element since we're not using it */
  }
  
  .team-picks-list {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 10px;
  }
  
  .pick-badge-content {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
  }
  
  .badge-player-name {
    font-weight: bold;
    font-size: 13px;
    margin-bottom: 2px;
  }
  
  .badge-details {
    display: flex;
    align-items: center;
    gap: 6px;
  }
  
  .badge-school {
    font-size: 11px;
    color: #6c757d;
  }
  
  .team-pick-badge {
    background-color: white;
    border: 1px solid var(--light-border);
    border-radius: 8px;
    padding: 8px 12px;
    font-size: 12px;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    min-width: 120px;
  }
  
  .footer {
    text-align: center;
    margin-top: 30px;
    color: #6c757d;
    font-size: 12px;
  }
  
  .trade-icon {
    color: #FF9800;
    font-size: 14px;
    margin-left: 5px;
  }
  
  @media (max-width: 768px) {
    .first-round-grid {
      grid-template-columns: 1fr;
    }
    
    .header {
      padding: 15px;
    }
    
    .section {
      padding: 12px;
    }
    
    .draft-stats {
      flex-direction: column;
    }
  }
  .compact-first-round-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 8px;
  }
  
  .compact-first-pick {
    display: flex;
    align-items: center;
    padding: 4px;
    border-radius: 4px;
    border: 1px solid var(--light-border);
    background-color: white;
    max-height: 50px;
  }
  
  .compact-first-pick.user-team {
    background-color: var(--highlight-bg);
  }
  
  .pick-circle {
    width: 22px;
    height: 22px;
    border-radius: 50%;
    background-color: #0076CE;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 11px;
    margin-right: 4px;
    flex-shrink: 0;
  }
  
  .team-small-logo {
    width: 20px;
    height: 20px;
    margin-right: 4px;
    flex-shrink: 0;
  }
  
  .team-small-logo img {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
  }
  
  .pick-info {
    flex-grow: 1;
    overflow: hidden;
  }
  
  .player-title {
    font-weight: bold;
    font-size: 10px;
    line-height: 1.1;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    margin-bottom: 1px;
  }
  
  .pick-details {
  flex-grow: 1;
  display: flex;
  flex-direction: column;
}
  
  .small-position {
    font-size: 8px;
    padding: 1px 2px;
    border-radius: 2px;
    color: white;
    margin-right: 3px;
  }
  
  .school-small-logo {
    width: 14px;
    height: 14px;
    display: inline-block;
    margin-left: 3px;
    margin-right: 3px;
  }
  
  .school-small-logo img {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
  }
  
  .small-value {
    font-size: 9px;
    margin-left: auto;
    color: inherit;
  }
  
  .small-grade {
    display: inline-block !important;
    font-size: 9px;
    padding: 1px 4px;
    min-width: 14px;
    border-radius: 3px;
    font-weight: bold;
    margin-left: 4px;
    text-align: center;
    flex-shrink: 0;
  }

  /* New card style matching the design in screenshots */
  .draft-card {
    background-color: #f8f9fa;
    border-radius: 8px;
    border: 1px solid #dee2e6;
    padding: 8px;
    margin-bottom: 8px;
    display: flex;
    align-items: center;
    position: relative;
  }
  
  .draft-card.user-team {
    background-color: #e7f5ff;
    border-color: #74c0fc;
  }
  
  .pick-circle {
    width: 36px;
    height: 36px;
    background-color: #4dabf7;
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 14px;
    margin-right: 8px;
    flex-shrink: 0;
  }
  
  .team-logo-small {
    width: 30px;
    height: 30px;
    margin-right: 10px;
    flex-shrink: 0;
  }
  
  .team-logo-small img {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }
  
  .player-content {
    flex-grow: 1;
    min-width: 0;
    margin-right: 8px;
  }
  
  .player-name {
    font-weight: bold;
    font-size: 14px;
    margin-bottom: 4px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  
  .grade-column {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }
  
  .rank-small {
    font-size: 10px;
    text-align: center;
    margin-top: 2px;
    white-space: nowrap;
  }
  
  .card-details {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 4px;
    font-size: 12px;
  }
  
  .position-pill {
    padding: 2px 6px;
    border-radius: 4px;
    color: white;
    font-weight: bold;
    font-size: 11px;
  }
  
  .school-logo-sm {
    width: 16px;
    height: 16px;
    margin: 0 4px;
  }
  
  .school-logo-sm img {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }
  
  .school-text {
    color: #6c757d;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 90px;
  }
  
  .rank-value {
    margin-left: auto;
    white-space: nowrap;
    font-size: 11px;
  }
  
  .grade-badge {
    padding: 2px 8px;
    border-radius: 20px;
    font-size: 14px;
    font-weight: bold;
    text-align: center;
    flex-shrink: 0;
  }
  
  /* First round grid with new card styling */
  .compact-first-round-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
    margin-top: 10px;
  }
  
  @media (min-width: 992px) {
    .compact-first-round-grid {
      grid-template-columns: repeat(2, 1fr);
    }
  }
  
  @media (max-width: 768px) {
    .compact-first-round-grid {
      grid-template-columns: 1fr;
    }
    
    .school-text {
      max-width: 60px;
    }
  }
</style>
</head>
<body>
  <div class="header">
    <h1>$title</h1>
    <p>@StickToTheModel</p>
  </div>
''');

    // Add overall stats if showing all teams
    if (showAllTeams) {
      html.write('''
  <div class="draft-stats-row">
  <div class="stat-column">
    <div class="stat-item">
      <div class="stat-title">Total Picks</div>
      <div class="stat-value">${draftStats['totalPicks']}</div>
    </div>
  </div>
  <div class="stat-column">
    <div class="stat-item">
      <div class="stat-title">Total Trades</div>
      <div class="stat-value">${draftStats['totalTrades']}</div>
    </div>
  </div>
  <div class="stat-column">
    <div class="stat-item">
      <div class="stat-title">Average Value</div>
      <div class="stat-value ${draftStats['avgValueDiff'] >= 0 ? 'positive' : 'negative'}">
        ${draftStats['avgValueDiff'] >= 0 ? '+' : ''}${draftStats['avgValueDiff'].toStringAsFixed(1)}
      </div>
    </div>
  </div>
</div>
''');
    }

    // Add team summary if requested
    if (showTeamSummary && userTeam != null) {
      // Calculate team grade
      Map<String, dynamic> teamGrade = _calculateTeamGrade(
        picks.where((p) => p.teamName == userTeam).toList(),
        trades,
        userTeam,
      );
      
      html.write('''
  <div class="section">
    <div class="grade-summary">
      <div style="display: flex; align-items: center; justify-content: space-between;">
        <div style="display: flex; align-items: center;">
          <div class="team-logo">
            <img src="https://a.espncdn.com/i/teamlogos/nfl/500/${_getTeamAbbreviation(userTeam).toLowerCase()}.png" alt="$userTeam logo">
          </div>
          <span style="font-size: 18px; font-weight: bold; margin-left: 10px;">$userTeam</span>
        </div>
        <div>
          <span class="grade-badge grade-${teamGrade['grade'].replaceAll('+', '-plus').toLowerCase()}">${teamGrade['grade']}</span>
        </div>
      </div>
      <p style="margin: 10px 0; font-style: italic;">${teamGrade['description']}</p>
      <div class="team-picks-list">
''');

      // Add team pick badges - Just position badges for grade summary
      for (var pick in picks.where((p) => p.teamName == userTeam && p.selectedPlayer != null)) {
        html.write('''
        <div class="team-pick-badge">
          <span class="position-badge pos-${pick.selectedPlayer!.position.toLowerCase()}">${pick.selectedPlayer!.position}</span>
        </div>
''');
      }

      html.write('''
      </div>
    </div>
  </div>
''');
    }

    // First round two-column layout if requested
    if (showTwoColumnLayout) {
      html.write('''
  <div class="section">
    <div class="compact-first-round-grid">
''');

      // Create one container for each pick
      for (var i = 0; i < picks.length; i++) {
        _writeCompactFirstRoundPickHtml(html, picks[i], teamNeeds, userTeam);
      }

      html.write('''
    </div>
  </div>
''');
    }

    // Main picks section
    if (!showTwoColumnLayout || !showRoundSummary) {
      html.write('''
  <div class="section">
    <h2 class="section-title">Draft Picks</h2>
''');

      // Write each pick with details
  for (var pick in picks) {
    if (pick.selectedPlayer == null) continue;

    // Always use the card style
    _writeCompactPickHtml(html, pick, teamNeeds, userTeam);
  }

      html.write('''
  </div>
''');
    }

    // Footer
    html.write('''
  <div class="footer">
    <p>Generated by StickToTheModel Mock Draft Simulator</p>
  </div>
</body>
</html>
''');

    return html.toString();
  }

  /// Helper to write compact pick HTML for 2-column layout
static void _writeCompactPickHtml(StringBuffer html, DraftPick pick, List<TeamNeed> teamNeeds, String? userTeam) {
  if (pick.selectedPlayer == null) return;
  
  // Calculate pick grade
  Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
  String letterGrade = gradeInfo['letter'];
  
  // Value differential
  int valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
  String valueDiffText = valueDiff >= 0 ? "+$valueDiff" : "$valueDiff";
  String valueDiffClass = valueDiff >= 0 ? "value-positive" : "value-negative";
  
  // Grade CSS class
  String gradeClass = letterGrade.toLowerCase();
  if (gradeClass.contains('+')) {
    gradeClass = gradeClass.replaceAll('+', '-plus');
  } else if (gradeClass.contains('-')) {
    gradeClass = gradeClass.replaceAll('-', '-minus');
  }
  
  // Position CSS class
  String positionClass = pick.selectedPlayer!.position.toLowerCase();
  
  // User team highlighting
  String userTeamClass = (userTeam != null && pick.teamName == userTeam) ? "user-team" : "";
  
  // Team abbreviation for logo
  String teamAbbr = _getTeamAbbreviation(pick.teamName);
  
  html.write('''
    <div class="draft-card $userTeamClass">
      <div class="pick-circle round-${pick.round}">${pick.pickNumber}</div>
      <div class="team-logo-small">
        <img src="https://a.espncdn.com/i/teamlogos/nfl/500/${teamAbbr.toLowerCase()}.png" alt="${pick.teamName}">
      </div>
      <div class="player-content">
        <div class="player-name">${pick.selectedPlayer!.name}</div>
        <div class="card-details">
          <div class="position-pill pos-$positionClass">${pick.selectedPlayer!.position}</div>
          <div class="school-logo-sm">
            <img src="https://a.espncdn.com/i/teamlogos/ncaa/500/${_getCollegeId(pick.selectedPlayer!.school)}.png" 
                 alt="" onerror="this.style.display='none';">
          </div>
          <div class="school-text">${pick.selectedPlayer!.school}</div>
          <div class="rank-value $valueDiffClass">Rank: #${pick.selectedPlayer!.rank} ($valueDiffText)</div>
        </div>
      </div>
      <div class="grade-badge grade-$gradeClass">$letterGrade</div>
    </div>
  ''');
}

  /// Calculate overall draft stats
  static Map<String, dynamic> _calculateOverallStats(
    List<DraftPick> picks, 
    List<TradePackage> trades,
    List<TeamNeed> teamNeeds
  ) {
    // Count completed picks
    int totalPicks = picks.where((p) => p.selectedPlayer != null).length;
    int totalTrades = trades.length;
    
    // Calculate average value differential
    double totalValueDiff = 0;
    for (var pick in picks) {
      if (pick.selectedPlayer != null) {
        totalValueDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
      }
    }
    double avgValueDiff = totalPicks > 0 ? totalValueDiff / totalPicks : 0;
    
    // Count team grades
    Map<String, String> teamGrades = {};
    Map<String, List<DraftPick>> teamPicks = {};
    
    // Group picks by team
    for (var pick in picks) {
      if (pick.selectedPlayer != null) {
        if (!teamPicks.containsKey(pick.teamName)) {
          teamPicks[pick.teamName] = [];
        }
        teamPicks[pick.teamName]!.add(pick);
      }
    }
    
    // Calculate grades for each team
    for (var team in teamPicks.keys) {
      final teamTradeList = trades.where(
        (trade) => trade.teamOffering == team || trade.teamReceiving == team
      ).toList();
      
      final gradeInfo = _calculateTeamGrade(teamPicks[team]!, teamTradeList, team);
      teamGrades[team] = gradeInfo['grade'];
    }
    
    // Count grades
    int aGrades = teamGrades.values.where((g) => g.startsWith('A')).length;
    int bGrades = teamGrades.values.where((g) => g.startsWith('B')).length;
    int cGrades = teamGrades.values.where((g) => g.startsWith('C')).length;
    int dGrades = teamGrades.values.where((g) => g.startsWith('D')).length;
    
    // Count positions drafted
    Map<String, int> positionCounts = {};
    for (var pick in picks) {
      if (pick.selectedPlayer != null) {
        final position = pick.selectedPlayer!.position;
        positionCounts[position] = (positionCounts[position] ?? 0) + 1;
      }
    }
    
    // Return stats map
    return {
      'totalPicks': totalPicks,
      'totalTrades': totalTrades,
      'avgValueDiff': avgValueDiff,
      'aGrades': aGrades,
      'bGrades': bGrades,
      'cGrades': cGrades,
      'dGrades': dGrades,
      'positionCounts': positionCounts,
    };
  }
  
  /// Calculate team grade based on picks and trades
  static Map<String, dynamic> _calculateTeamGrade(
    List<DraftPick> teamPicks, 
    List<TradePackage> teamTrades,
    String teamName
  ) {
    if (teamPicks.isEmpty) {
      return {
        'grade': 'N/A',
        'value': 0.0,
        'description': 'No picks made',
        'pickCount': 0,
      };
    }
    
    // Calculate average rank differential
    double totalDiff = 0;
    for (var pick in teamPicks) {
      if (pick.selectedPlayer != null) {
        totalDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
      }
    }
    double avgDiff = totalDiff / teamPicks.length;
    
    // Calculate trade value
    double tradeValue = 0;
    for (var trade in teamTrades) {
      if (trade.teamOffering == teamName) {
        tradeValue -= trade.valueDifferential;
      } else if (trade.teamReceiving == teamName) {
        tradeValue += trade.valueDifferential;
      }
    }
    
    // Trade value per pick
    double tradeValuePerPick = teamPicks.isNotEmpty ? tradeValue / teamPicks.length : 0;
    
    // Combine metrics for final grade
    double combinedValue = avgDiff + (tradeValuePerPick / 10);
    
    // Determine letter grade based on value
    String grade;
    String description;
    
    if (combinedValue >= 15) {
      grade = 'A+';
      description = 'Outstanding draft with exceptional value';
    } else if (combinedValue >= 10) {
      grade = 'A';
      description = 'Excellent draft with great value picks';
    } else if (combinedValue >= 5) {
      grade = 'B+';
      description = 'Very good draft with solid value picks';
    } else if (combinedValue >= 0) {
      grade = 'B';
      description = 'Solid draft with good value picks';
    } else if (combinedValue >= -5) {
      grade = 'C+';
      description = 'Average draft with some reaches';
    } else if (combinedValue >= -10) {
      grade = 'C';
      description = 'Below average draft with several reaches';
    } else {
      grade = 'D';
      description = 'Poor draft with significant reaches';
    }
    
    return {
      'grade': grade,
      'value': avgDiff,
      'description': description,
      'pickCount': teamPicks.length,
      'tradeValue': tradeValue,
    };
  }
  
  /// Get NFL team abbreviation for logo URLs
  static String _getTeamAbbreviation(String teamName) {
    // Map full team names to abbreviations
    const Map<String, String> teamMap = NFLTeamMappings.fullNameToAbbreviation;
    
    // Return the abbreviation if found in the map
    if (teamMap.containsKey(teamName)) {
      return teamMap[teamName]!;
    }
    
    // For unknown teams or if the map fails, generate a simple abbreviation
    if (teamName.length <= 3) {
      return teamName;
    }
    
    // Generate from team name (e.g., "New York Giants" -> "NYG")
    final words = teamName.split(' ');
    if (words.length >= 2) {
      return words.map((word) => word.isNotEmpty ? word[0] : '').join('');
    }
    
    // Fallback to first 3 characters
    return teamName.substring(0, min(3, teamName.length));
  }
  
  /// Get ESPN college ID for school logos
  static String _getCollegeId(String schoolName) {
    // Try to get the ESP ID from the mapping
    final collegeId = CollegeTeamESPNIds.findIdForSchool(schoolName);
    
    // Return the ID if found
    if (collegeId != null) {
      return collegeId;
    }
    
    // Fallback to placeholder
    return 'placeholder';
  }

/// Helper to write compact first round pick HTML
static void _writeCompactFirstRoundPickHtml(StringBuffer html, DraftPick pick, List<TeamNeed> teamNeeds, String? userTeam) {
  if (pick.selectedPlayer == null) return;
  
  // Calculate pick grade
  Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
  String letterGrade = gradeInfo['letter'];
  
  // Value differential
  int valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
  String valueDiffText = valueDiff >= 0 ? "+$valueDiff" : "$valueDiff";
  String valueDiffClass = valueDiff >= 0 ? "value-positive" : "value-negative";
  
  // Grade CSS class - Fix for minus grades
  String gradeClass = letterGrade.toLowerCase();
  if (gradeClass.contains('+')) {
    gradeClass = gradeClass.replaceAll('+', '-plus');
  } else if (gradeClass.contains('-')) {
    gradeClass = gradeClass.replaceAll('-', '-minus');
  }
  
  // Position CSS class
  String positionClass = pick.selectedPlayer!.position.toLowerCase();
  
  // User team highlighting
  String userTeamClass = (userTeam != null && pick.teamName == userTeam) ? "user-team" : "";
  
  // Team abbreviation for logo
  String teamAbbr = _getTeamAbbreviation(pick.teamName);
  
  html.write('''
    <div class="draft-card $userTeamClass">
      <div class="pick-circle">${pick.pickNumber}</div>
      <div class="team-logo-small">
        <img src="https://a.espncdn.com/i/teamlogos/nfl/500/${teamAbbr.toLowerCase()}.png" alt="${pick.teamName}">
      </div>
      <div class="player-content">
        <div class="player-name">${pick.selectedPlayer!.name}</div>
        <div class="card-details">
          <div class="position-pill pos-$positionClass">${pick.selectedPlayer!.position}</div>
          <div class="school-logo-sm">
            <img src="https://a.espncdn.com/i/teamlogos/ncaa/500/${_getCollegeId(pick.selectedPlayer!.school)}.png" 
                 alt="" onerror="this.style.display='none';">
          </div>
        </div>
      </div>
      <div class="grade-column">
        <div class="grade-badge grade-$gradeClass">$letterGrade</div>
        <div class="rank-small $valueDiffClass">Rank: #${pick.selectedPlayer!.rank} ($valueDiffText)</div>
      </div>
    </div>
  ''');
}
}