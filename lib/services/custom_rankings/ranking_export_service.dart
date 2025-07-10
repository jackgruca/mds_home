import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/services/custom_rankings/enhanced_calculation_engine.dart';

class RankingExportService {
  static const String csvMimeType = 'text/csv';
  static const String jsonMimeType = 'application/json';
  static const String htmlMimeType = 'text/html';

  /// Export rankings to CSV format
  static Future<void> exportToCsv({
    required List<CustomRankingResult> results,
    required List<EnhancedRankingAttribute> attributes,
    required String rankingName,
    String? fileName,
  }) async {
    final csvContent = _generateCsvContent(results, attributes, rankingName);
    final finalFileName = fileName ?? '${_sanitizeFileName(rankingName)}_rankings.csv';
    
    if (kIsWeb) {
      _downloadWebFile(csvContent, finalFileName, csvMimeType);
    } else {
      // For mobile platforms, you would use file_picker or similar
      throw UnsupportedError('Mobile export not implemented yet');
    }
  }

  /// Export rankings to JSON format
  static Future<void> exportToJson({
    required List<CustomRankingResult> results,
    required List<EnhancedRankingAttribute> attributes,
    required String rankingName,
    String? fileName,
  }) async {
    final jsonContent = _generateJsonContent(results, attributes, rankingName);
    final finalFileName = fileName ?? '${_sanitizeFileName(rankingName)}_rankings.json';
    
    if (kIsWeb) {
      _downloadWebFile(jsonContent, finalFileName, jsonMimeType);
    } else {
      throw UnsupportedError('Mobile export not implemented yet');
    }
  }

  /// Export rankings to HTML report
  static Future<void> exportToHtmlReport({
    required List<CustomRankingResult> results,
    required List<EnhancedRankingAttribute> attributes,
    required String rankingName,
    required String position,
    RankingAnalysis? analysis,
    String? fileName,
  }) async {
    final htmlContent = await _generateHtmlReport(
      results, attributes, rankingName, position, analysis,
    );
    final finalFileName = fileName ?? '${_sanitizeFileName(rankingName)}_report.html';
    
    if (kIsWeb) {
      _downloadWebFile(htmlContent, finalFileName, htmlMimeType);
    } else {
      throw UnsupportedError('Mobile export not implemented yet');
    }
  }

