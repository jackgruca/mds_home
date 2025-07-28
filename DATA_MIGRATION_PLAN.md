# Data Migration & Implementation Plan

## Current State Analysis

### Existing CSV Files:
- `player_profiles.csv` - 3,856 players ✓
- `player_stats_2024.csv` - Season aggregated stats ✓
- Position-specific game stats:
  - `quarterback_game_stats.csv` - 1,365 records
  - `runningback_game_stats.csv` - 2,882 records
  - `tightend_game_stats.csv` - 2,162 records
  - `widereceiver_game_stats.csv` - 4,277 records

## Immediate Next Steps

### Step 1: Consolidate Game Stats (Priority: HIGH)

Create a unified `player_game_stats_all.csv` by merging position files:

```python
# Script to merge position-specific CSVs
import pandas as pd

# Load all position files
qb_stats = pd.read_csv('quarterback_game_stats.csv')
rb_stats = pd.read_csv('runningback_game_stats.csv')
te_stats = pd.read_csv('tightend_game_stats.csv')
wr_stats = pd.read_csv('widereceiver_game_stats.csv')

# Standardize columns and merge
# Add position column if not present
# Handle stat columns that don't apply to all positions
```

### Step 2: Create Game Schedule Master File

Extract unique games from game stats to create `game_schedule.csv`:
- Parse game_id to extract date, teams
- Add playoff indicators based on week number
- Include weather/venue data if available

### Step 3: Build New Data Services

#### UnifiedGameStatsService
```dart
class UnifiedGameStatsService {
  // Load consolidated game stats
  // Index by player_id and game_id
  // Support position-agnostic queries
  
  Future<List<GameStats>> getPlayerGameLog(
    String playerId, {
    StatsFilter? filter,
  });
  
  Future<List<GameStats>> getGamesForWeek(
    int season,
    int week,
  );
}
```

#### DynamicAggregationService
```dart
class DynamicAggregationService {
  // Aggregate game stats on-the-fly
  // Support custom date ranges
  // Handle playoff normalization
  
  Future<SeasonStats> aggregateToSeason(
    String playerId,
    int season, {
    bool includePlayoffs = true,
    int? throughWeek,
  });
  
  Future<CareerStats> aggregateToCareer(
    String playerId, {
    DateRange? dateRange,
  });
}
```

### Step 4: Update UI Components

#### Enhanced Player Profile Screen
```dart
PlayerProfileScreen
  ├─ HeaderSection (name, team, photo)
  ├─ QuickStatsCard (current season highlights)
  ├─ TabBar
  │   ├─ Career Tab
  │   ├─ Season Tab (with year selector)
  │   ├─ Game Log Tab (with filters)
  │   └─ Splits Tab
  └─ NavigationButtons (similar players, team page)
```

## Migration Timeline

### Week 1
- [ ] Create data consolidation scripts
- [ ] Generate unified game stats CSV
- [ ] Build game schedule master file
- [ ] Test data integrity

### Week 2
- [ ] Implement UnifiedGameStatsService
- [ ] Create efficient indexing system
- [ ] Build basic filtering capability
- [ ] Add caching layer

### Week 3
- [ ] Build DynamicAggregationService
- [ ] Implement date range filtering
- [ ] Add playoff/regular season splits
- [ ] Create aggregation caching

### Week 4
- [ ] Update player profile screen
- [ ] Add game log with filtering UI
- [ ] Implement season comparison view
- [ ] Add navigation between players

## Performance Considerations

1. **Initial Load**: ~15MB of CSV data
   - Load asynchronously on app start
   - Show splash screen during load
   - Cache parsed data in memory

2. **Query Speed**: Target <50ms for any query
   - Pre-build indexes on player_id, game_id
   - Use HashMap for O(1) lookups
   - Cache common aggregations

3. **Memory Usage**: ~50-100MB in memory
   - Acceptable for modern devices
   - Consider pagination for game logs
   - Implement LRU cache for aggregations

## Data Update Strategy

1. **Weekly Updates**
   - New game stats appended to CSV
   - Regenerate aggregations
   - Push update to app

2. **Season Transitions**
   - Archive previous season data
   - Reset current season files
   - Maintain historical data

## Validation Checklist

- [ ] All player_ids match between files
- [ ] Game totals match team stats
- [ ] Season aggregations match game sums
- [ ] Playoff games properly tagged
- [ ] Missing data handled gracefully