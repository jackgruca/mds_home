// lib/models/nfl_player.dart
class NFLPlayer {
  // Universal Identifiers
  final String? gsisId;           // Primary NFL identifier
  final String? playerId;         // NFLverse player ID  
  final String? esbId;           // ESPN identifier
  final String? pfrId;           // Pro Football Reference ID
  
  // Basic Information
  final String playerName;
  final String? position;
  final String? team;
  final int? jerseyNumber;
  final String? status;           // Active, IR, etc.
  
  // Physical Attributes
  final double? height;
  final double? weight;
  final DateTime? birthDate;
  final int? age;
  final String? college;
  final String? highSchool;
  
  // Career Context
  final int? entryYear;
  final int? rookieYear;
  final String? draftClub;
  final int? draftNumber;
  final int? draftRound;
  final int? yearsExp;
  
  // Current Season Stats (dynamic based on position)
  final Map<String, dynamic>? currentSeasonStats;
  
  // Historical Season Stats (by year)
  final Map<int, Map<String, dynamic>>? historicalStats;
  
  // Headshot URL
  final String? headshotUrl;

  NFLPlayer({
    this.gsisId,
    this.playerId,
    this.esbId,
    this.pfrId,
    required this.playerName,
    this.position,
    this.team,
    this.jerseyNumber,
    this.status,
    this.height,
    this.weight,
    this.birthDate,
    this.age,
    this.college,
    this.highSchool,
    this.entryYear,
    this.rookieYear,
    this.draftClub,
    this.draftNumber,
    this.draftRound,
    this.yearsExp,
    this.currentSeasonStats,
    this.historicalStats,
    this.headshotUrl,
  });

  // Create from API response
  factory NFLPlayer.fromJson(Map<String, dynamic> json) {
    return NFLPlayer(
      gsisId: json['gsis_id'],
      playerId: json['player_id'],
      esbId: json['esb_id'],
      pfrId: json['pfr_id'],
      playerName: json['player_name'] ?? json['name'] ?? 'Unknown Player',
      position: json['position'],
      team: json['team'],
      jerseyNumber: json['jersey_number'],
      status: json['status'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
      age: json['age'],
      college: json['college'],
      highSchool: json['high_school'],
      entryYear: json['entry_year'],
      rookieYear: json['rookie_year'],
      draftClub: json['draft_club'],
      draftNumber: json['draft_number'],
      draftRound: json['draft_round'],
      yearsExp: json['years_exp'],
      currentSeasonStats: json['current_season_stats'],
      historicalStats: json['historical_stats'] != null 
          ? Map<int, Map<String, dynamic>>.from(
              (json['historical_stats'] as Map).map(
                (key, value) => MapEntry(
                  int.parse(key.toString()), 
                  Map<String, dynamic>.from(value)
                )
              )
            )
          : null,
      headshotUrl: json['headshot_url'],
    );
  }

  // Helper methods
  String get displayName => playerName;
  
  String get positionTeam {
    final pos = position ?? '';
    final tm = team ?? '';
    if (pos.isNotEmpty && tm.isNotEmpty) {
      return '$pos, $tm';
    } else if (pos.isNotEmpty) {
      return pos;
    } else if (tm.isNotEmpty) {
      return tm;
    }
    return '';
  }

  String get formattedHeight {
    if (height == null) return 'N/A';
    final totalInches = height!.round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }

  String get formattedWeight {
    if (weight == null) return 'N/A';
    return '${weight!.round()} lbs';
  }

  String get draftInfo {
    if (draftRound != null && draftNumber != null && draftClub != null) {
      return 'Rd $draftRound, Pick $draftNumber ($draftClub)';
    } else if (draftRound != null && draftNumber != null) {
      return 'Rd $draftRound, Pick $draftNumber';
    } else if (entryYear != null) {
      return 'Entered $entryYear';
    }
    return 'Draft info unavailable';
  }

  String get experienceText {
    if (yearsExp == null) return '';
    if (yearsExp == 0) return 'Rookie';
    if (yearsExp == 1) return '1 year exp';
    return '$yearsExp years exp';
  }

  // Primary identifier for navigation
  String get primaryId {
    return gsisId ?? playerId ?? esbId ?? pfrId ?? playerName;
  }

  // Check if we have sufficient data for a modal
  bool get hasModalData {
    return position != null || team != null || college != null || currentSeasonStats != null;
  }
}