  /// Generate shareable methodology summary
  static Map<String, dynamic> generateMethodologySummary({
    required List<EnhancedRankingAttribute> attributes,
    required String rankingName,
    required String position,
  }) {
    final totalWeight = attributes.fold(0.0, (sum, attr) => sum + attr.weight);
    final categoryWeights = <String, double>{};
    
    for (final attr in attributes) {
      categoryWeights[attr.category] = (categoryWeights[attr.category] ?? 0.0) + attr.weight;
    }
    
    final primaryCategory = categoryWeights.isNotEmpty
        ? categoryWeights.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None';

    return {
      'name': rankingName,
      'position': position,
      'totalAttributes': attributes.length,
      'totalWeight': totalWeight,
      'primaryFocus': primaryCategory,
      'attributes': attributes.map((attr) => {
        'name': attr.displayName,
        'category': attr.category,
        'weight': attr.weight,
        'weightPercentage': (attr.weight * 100).toStringAsFixed(1),
      }).toList(),
      'categoryBreakdown': categoryWeights.map((key, value) => 
        MapEntry(key, (value * 100).toStringAsFixed(1))
      ),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static String _generateCsvContent(
    List<CustomRankingResult> results,
    List<EnhancedRankingAttribute> attributes,
    String rankingName,
  ) {
    final buffer = StringBuffer();
    
    // Header comment
    buffer.writeln('# $rankingName - Custom Fantasy Rankings');
    buffer.writeln('# Generated on ${DateTime.now().toString()}');
    buffer.writeln('# Attributes: ${attributes.map((a) => a.displayName).join(', ')}');
    buffer.writeln('#');
    
    // CSV Headers
    final headers = [
      'Rank',
      'Player Name',
      'Position',
      'Team',
      'Total Score',
      ...attributes.map((attr) => attr.displayName),
    ];
    buffer.writeln(headers.map(_escapeCsvField).join(','));
    
    // Data rows
    for (final result in results) {
      final row = [
        result.rank.toString(),
        result.playerName,
        result.position,
        result.team,
        result.formattedScore,
        ...attributes.map((attr) => 
          (result.attributeScores[attr.id] ?? 0.0).toStringAsFixed(3)
        ),
      ];
      buffer.writeln(row.map(_escapeCsvField).join(','));
    }
    
    return buffer.toString();
  }

  static String _generateJsonContent(
    List<CustomRankingResult> results,
    List<EnhancedRankingAttribute> attributes,
    String rankingName,
  ) {
    final exportData = {
      'metadata': {
        'name': rankingName,
        'generatedAt': DateTime.now().toIso8601String(),
        'totalPlayers': results.length,
        'attributes': attributes.map((attr) => {
          'id': attr.id,
          'name': attr.displayName,
          'category': attr.category,
          'weight': attr.weight,
        }).toList(),
      },
      'rankings': results.map((result) => {
        'rank': result.rank,
        'playerId': result.playerId,
        'playerName': result.playerName,
        'position': result.position,
        'team': result.team,
        'totalScore': result.totalScore,
        'attributeScores': result.attributeScores,
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  static Future<String> _generateHtmlReport(
    List<CustomRankingResult> results,
    List<EnhancedRankingAttribute> attributes,
    String rankingName,
    String position,
    RankingAnalysis? analysis,
  ) async {
    final topPlayers = results.take(20).toList();
    final totalWeight = attributes.fold(0.0, (sum, attr) => sum + attr.weight);
    
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$rankingName - Fantasy Rankings Report</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 3px solid #1a365d;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #1a365d;
            margin: 0;
            font-size: 2.5em;
        }
        .header p {
            color: #666;
            margin: 10px 0 0 0;
            font-size: 1.1em;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            text-align: center;
            border-left: 4px solid #d4af37;
        }
        .summary-card h3 {
            margin: 0 0 5px 0;
            color: #1a365d;
        }
        .summary-card p {
            margin: 0;
            font-size: 1.2em;
            font-weight: bold;
            color: #d4af37;
        }
        .section {
            margin-bottom: 40px;
        }
        .section h2 {
            color: #1a365d;
            border-bottom: 2px solid #d4af37;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .attributes-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        .attribute-card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            border-left: 4px solid #28a745;
        }
        .attribute-card h4 {
            margin: 0 0 5px 0;
            color: #1a365d;
        }
        .attribute-card p {
            margin: 0;
            color: #666;
            font-size: 0.9em;
        }
        .weight-bar {
            background: #e9ecef;
            height: 8px;
            border-radius: 4px;
            margin-top: 8px;
            overflow: hidden;
        }
        .weight-fill {
            background: #28a745;
            height: 100%;
            transition: width 0.3s ease;
        }
        .rankings-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .rankings-table th,
        .rankings-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .rankings-table th {
            background-color: #1a365d;
            color: white;
            font-weight: bold;
        }
        .rankings-table tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        .rankings-table tr:hover {
            background-color: #e8f4fd;
        }
        .rank-badge {
            display: inline-block;
            width: 30px;
            height: 30px;
            border-radius: 50%;
            color: white;
            text-align: center;
            line-height: 30px;
            font-weight: bold;
            font-size: 14px;
        }
        .rank-elite { background-color: #28a745; }
        .rank-high { background-color: #d4af37; }
        .rank-mid { background-color: #fd7e14; }
        .rank-low { background-color: #6c757d; }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
            font-size: 0.9em;
        }
        @media print {
            body { background: white; }
            .container { box-shadow: none; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$rankingName</h1>
            <p>Custom $position Fantasy Football Rankings</p>
            <p>Generated on ${DateTime.now().toString().split('.')[0]}</p>
        </div>

        <div class="summary">
            <div class="summary-card">
                <h3>Total Players</h3>
                <p>${results.length}</p>
            </div>
            <div class="summary-card">
                <h3>Attributes Used</h3>
                <p>${attributes.length}</p>
            </div>
            <div class="summary-card">
                <h3>Total Weight</h3>
                <p>${(totalWeight * 100).toStringAsFixed(0)}%</p>
            </div>
            ${analysis != null ? '''
            <div class="summary-card">
                <h3>Avg Score</h3>
                <p>${analysis.averageScore.toStringAsFixed(2)}</p>
            </div>
            ''' : ''}
        </div>

        <div class="section">
            <h2>Ranking Methodology</h2>
            <div class="attributes-grid">
                ${attributes.map((attr) => '''
                <div class="attribute-card">
                    <h4>${attr.displayName}</h4>
                    <p>${attr.category} • ${(attr.weight * 100).toStringAsFixed(1)}% weight</p>
                    <div class="weight-bar">
                        <div class="weight-fill" style="width: ${(attr.weight * 100).toStringAsFixed(1)}%"></div>
                    </div>
                </div>
                ''').join()}
            </div>
        </div>

        <div class="section">
            <h2>Top 20 Rankings</h2>
            <table class="rankings-table">
                <thead>
                    <tr>
                        <th>Rank</th>
                        <th>Player</th>
                        <th>Team</th>
                        <th>Score</th>
                        ${attributes.take(3).map((attr) => '<th>${attr.displayName}</th>').join()}
                    </tr>
                </thead>
                <tbody>
                    ${topPlayers.map((result) => '''
                    <tr>
                        <td>
                            <span class="rank-badge ${_getRankClass(result.rank)}">
                                ${result.rank}
                            </span>
                        </td>
                        <td><strong>${result.playerName}</strong></td>
                        <td>${result.team}</td>
                        <td><strong>${result.formattedScore}</strong></td>
                        ${attributes.take(3).map((attr) => 
                          '<td>${(result.attributeScores[attr.id] ?? 0.0).toStringAsFixed(2)}</td>'
                        ).join()}
                    </tr>
                    ''').join()}
                </tbody>
            </table>
        </div>

        <div class="footer">
            <p>Report generated by Custom Fantasy Rankings Tool</p>
            <p>Methodology: ${attributes.map((a) => '${a.displayName} (${(a.weight * 100).toStringAsFixed(0)}%)').join(' + ')}</p>
        </div>
    </div>
</body>
</html>
''';
  }

  static String _getRankClass(int rank) {
    if (rank <= 5) return 'rank-elite';
    if (rank <= 12) return 'rank-high';
    if (rank <= 24) return 'rank-mid';
    return 'rank-low';
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  static void _downloadWebFile(String content, String fileName, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}