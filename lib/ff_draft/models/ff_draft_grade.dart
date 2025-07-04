import 'ff_player.dart';
import 'ff_team.dart';

enum DraftGrade { A_PLUS, A, A_MINUS, B_PLUS, B, B_MINUS, C_PLUS, C, C_MINUS, D_PLUS, D, F }

enum PickType { STEAL, VALUE, SOLID, REACH, MAJOR_REACH }

/// Represents the grade and analysis for a single draft pick
class FFPickGrade {
  final FFPlayer player;
  final FFTeam team;
  final int pickNumber;
  final int round;
  final DraftGrade grade;
  final PickType pickType;
  final double value; // -10 to +10 scale
  final String reasoning;
  final List<String> positives;
  final List<String> negatives;
  final double adpDifference; // How many picks ahead/behind ADP
  final bool fillsNeed;
  final bool isReach;
  final double opportunityCost;

  const FFPickGrade({
    required this.player,
    required this.team,
    required this.pickNumber,
    required this.round,
    required this.grade,
    required this.pickType,
    required this.value,
    required this.reasoning,
    required this.positives,
    required this.negatives,
    required this.adpDifference,
    required this.fillsNeed,
    required this.isReach,
    required this.opportunityCost,
  });

  String get gradeDisplay {
    switch (grade) {
      case DraftGrade.A_PLUS: return 'A+';
      case DraftGrade.A: return 'A';
      case DraftGrade.A_MINUS: return 'A-';
      case DraftGrade.B_PLUS: return 'B+';
      case DraftGrade.B: return 'B';
      case DraftGrade.B_MINUS: return 'B-';
      case DraftGrade.C_PLUS: return 'C+';
      case DraftGrade.C: return 'C';
      case DraftGrade.C_MINUS: return 'C-';
      case DraftGrade.D_PLUS: return 'D+';
      case DraftGrade.D: return 'D';
      case DraftGrade.F: return 'F';
    }
  }

  String get pickTypeDisplay {
    switch (pickType) {
      case PickType.STEAL: return 'STEAL';
      case PickType.VALUE: return 'VALUE';
      case PickType.SOLID: return 'SOLID';
      case PickType.REACH: return 'REACH';
      case PickType.MAJOR_REACH: return 'MAJOR REACH';
    }
  }
}

/// Represents the overall grade and analysis for a team's draft
class FFTeamDraftGrade {
  final FFTeam team;
  final DraftGrade overallGrade;
  final double averagePickValue;
  final List<FFPickGrade> pickGrades;
  final Map<String, int> positionCounts;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final double rosterBalance; // 0-100 scale
  final double valueExtracted; // Total value above expectation
  final int stealsCount;
  final int reachesCount;

  const FFTeamDraftGrade({
    required this.team,
    required this.overallGrade,
    required this.averagePickValue,
    required this.pickGrades,
    required this.positionCounts,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.rosterBalance,
    required this.valueExtracted,
    required this.stealsCount,
    required this.reachesCount,
  });

  String get overallGradeDisplay {
    switch (overallGrade) {
      case DraftGrade.A_PLUS: return 'A+';
      case DraftGrade.A: return 'A';
      case DraftGrade.A_MINUS: return 'A-';
      case DraftGrade.B_PLUS: return 'B+';
      case DraftGrade.B: return 'B';
      case DraftGrade.B_MINUS: return 'B-';
      case DraftGrade.C_PLUS: return 'C+';
      case DraftGrade.C: return 'C';
      case DraftGrade.C_MINUS: return 'C-';
      case DraftGrade.D_PLUS: return 'D+';
      case DraftGrade.D: return 'D';
      case DraftGrade.F: return 'F';
    }
  }
}

/// Comprehensive draft analysis including league-wide insights
class FFDraftAnalysis {
  final List<FFTeamDraftGrade> teamGrades;
  final Map<String, List<FFPlayer>> bestByPosition;
  final Map<String, List<FFPlayer>> worstByPosition;
  final List<FFPickGrade> topSteals;
  final List<FFPickGrade> biggestReaches;
  final Map<String, double> positionValueTrends;
  final List<String> draftTrends;
  final double averageDraftValue;

