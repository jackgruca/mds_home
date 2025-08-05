# Player Data Section - Product Requirements Document

## Executive Summary
This document outlines the phased approach to create a comprehensive player data section for the MDS Home application, featuring individual player pages with templated layouts displaying career statistics, game logs, and fantasy football performance metrics.

## Vision
Create a fast, data-rich player information system that provides comprehensive NFL player statistics at multiple levels of detail, from team-level navigation down to individual player pages with career and game-by-game data.

## Data Architecture

### Data Storage Strategy
- **Primary Storage**: Pre-processed CSV files for optimal loading performance
- **Data Structure**: Hierarchical organization (League → Team → Player)
- **Update Frequency**: Weekly during season, monthly during off-season
- **File Organization**:
  ```
  data/
  ├── players/
  │   ├── roster_current.csv          # Current season rosters
  │   ├── player_info.csv             # Biographical/physical data
  │   └── player_ids_mapping.csv      # ID cross-references
  ├── stats/
  │   ├── career_stats_summary.csv    # Career aggregates by player
  │   ├── season_stats_2024.csv       # Current season stats
  │   └── season_stats_historical.csv # Historical season stats
  ├── game_logs/
  │   ├── game_logs_2024.csv          # Current season game logs
  │   └── game_logs_historical.csv    # Historical game logs
  └── fantasy/
      ├── fantasy_points_weekly.csv   # Weekly fantasy points
      └── fantasy_rankings.csv        # Current rankings/projections
  ```

### Data Processing Pipeline
1. **R Scripts** generate CSVs from nflreadr/nflfastR
2. **Backend** reads CSVs and filters by player_id/name/team
3. **Frontend** displays templated player pages
4. **Caching** layer for frequently accessed players

## Phase 1: Foundation (Week 1-2)

### Goals
- Establish data infrastructure
- Create basic player listing
- Implement navigation structure

### Deliverables
1. **Data Generation Scripts**
   - R script to generate roster CSV with player info
   - R script to generate current season stats CSV
   - Player ID mapping file creation

2. **Player List Screen**
   - Display all players grouped by team
   - Basic filtering (position, team)
   - Search functionality
   - Click navigation to player detail (placeholder)

3. **Navigation Structure**
   - Team → Position Group → Player hierarchy
   - URL structure: `/player/{player_id}/{player_name_slug}`

### Wire Frame - Player List
```
┌─────────────────────────────────────┐
│ [Search Players...]      [Position▼]│
├─────────────────────────────────────┤
│ Buffalo Bills                       │
│ ├─ QB: Josh Allen                  │
│ ├─ RB: James Cook                  │
│ └─ RB: Ty Johnson                  │
│                                     │
│ Miami Dolphins                      │
│ ├─ QB: Tua Tagovailoa             │
│ └─ RB: De'Von Achane              │
└─────────────────────────────────────┘
```

## Phase 2: Basic Player Pages (Week 3-4)

### Goals
- Create player detail page template
- Display basic info and current season stats
- Implement responsive design

### Deliverables
1. **Player Header Component**
   - Name, position, team, jersey number
   - Physical stats (height, weight, age)
   - Draft info, college, experience

2. **Current Season Stats**
   - Position-specific stat tables
   - Comparison to league averages
   - Basic visualizations (progress bars)

3. **Data Integration**
   - Backend service to query CSVs by player_id
   - API endpoint: `/api/player/{player_id}`

### Wire Frame - Player Page (Basic)
```
┌─────────────────────────────────────┐
│ Josh Allen | QB | #17 | Bills      │
│ 6-5, 237 lbs | Age: 28             │
│ Wyoming | Round 1, Pick 7 (2018)   │
├─────────────────────────────────────┤
│ 2024 Season Stats                   │
│ ┌─────────────────────────────────┐ │
│ │ Passing                         │ │
│ │ Att: 287  Comp: 193  Yds: 2281 │ │
│ │ TD: 17    INT: 3     Rate: 97.2│ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Rushing                         │ │
│ │ Att: 54   Yds: 231   TD: 5     │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Phase 3: Historical Data & Game Logs (Week 5-6)

### Goals
- Add career statistics
- Implement game log functionality
- Create tabbed interface

### Deliverables
1. **Career Stats Tab**
   - Year-by-year statistics
   - Career totals and averages
   - Trend visualizations

2. **Game Logs Tab**
   - Detailed game-by-game stats
   - Opponent, result, key metrics
   - Sortable/filterable table

3. **Enhanced Data Scripts**
   - Historical stats aggregation
   - Game log processing
   - Performance optimization

### Wire Frame - Tabbed Interface
```
┌─────────────────────────────────────┐
│ [Overview] [Career] [Game Logs]     │
├─────────────────────────────────────┤
│ Career Statistics                   │
│ ┌─────────────────────────────────┐ │
│ │Year │Games│Yards│TD │INT│Rating││
│ │2024 │  10 │2281 │17 │ 3 │ 97.2 ││
│ │2023 │  17 │4306 │29 │18 │ 92.2 ││
│ │2022 │  16 │4283 │35 │14 │ 96.6 ││
│ │...  │ ... │ ... │...│...│ ...  ││
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Phase 4: Fantasy Integration (Week 7-8)

### Goals
- Add fantasy football metrics
- Create fantasy-specific views
- Implement scoring calculations

### Deliverables
1. **Fantasy Stats Section**
   - Fantasy points by week
   - Multiple scoring formats
   - Rankings and projections

2. **Fantasy Trends**
   - Points vs projection
   - Consistency metrics
   - Matchup history

3. **Fantasy Data Processing**
   - Custom scoring calculations
   - DFS salary tracking
   - Ownership percentages

### Wire Frame - Fantasy View
```
┌─────────────────────────────────────┐
│ Fantasy Performance                 │
│ ┌─────────────────────────────────┐ │
│ │ Scoring: [PPR ▼]                │ │
│ │ Season Rank: RB12 | 14.3 PPG    │ │
│ │ ┌─────────────────────────────┐ ││
│ │ │Week│Opp │Pts │Proj│ +/-   │ ││
│ │ │ 10 │@IND│22.4│18.5│ +3.9  │ ││
│ │ │  9 │MIA │18.7│16.2│ +2.5  │ ││
│ │ │  8 │SEA │ 9.3│15.8│ -6.5  │ ││
│ │ └─────────────────────────────┘ ││
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Phase 5: Advanced Features (Week 9-10)

### Goals
- Add advanced metrics
- Implement comparisons
- Create sharing functionality

### Deliverables
1. **Advanced Metrics**
   - EPA, DVOA, PFF grades (if available)
   - Percentile rankings
   - Situational splits

2. **Player Comparisons**
   - Side-by-side comparisons
   - Similar player suggestions
   - Historical comparisons

3. **Export/Share Features**
   - PDF reports
   - CSV export
   - Social sharing

## Technical Requirements

### Performance
- Page load < 2 seconds
- CSV parsing < 500ms
- Client-side caching

### Frontend
- React/Next.js components
- Responsive design
- TypeScript
- Tailwind CSS

### Backend
- Node.js API
- CSV parsing libraries
- Redis caching
- Player search index

### Data Updates
- Automated R scripts
- GitHub Actions for scheduling
- Data validation checks

## Success Metrics
- Page load performance
- User engagement (time on page)
- Search accuracy
- Data freshness
- Mobile responsiveness

## Future Enhancements
- Real-time updates during games
- Video highlights integration
- Injury report integration
- Weather impact analysis
- Team chemistry metrics
- Contract/salary information