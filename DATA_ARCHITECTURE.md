# Sports Analytics Data Architecture

## Overview
This document outlines the comprehensive data architecture for a multi-level sports analytics system with local CSV storage, optimized for speed and flexibility.

## Data Hierarchy

```
Game Level (Base)
  ↓
Player Game Stats → Player Season Stats → Player Career Stats
  ↓                      ↓
Team Game Stats  →  Team Season Stats  → Team Historical Stats
```

## CSV Data Schema

### 1. Core Data Files

#### player_profiles.csv (Master Player Registry)
```csv
player_id,player_name,position,height,weight,birth_date,college,draft_year,draft_round,status
```

#### game_schedule.csv (Game Metadata)
```csv
game_id,season,week,game_type,game_date,home_team,away_team,home_score,away_score,stadium,weather_temp,weather_wind,surface,spread,total,playoff_round
```
- game_type: REG, POST, PRE
- playoff_round: NULL, WC, DIV, CONF, SB

#### player_game_stats.csv (Unified Position Stats)
```csv
game_id,player_id,team,opponent,home_away,snap_count,
# Passing
pass_att,completions,pass_yards,pass_tds,interceptions,sacks,sack_yards,pass_rating,
# Rushing  
rush_att,rush_yards,rush_tds,rush_long,rush_first_downs,
# Receiving
targets,receptions,rec_yards,rec_tds,rec_long,rec_first_downs,
# Defense
tackles,sacks_def,ints_def,pass_def,forced_fumbles,
# Fantasy
fantasy_points_std,fantasy_points_ppr,fantasy_points_half_ppr
```

#### team_game_stats.csv
```csv
game_id,team,opponent,home_away,
# Offense
total_yards,pass_yards,rush_yards,first_downs,third_down_pct,red_zone_pct,
# Defense
yards_allowed,pass_yards_allowed,rush_yards_allowed,sacks_made,turnovers_forced,
# Special Teams
fg_made,fg_att,punt_avg,punt_return_avg
```

### 2. Aggregated Data Files (Pre-computed for speed)

#### player_season_stats.csv
```csv
player_id,season,team,games_played,games_started,
# Aggregated stats from game level
# Include per-game averages and totals
```

#### player_career_stats.csv
```csv
player_id,seasons_played,teams,total_games,
# Career totals and averages
```

## Data Service Architecture

### 1. Base Services

```dart
// Core data loading service
class GameStatsDataService {
  // Singleton with aggressive caching
  // Load all position-specific CSVs into memory
  // Index by player_id and game_id for fast lookups
}

// Aggregation service
class StatsAggregationService {
  // Dynamic aggregation with filters
  // Support for date ranges, game types, etc.
}
```

### 2. Filter System

```dart
class StatsFilter {
  DateRange? dateRange;
  GameType? gameType; // REG, POST, PRE
  List<int>? weeks;
  List<String>? teams;
  bool includePlayoffs = true;
  int? lastNGames;
}
```

### 3. Navigation Structure

```
/player/:id
  → Career Overview
  → Season Stats (filterable)
  → Game Log (sortable, filterable)
  → Splits (home/away, by opponent, by month)
  → Advanced Metrics

/team/:id/:season
  → Season Overview  
  → Game Results
  → Player Stats
  → Opponent Stats
```

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
1. Create unified CSV schema
2. Build RobustGameStatsParser service
3. Implement core data models
4. Create in-memory indexing system

### Phase 2: Player Stats (Week 3-4)
1. Player game stats screen with filtering
2. Season aggregation with dynamic date ranges
3. Player profile navigation
4. Basic splits (home/away, monthly)

### Phase 3: Team Stats (Week 5-6)
1. Team game stats aggregation
2. Team season views
3. Opponent analysis
4. League rankings

### Phase 4: Advanced Features (Week 7-8)
1. Custom date range analysis
2. Playoff vs regular season normalization
3. Advanced metrics calculation
4. Export functionality

### Phase 5: Performance Optimization
1. Pre-compute common aggregations
2. Implement lazy loading for large datasets
3. Add query result caching
4. Optimize CSV parsing

## Key Design Decisions

1. **CSV Storage**: Keep all data in CSV for portability and ease of updates
2. **In-Memory Processing**: Load all data on app start for instant queries
3. **Pre-computed Aggregations**: Balance between storage and computation
4. **Flexible Filtering**: Support arbitrary date ranges and game selections
5. **Hierarchical Navigation**: Natural drill-down from career → season → game

## Example Queries

```dart
// Get player's last 5 games
final games = await gameStatsService.getPlayerGames(
  playerId: 'player123',
  filter: StatsFilter(lastNGames: 5),
);

// Get regular season stats only
final seasonStats = await aggregationService.getSeasonStats(
  playerId: 'player123',
  season: 2024,
  filter: StatsFilter(gameType: GameType.regular),
);

// Compare home vs away performance
final splits = await aggregationService.getPlayerSplits(
  playerId: 'player123',
  splitType: SplitType.homeAway,
);
```