  const FFDraftAnalysis({
    required this.teamGrades,
    required this.bestByPosition,
    required this.worstByPosition,
    required this.topSteals,
    required this.biggestReaches,
    required this.positionValueTrends,
    required this.draftTrends,
    required this.averageDraftValue,
  });

  FFTeamDraftGrade? getTeamGrade(String teamId) {
    try {
      return teamGrades.firstWhere((grade) => grade.team.id == teamId);
    } catch (e) {
      return null;
    }
  }
}

/// Real-time draft insights and alerts
class FFDraftInsight {
  final String title;
  final String message;
  final InsightType type;
  final InsightPriority priority;
  final FFPlayer? relatedPlayer;
  final FFTeam? relatedTeam;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const FFDraftInsight({
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    this.relatedPlayer,
    this.relatedTeam,
    required this.timestamp,
    this.metadata = const {},
  });
}

enum InsightType {
  STEAL,
  REACH,
  POSITIONAL_RUN,
  VALUE_OPPORTUNITY,
  ROSTER_IMBALANCE,
  LATE_ROUND_VALUE,
  POSITION_SCARCITY
}

enum InsightPriority { HIGH, MEDIUM, LOW }

/// Utility functions for draft grading
class DraftGradeUtils {
  /// Converts numeric grade to letter grade
  static DraftGrade valueToGrade(double value) {
    if (value >= 8.0) return DraftGrade.A_PLUS;
    if (value >= 7.0) return DraftGrade.A;
    if (value >= 6.0) return DraftGrade.A_MINUS;
    if (value >= 5.0) return DraftGrade.B_PLUS;
    if (value >= 4.0) return DraftGrade.B;
    if (value >= 3.0) return DraftGrade.B_MINUS;
    if (value >= 2.0) return DraftGrade.C_PLUS;
    if (value >= 1.0) return DraftGrade.C;
    if (value >= 0.0) return DraftGrade.C_MINUS;
    if (value >= -2.0) return DraftGrade.D_PLUS;
    if (value >= -4.0) return DraftGrade.D;
    return DraftGrade.F;
  }

  /// Determines pick type based on ADP difference and context
  static PickType determinePickType(double adpDifference, bool fillsNeed, double value) {
    // Steal: Drafted significantly later than ADP with high value
    if (adpDifference <= -15 && value >= 3.0) return PickType.STEAL;
    
    // Value: Good value relative to draft position
    if ((adpDifference <= -8 && value >= 1.0) || (value >= 4.0)) return PickType.VALUE;
    
    // Major Reach: Drafted way too early
    if (adpDifference >= 25 || value <= -3.0) return PickType.MAJOR_REACH;
    
    // Reach: Drafted earlier than expected
    if (adpDifference >= 12 || value <= -1.0) return PickType.REACH;
    
    // Otherwise solid pick
    return PickType.SOLID;
  }

  /// Calculates roster balance score (0-100)
  static double calculateRosterBalance(FFTeam team, int roundsCompleted) {
    final counts = team.getPositionCounts();
    double balance = 100.0;
    
    // Penalize missing starters
    if (counts['QB']! == 0 && roundsCompleted >= 6) balance -= 20;
    if (counts['RB']! < 2 && roundsCompleted >= 6) balance -= 15 * (2 - counts['RB']!);
    if (counts['WR']! < 2 && roundsCompleted >= 6) balance -= 15 * (2 - counts['WR']!);
    if (counts['TE']! == 0 && roundsCompleted >= 8) balance -= 15;
    
    // Penalize too many of one position early
    if (roundsCompleted <= 8) {
      if (counts['QB']! > 1) balance -= 10;
      if (counts['TE']! > 2) balance -= 10;
      if (counts['K']! > 0) balance -= 15; // Kicker too early
      if (counts['DEF']! > 0 && roundsCompleted <= 10) balance -= 10;
    }
    
    // Reward balanced skill position distribution
    final skillPositions = counts['RB']! + counts['WR']! + counts['TE']!;
    if (skillPositions >= 6 && roundsCompleted >= 8) balance += 5;
    
    return balance.clamp(0.0, 100.0);
  }
}