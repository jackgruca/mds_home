import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../services/robust_csv_parser.dart';

class PlayerGameStatsScreen extends StatefulWidget {
  const PlayerGameStatsScreen({super.key});

  @override
  State<PlayerGameStatsScreen> createState() => _PlayerGameStatsScreenState();
}

class _PlayerGameStatsScreenState extends State<PlayerGameStatsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _gameData = [];
  
  // Position filter
  String _selectedPosition = 'QB'; // Default to QB
  final List<String> _positions = ['QB', 'RB', 'WR', 'TE'];
  
  // Sorting state
  String _sortColumn = 'fantasy_points_ppr';
  bool _sortAscending = false;
  
  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 50;
  
  late TabController _tabController;

  // Get position-specific data sections
  List<Map<String, dynamic>> get _dataSections {
    switch (_selectedPosition) {
      case 'QB':
        return _getQBSections();
      case 'RB':
        return _getRBSections();
      case 'WR':
        return _getWRSections();
      case 'TE':
        return _getTESections();
      default:
        return _getQBSections();
    }
  }

  List<Map<String, dynamic>> _getQBSections() {
    return [
      {
        'id': 'core_passing',
        'title': '🎯 Core Passing Stats',
        'subtitle': 'Essential passing statistics',
        'color': Colors.blue,
        'icon': Icons.sports_football,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'pass_attempts', 'label': 'Att', 'type': 'int', 'width': 60.0},
          {'key': 'completions', 'label': 'Comp', 'type': 'int', 'width': 60.0},
          {'key': 'passing_yards', 'label': 'Pass Yds', 'type': 'int', 'width': 80.0},
          {'key': 'passing_tds', 'label': 'Pass TD', 'type': 'int', 'width': 70.0},
          {'key': 'interceptions', 'label': 'INT', 'type': 'int', 'width': 50.0},
          {'key': 'completion_pct', 'label': 'Comp%', 'type': 'percentage', 'width': 70.0},
          {'key': 'yards_per_attempt', 'label': 'YPA', 'type': 'decimal', 'width': 60.0},
          {'key': 'passer_rating', 'label': 'Rating', 'type': 'decimal', 'width': 70.0},
        ]
      },
      {
        'id': 'advanced_passing',
        'title': '📊 Advanced Passing Metrics',
        'subtitle': 'EPA and efficiency metrics',
        'color': Colors.purple,
        'icon': Icons.analytics,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'pass_epa', 'label': 'Pass EPA', 'type': 'decimal', 'width': 80.0},
          {'key': 'pass_epa_per_att', 'label': 'EPA/Att', 'type': 'decimal', 'width': 80.0},
          {'key': 'cpoe', 'label': 'CPOE', 'type': 'decimal', 'width': 70.0},
          {'key': 'cpoe_ngs', 'label': 'CPOE NGS', 'type': 'decimal', 'width': 80.0},
          {'key': 'success_rate', 'label': 'Success%', 'type': 'percentage', 'width': 80.0},
          {'key': 'td_pct', 'label': 'TD%', 'type': 'percentage', 'width': 60.0},
          {'key': 'int_pct', 'label': 'INT%', 'type': 'percentage', 'width': 60.0},
        ]
      },
      {
        'id': 'pressure_timing',
        'title': '⚡ Pressure & Timing',
        'subtitle': 'Pressure handling and timing metrics',
        'color': Colors.orange,
        'icon': Icons.speed,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'sacks', 'label': 'Sacks', 'type': 'int', 'width': 60.0},
          {'key': 'sack_yards', 'label': 'Sack Yds', 'type': 'int', 'width': 80.0},
          {'key': 'pressures', 'label': 'Pressures', 'type': 'int', 'width': 80.0},
          {'key': 'pressure_rate', 'label': 'Pressure%', 'type': 'percentage', 'width': 80.0},
          {'key': 'time_to_throw', 'label': 'Time/Throw', 'type': 'decimal', 'width': 90.0},
          {'key': 'aggressiveness', 'label': 'Aggr%', 'type': 'percentage', 'width': 70.0},
          {'key': 'avg_air_distance', 'label': 'Avg Air Dist', 'type': 'decimal', 'width': 100.0},
          {'key': 'intended_air_yards', 'label': 'Int Air Yds', 'type': 'decimal', 'width': 100.0},
        ]
      },
      {
        'id': 'situational_passing',
        'title': '🎲 Situational Passing',
        'subtitle': 'Third down and red zone passing',
        'color': Colors.green,
        'icon': Icons.location_on,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'third_down_attempts', 'label': '3D Att', 'type': 'int', 'width': 70.0},
          {'key': 'third_down_completions', 'label': '3D Comp', 'type': 'int', 'width': 80.0},
          {'key': 'third_down_pct', 'label': '3D%', 'type': 'percentage', 'width': 60.0},
          {'key': 'red_zone_attempts', 'label': 'RZ Att', 'type': 'int', 'width': 70.0},
          {'key': 'red_zone_td_pct', 'label': 'RZ TD%', 'type': 'percentage', 'width': 80.0},
        ]
      },
      {
        'id': 'core_rushing',
        'title': '🏃 Core Rushing Stats',
        'subtitle': 'QB rushing and fantasy',
        'color': Colors.red,
        'icon': Icons.directions_run,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'rush_attempts', 'label': 'Rush Att', 'type': 'int', 'width': 80.0},
          {'key': 'rushing_yards', 'label': 'Rush Yds', 'type': 'int', 'width': 80.0},
          {'key': 'rushing_tds', 'label': 'Rush TD', 'type': 'int', 'width': 70.0},
          {'key': 'yards_per_carry', 'label': 'YPC', 'type': 'decimal', 'width': 60.0},
          {'key': 'rush_epa', 'label': 'Rush EPA', 'type': 'decimal', 'width': 80.0},
          {'key': 'rush_epa_per_att', 'label': 'Rush EPA/Att', 'type': 'decimal', 'width': 100.0},
          {'key': 'fumbles', 'label': 'Fumbles', 'type': 'int', 'width': 70.0},
          {'key': 'fumbles_lost', 'label': 'Fum Lost', 'type': 'int', 'width': 80.0},
          {'key': 'fantasy_points_std', 'label': 'Std Pts', 'type': 'decimal', 'width': 80.0},
          {'key': 'fantasy_points_ppr', 'label': 'PPR Pts', 'type': 'decimal', 'width': 80.0},
          {'key': 'fantasy_points_per_game', 'label': 'FP/Game', 'type': 'decimal', 'width': 90.0},
        ]
      },
    ];
  }

  List<Map<String, dynamic>> _getRBSections() {
    return [
      {
        'id': 'core_rushing',
        'title': '🏃 Core Rushing Stats',
        'subtitle': 'Essential rushing statistics',
        'color': Colors.green,
        'icon': Icons.directions_run,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'rush_attempts', 'label': 'Rush Att', 'type': 'int', 'width': 80.0},
          {'key': 'rushing_yards', 'label': 'Rush Yds', 'type': 'int', 'width': 80.0},
          {'key': 'rushing_tds', 'label': 'Rush TD', 'type': 'int', 'width': 70.0},
          {'key': 'yards_per_carry', 'label': 'YPC', 'type': 'decimal', 'width': 60.0},
          {'key': 'rush_share', 'label': 'Rush Share', 'type': 'percentage', 'width': 90.0},
          {'key': 'fumbles', 'label': 'Fumbles', 'type': 'int', 'width': 70.0},
          {'key': 'fumbles_lost', 'label': 'Fum Lost', 'type': 'int', 'width': 80.0},
          {'key': 'fumble_rate', 'label': 'Fum Rate', 'type': 'percentage', 'width': 80.0},
          {'key': 'fantasy_points_std', 'label': 'Std Pts', 'type': 'decimal', 'width': 80.0},
          {'key': 'fantasy_points_ppr', 'label': 'PPR Pts', 'type': 'decimal', 'width': 80.0},
          {'key': 'fantasy_points_per_game', 'label': 'FP/Game', 'type': 'decimal', 'width': 90.0},
        ]
      },
      {
        'id': 'advanced_rushing',
        'title': '⚡ Advanced Rushing Metrics',
        'subtitle': 'EPA and efficiency metrics',
        'color': Colors.orange,
        'icon': Icons.speed,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'rush_epa', 'label': 'Rush EPA', 'type': 'decimal', 'width': 80.0},
          {'key': 'rush_epa_per_att', 'label': 'Rush EPA/Att', 'type': 'decimal', 'width': 100.0},
          {'key': 'rush_efficiency', 'label': 'Rush Eff', 'type': 'decimal', 'width': 80.0},
          {'key': 'ryoe_per_att', 'label': 'RYOE/Att', 'type': 'decimal', 'width': 90.0},
          {'key': 'explosive_runs', 'label': 'Exp Runs', 'type': 'int', 'width': 80.0},
          {'key': 'td_rate', 'label': 'TD Rate', 'type': 'percentage', 'width': 80.0},
        ]
      },
      {
        'id': 'situational_rushing',
        'title': '🎲 Situational Rushing',
        'subtitle': 'Down and distance metrics',
        'color': Colors.blue,
        'icon': Icons.location_on,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'first_down_rushes', 'label': '1D Rush', 'type': 'int', 'width': 80.0},
          {'key': 'third_down_rushes', 'label': '3D Rush', 'type': 'int', 'width': 80.0},
          {'key': 'third_down_conversion_rate', 'label': '3D Conv%', 'type': 'percentage', 'width': 90.0},
          {'key': 'red_zone_rushes', 'label': 'RZ Rush', 'type': 'int', 'width': 80.0},
          {'key': 'red_zone_td_rate', 'label': 'RZ TD Rate', 'type': 'percentage', 'width': 100.0},
          {'key': 'goal_line_rushes', 'label': 'GL Rush', 'type': 'int', 'width': 80.0},
          {'key': 'goal_line_tds', 'label': 'GL TD', 'type': 'int', 'width': 70.0},
          {'key': 'goal_line_td_rate', 'label': 'GL TD Rate', 'type': 'percentage', 'width': 100.0},
        ]
      },
      {
        'id': 'receiving',
        'title': '🎯 Receiving (Pass-catching backs)',
        'subtitle': 'Receiving metrics for RBs',
        'color': Colors.purple,
        'icon': Icons.sports_football,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'targets', 'label': 'Targets', 'type': 'int', 'width': 70.0},
          {'key': 'receptions', 'label': 'Rec', 'type': 'int', 'width': 50.0},
          {'key': 'receiving_yards', 'label': 'Rec Yds', 'type': 'int', 'width': 80.0},
          {'key': 'receiving_tds', 'label': 'Rec TD', 'type': 'int', 'width': 70.0},
          {'key': 'catch_rate', 'label': 'Catch Rate', 'type': 'percentage', 'width': 80.0},
          {'key': 'target_share', 'label': 'Tgt Share', 'type': 'percentage', 'width': 90.0},
          {'key': 'air_yards', 'label': 'Air Yds', 'type': 'int', 'width': 80.0},
          {'key': 'yac', 'label': 'YAC', 'type': 'int', 'width': 60.0},
          {'key': 'yac_above_expected', 'label': 'YAC+', 'type': 'decimal', 'width': 70.0},
          {'key': 'drops', 'label': 'Drops', 'type': 'int', 'width': 60.0},
          {'key': 'drop_rate', 'label': 'Drop%', 'type': 'percentage', 'width': 70.0},
        ]
      },
    ];
  }

  List<Map<String, dynamic>> _getWRSections() {
    return [
      {
        'id': 'core_receiving',
        'title': '🎯 Core Receiving Stats',
        'subtitle': 'Essential receiving statistics',
        'color': Colors.orange,
        'icon': Icons.sports_football,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'targets', 'label': 'Targets', 'type': 'int', 'width': 70.0},
          {'key': 'receptions', 'label': 'Rec', 'type': 'int', 'width': 50.0},
          {'key': 'receiving_yards', 'label': 'Rec Yds', 'type': 'int', 'width': 80.0},
          {'key': 'receiving_tds', 'label': 'Rec TD', 'type': 'int', 'width': 70.0},
          {'key': 'catch_rate', 'label': 'Catch Rate', 'type': 'percentage', 'width': 80.0},
          {'key': 'target_share', 'label': 'Tgt Share', 'type': 'percentage', 'width': 90.0},
          {'key': 'fantasy_points_std', 'label': 'Std Pts', 'type': 'decimal', 'width': 80.0},
          {'key': 'fantasy_points_ppr', 'label': 'PPR Pts', 'type': 'decimal', 'width': 80.0},
          {'key': 'fantasy_points_per_game', 'label': 'FP/Game', 'type': 'decimal', 'width': 90.0},
        ]
      },
      {
        'id': 'advanced_receiving',
        'title': '📊 Advanced Receiving Metrics',
        'subtitle': 'EPA and efficiency metrics',
        'color': Colors.blue,
        'icon': Icons.analytics,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'air_yards', 'label': 'Air Yds', 'type': 'int', 'width': 80.0},
          {'key': 'yac', 'label': 'YAC', 'type': 'int', 'width': 60.0},
          {'key': 'racr', 'label': 'RACR', 'type': 'decimal', 'width': 70.0},
          {'key': 'wopr', 'label': 'WOPR', 'type': 'decimal', 'width': 70.0},
          {'key': 'rec_epa', 'label': 'Rec EPA', 'type': 'decimal', 'width': 80.0},
          {'key': 'rec_epa_per_target', 'label': 'Rec EPA/Tgt', 'type': 'decimal', 'width': 100.0},
          {'key': 'yards_per_target', 'label': 'YPT', 'type': 'decimal', 'width': 60.0},
          {'key': 'yards_per_reception', 'label': 'YPR', 'type': 'decimal', 'width': 60.0},
          {'key': 'air_yards_per_target', 'label': 'Air/Tgt', 'type': 'decimal', 'width': 80.0},
          {'key': 'yac_per_reception', 'label': 'YAC/Rec', 'type': 'decimal', 'width': 80.0},
          {'key': 'yac_above_expected', 'label': 'YAC+', 'type': 'decimal', 'width': 70.0},
          {'key': 'avg_separation', 'label': 'Avg Sep', 'type': 'decimal', 'width': 80.0},
          {'key': 'avg_cushion', 'label': 'Avg Cushion', 'type': 'decimal', 'width': 100.0},
          {'key': 'completed_air_yards', 'label': 'Comp Air Yds', 'type': 'decimal', 'width': 110.0},
          {'key': 'explosive_catches', 'label': 'Exp Catch', 'type': 'int', 'width': 80.0},
          {'key': 'explosive_rate', 'label': 'Exp Rate', 'type': 'percentage', 'width': 80.0},
          {'key': 'drops', 'label': 'Drops', 'type': 'int', 'width': 60.0},
          {'key': 'drop_rate', 'label': 'Drop%', 'type': 'percentage', 'width': 70.0},
        ]
      },
      {
        'id': 'situational_receiving',
        'title': '🎲 Situational Receiving',
        'subtitle': 'Red zone and third down receiving',
        'color': Colors.green,
        'icon': Icons.location_on,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'red_zone_targets', 'label': 'RZ Tgt', 'type': 'int', 'width': 70.0},
          {'key': 'red_zone_tds', 'label': 'RZ TD', 'type': 'int', 'width': 70.0},
          {'key': 'third_down_targets', 'label': '3D Tgt', 'type': 'int', 'width': 70.0},
          {'key': 'third_down_conversions', 'label': '3D Conv', 'type': 'int', 'width': 80.0},
          {'key': 'first_down_targets', 'label': '1D Tgt', 'type': 'int', 'width': 70.0},
        ]
      },
    ];
  }

  List<Map<String, dynamic>> _getTESections() {
    return [
      {
        'id': 'core_receiving',
        'title': '🎯 Core Receiving Stats',
        'subtitle': 'Essential receiving statistics',
        'color': Colors.purple,
        'icon': Icons.sports_handball,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'targets', 'label': 'Targets', 'type': 'int', 'width': 70.0},
          {'key': 'receptions', 'label': 'Rec', 'type': 'int', 'width': 50.0},
          {'key': 'receiving_yards', 'label': 'Rec Yds', 'type': 'int', 'width': 80.0},
          {'key': 'receiving_tds', 'label': 'Rec TD', 'type': 'int', 'width': 70.0},
          {'key': 'catch_rate', 'label': 'Catch Rate', 'type': 'percentage', 'width': 80.0},
          {'key': 'target_share', 'label': 'Tgt Share', 'type': 'percentage', 'width': 90.0},
          {'key': 'fantasy_points_std', 'label': 'Std Pts', 'type': 'decimal', 'width': 80.0},
          {'key': 'fantasy_points_ppr', 'label': 'PPR Pts', 'type': 'decimal', 'width': 80.0},
          {'key': 'fantasy_points_per_game', 'label': 'FP/Game', 'type': 'decimal', 'width': 90.0},
        ]
      },
      {
        'id': 'advanced_receiving',
        'title': '📊 Advanced Receiving Metrics',
        'subtitle': 'EPA and efficiency metrics',
        'color': Colors.blue,
        'icon': Icons.analytics,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'air_yards', 'label': 'Air Yds', 'type': 'int', 'width': 80.0},
          {'key': 'yac', 'label': 'YAC', 'type': 'int', 'width': 60.0},
          {'key': 'racr', 'label': 'RACR', 'type': 'decimal', 'width': 70.0},
          {'key': 'wopr', 'label': 'WOPR', 'type': 'decimal', 'width': 70.0},
          {'key': 'rec_epa', 'label': 'Rec EPA', 'type': 'decimal', 'width': 80.0},
          {'key': 'rec_epa_per_target', 'label': 'Rec EPA/Tgt', 'type': 'decimal', 'width': 100.0},
          {'key': 'yards_per_target', 'label': 'YPT', 'type': 'decimal', 'width': 60.0},
          {'key': 'yards_per_reception', 'label': 'YPR', 'type': 'decimal', 'width': 60.0},
          {'key': 'air_yards_per_target', 'label': 'Air/Tgt', 'type': 'decimal', 'width': 80.0},
          {'key': 'yac_per_reception', 'label': 'YAC/Rec', 'type': 'decimal', 'width': 80.0},
          {'key': 'yac_above_expected', 'label': 'YAC+', 'type': 'decimal', 'width': 70.0},
          {'key': 'avg_separation', 'label': 'Avg Sep', 'type': 'decimal', 'width': 80.0},
          {'key': 'avg_cushion', 'label': 'Avg Cushion', 'type': 'decimal', 'width': 100.0},
          {'key': 'completed_air_yards', 'label': 'Comp Air Yds', 'type': 'decimal', 'width': 110.0},
          {'key': 'explosive_catches', 'label': 'Exp Catch', 'type': 'int', 'width': 80.0},
          {'key': 'explosive_rate', 'label': 'Exp Rate', 'type': 'percentage', 'width': 80.0},
          {'key': 'drops', 'label': 'Drops', 'type': 'int', 'width': 60.0},
          {'key': 'drop_rate', 'label': 'Drop%', 'type': 'percentage', 'width': 70.0},
        ]
      },
      {
        'id': 'situational_receiving',
        'title': '🎲 Situational Receiving',
        'subtitle': 'Red zone and third down receiving',
        'color': Colors.green,
        'icon': Icons.location_on,
        'fields': [
          {'key': 'player_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
          {'key': 'week', 'label': 'Week', 'type': 'int', 'width': 50.0},
          {'key': 'season', 'label': 'Season', 'type': 'int', 'width': 60.0},
          {'key': 'team', 'label': 'Team', 'type': 'string', 'width': 60.0},
          {'key': 'red_zone_targets', 'label': 'RZ Tgt', 'type': 'int', 'width': 70.0},
          {'key': 'red_zone_tds', 'label': 'RZ TD', 'type': 'int', 'width': 70.0},
          {'key': 'third_down_targets', 'label': '3D Tgt', 'type': 'int', 'width': 70.0},
          {'key': 'third_down_conversions', 'label': '3D Conv', 'type': 'int', 'width': 80.0},
          {'key': 'first_down_targets', 'label': '1D Tgt', 'type': 'int', 'width': 70.0},
        ]
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadGameData();
  }

  void _initializeTabController() {
    _tabController = TabController(length: _dataSections.length, vsync: this);
  }

  Future<void> _loadGameData() async {
    setState(() => _isLoading = true);
    
    try {
      print('🚀 Loading $_selectedPosition game stats from CSV...');
      final startTime = DateTime.now();
      
      // Load position-specific CSV file
      String csvFile;
      switch (_selectedPosition) {
        case 'QB':
          csvFile = 'assets/data/quarterback_game_stats.csv';
          break;
        case 'RB':
          csvFile = 'assets/data/runningback_game_stats.csv';
          break;
        case 'WR':
          csvFile = 'assets/data/widereceiver_game_stats.csv';
          break;
        case 'TE':
          csvFile = 'assets/data/tightend_game_stats.csv';
          break;
        default:
          csvFile = 'assets/data/quarterback_game_stats.csv';
      }
      
      // Load data from position-specific CSV
      final allData = await RobustCsvParser.parseFromAsset(csvFile);
      
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      print('✅ Loaded ${allData.length} $_selectedPosition records in ${loadTime}ms');

      _gameData = allData;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading $_selectedPosition game data: $e');
    }
  }

  void _onPositionChanged(String newPosition) {
    setState(() {
      _selectedPosition = newPosition;
      _currentPage = 0; // Reset pagination
      // Recreate tab controller with new section count
      _tabController.dispose();
      _initializeTabController();
    });
    _loadGameData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('🎯 Player Game Analytics'),
      ),
      body: Column(
        children: [
          const TopNavBarContent(),
          
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Analytics header
                  _buildAnalyticsHeader(),
                  
                  // Tab bar for different sections
                  _buildSectionTabs(),
                  
                  // Data table content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _dataSections.map((section) => 
                        _buildDataTable(section)
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.purple.shade600,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart, size: 32, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Player Game Analytics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_gameData.length} $_selectedPosition Game Performances • Position-Specific Analytics',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Position selector
          Row(
            children: [
              // Position dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPosition,
                    dropdownColor: Colors.blue.shade700,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    items: _positions.map((position) => DropdownMenuItem(
                      value: position,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(position, style: const TextStyle(color: Colors.white)),
                      ),
                    )).toList(),
                    onChanged: (String? newPosition) {
                      if (newPosition != null) {
                        _onPositionChanged(newPosition);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Position: $_selectedPosition',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    return Container(
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: _dataSections.map((section) => Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section['icon'], size: 16),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    section['title'],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    section['subtitle'],
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDataTable(Map<String, dynamic> section) {
    final fields = section['fields'] as List<Map<String, dynamic>>;
    final sectionColor = section['color'] as Color;
    
    // Calculate pagination
    final totalItems = _gameData.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final paginatedData = _gameData.sublist(startIndex, endIndex);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pagination controls
          if (totalItems > _itemsPerPage) _buildPaginationControls(totalPages, totalItems),
          
          // Data table
          Expanded(
            child: AnimationLimiter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowColor: WidgetStateColor.resolveWith(
                        (states) => sectionColor.withOpacity(0.1),
                      ),
                      sortColumnIndex: fields.indexWhere((f) => f['key'] == _sortColumn) != -1 
                          ? fields.indexWhere((f) => f['key'] == _sortColumn) 
                          : null,
                      sortAscending: _sortAscending,
                      columns: fields.map((field) => DataColumn(
                        label: SizedBox(
                          width: field['width'],
                          child: Text(
                            field['label'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onSort: field['type'] != 'string' ? (columnIndex, ascending) {
                          _sortData(field['key'], ascending);
                        } : null,
                      )).toList(),
                      rows: paginatedData.map((game) {
                        return DataRow(
                          cells: fields.map((field) {
                            final value = game[field['key']];
                            return DataCell(
                              Container(
                                width: field['width'],
                                child: Text(
                                  _formatFieldValue(value, field['type']),
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages, int totalItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Results info
          Text(
            'Showing ${(_currentPage * _itemsPerPage) + 1}-${((_currentPage + 1) * _itemsPerPage).clamp(0, totalItems)} of $totalItems results',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          
          // Page controls
          Row(
            children: [
              // Previous button
              IconButton(
                onPressed: _currentPage > 0 ? () {
                  setState(() {
                    _currentPage--;
                  });
                } : null,
                icon: const Icon(Icons.chevron_left),
              ),
              
              // Page numbers
              ...List.generate(
                (totalPages).clamp(0, 5), // Show max 5 page numbers
                (index) {
                  // Calculate which pages to show
                  int pageStart = (_currentPage - 2).clamp(0, totalPages - 5);
                  int actualPage = pageStart + index;
                  
                  if (actualPage >= totalPages) return const SizedBox.shrink();
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _currentPage = actualPage;
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _currentPage == actualPage 
                            ? Colors.blue.shade600 
                            : Colors.grey.shade200,
                        foregroundColor: _currentPage == actualPage 
                            ? Colors.white 
                            : Colors.black87,
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text('${actualPage + 1}'),
                    ),
                  );
                },
              ),
              
              // Next button
              IconButton(
                onPressed: _currentPage < totalPages - 1 ? () {
                  setState(() {
                    _currentPage++;
                  });
                } : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sortData(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
      
      _gameData.sort((a, b) {
        final aVal = a[column];
        final bVal = b[column];
        
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return ascending ? -1 : 1;
        if (bVal == null) return ascending ? 1 : -1;
        
        if (aVal is num && bVal is num) {
          return ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
        }
        
        return ascending 
          ? aVal.toString().compareTo(bVal.toString())
          : bVal.toString().compareTo(aVal.toString());
      });
    });
  }

  String _formatFieldValue(dynamic value, String type) {
    if (value == null) return '-';
    
    switch (type) {
      case 'string':
        return value.toString();
      case 'int':
        return value.toString();
      case 'decimal':
        if (value is num) {
          return value.toStringAsFixed(1);
        }
        return value.toString();
      case 'percentage':
        if (value is num) {
          return '${value.toStringAsFixed(1)}%';
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}