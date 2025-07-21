# Player Stat Predictor - Project Requirements Document

## Executive Summary

Create a new Player Stat Predictor section that enables users to view, analyze, and customize next-year statistical predictions for WR and TE players. This feature bridges the gap between consensus rankings and custom ranking creation by providing data-driven baseline predictions with user customization capabilities.

## User Problem Statement

Fantasy football users currently struggle with:
- **Data Fragmentation**: Need to consult multiple sources for rankings, ADP, and statistical projections
- **Limited Customization**: No easy way to adjust predictions based on personal insights
- **Cumbersome Workflow**: Difficult process to create personalized rankings from various data sources
- **Missing Context**: Lack of historical prediction accuracy and tier-based classifications

## Solution Overview

A comprehensive Player Stat Predictor that allows users to:
1. View historical current vs. next-year statistical comparisons
2. See baseline 2025 predictions with tier classifications
3. Customize target share allocations with team-based normalization
4. Integrate adjusted predictions into the existing Custom Rankings Builder

## User Journey

```
Consensus Rankings → Player Stat Predictor → Custom Rankings Builder
     (existing)           (new feature)        (enhanced existing)
```

1. **User starts** at existing consensus rankings (no changes)
2. **User navigates** to new Player Stat Predictor section
3. **User views** historical and predicted stats in comparative table format
4. **User adjusts** target shares and other predictions as desired
5. **User proceeds** to Custom Rankings Builder
6. **User selects** "Next Year Predictions" as additional data source
7. **User creates** personalized rankings incorporating their adjusted predictions

## Technical Requirements

### Data Sources

**Primary Data**: 
- `'2025 FF preds - FF WR 2025 v2 (4).csv'` for 2025 predictions
- R script dataframes for historical analysis:
  - `wr_db_test`: Historical current vs. next-year stats
  - `newNYpred1`: Target share predictions
  - `wr_preds_2024`: Rookie predictions

**Data Scope**:
- **Positions**: WR and TE (filter from pass-catcher dataset)
- **Stats Comparison**: All stats with `NY_` prefix compared to current year
- **Key Metrics**:
  - `tgt_share` / `NY_tgtShare`
  - `wr_rank` / `NY_wr_rank` 
  - `points` / `NY_points`
  - `numYards` / `NY_seasonYards`
  - `numTD` / `NY_numTD`
  - `numRec` / `NY_numRec`
  - Tier classifications: `passOffenseTier`, `qbTier`, etc.

### UI/UX Requirements

#### New Screen: Player Stat Predictor
**Route**: `/projections/stat-predictor`

**Layout**:
- **Position Filter**: Toggle between WR/TE or show combined
- **Main Table**: Current vs. Next Year stats comparison
- **Tier Display**: Visual indicators for offense/QB tiers
- **Real-time Updates**: Immediate feedback on adjustments

#### Table Specifications
- **Editable Cells**: Direct editing for prediction adjustments
- **Column Structure**: Side-by-side current vs. predicted stats
- **Team Normalization**: Target share adjustments automatically rebalance teammates
- **Visual Indicators**: 
  - Highlight edited values
  - Show normalization impacts
  - Tier-based color coding

#### Enhanced Custom Rankings Integration
**Location**: Existing Custom Rankings Builder
**Addition**: New section "Next Year Predictions"
- **Toggle Option**: Include/exclude adjusted predictions
- **Data Source**: User's customized predictions from Stat Predictor
- **Integration**: Seamless incorporation with existing ranking attributes

### Technical Architecture

#### File Structure
```
lib/
├── screens/
│   └── projections/
│       └── player_stat_predictor_screen.dart
├── models/
│   └── projections/
│       ├── stat_prediction.dart
│       └── prediction_comparison.dart
├── services/
│   └── projections/
│       ├── stat_predictor_service.dart
│       └── team_normalization_service.dart
├── widgets/
│   └── stat_predictor/
│       ├── prediction_table.dart
│       ├── editable_stat_cell.dart
│       └── tier_indicator.dart
└── assets/
    └── 2025/
        └── 2025_FF_preds_FF_WR_2025_v2.csv
```

#### Data Models

**StatPrediction Model**:
```dart
class StatPrediction {
  String playerId;
  String playerName;
  String position;
  String team;
  
  // Current Year Stats
  double tgtShare;
  int wrRank;
  double points;
  int numYards;
  int numTD;
  int numRec;
  
  // Next Year Predictions
  double nyTgtShare;
  int nyWrRank;
  double nyPoints;
  int nySeasonYards;
  int nyNumTD;
  int nyNumRec;
  
  // Tier Classifications
  int passOffenseTier;
  int qbTier;
  
  // Customization
  bool isEdited;
  Map<String, double> originalValues;
}
```

#### Core Services

**StatPredictorService**:
- Load CSV data and historical comparisons
- Handle data filtering by position
- Manage prediction state and user modifications

**TeamNormalizationService**:
- Calculate team-based target share totals
- Proportionally adjust teammate values when user edits
- Maintain realistic constraints (team total ≤ 0.95)

### Functional Requirements

#### MVP Features
1. **Data Display**
   - Load and display current vs. predicted stats table
   - Filter by WR/TE positions
   - Show tier classifications

2. **Interactive Editing**
   - Direct cell editing for key predictions
   - Real-time team normalization for target shares
   - Visual feedback for modifications

3. **Custom Rankings Integration**
   - Export adjusted predictions to Custom Rankings Builder
   - New "Next Year Predictions" section in rankings
   - Toggle to include/exclude in ranking calculations

#### Enhancement Suggestions

**Phase 2 Enhancements**:

1. **Advanced Analytics**
   - Confidence intervals for predictions
   - Historical accuracy metrics
   - Prediction vs. actual performance charts

2. **Scenario Testing**
   - Save multiple prediction scenarios
   - Compare different adjustment strategies
   - "What-if" analysis tools

3. **Team Context**
   - Roster construction implications
   - Coaching/scheme change adjustments
   - Injury impact modeling

4. **Export Capabilities**
   - Export customized predictions to CSV
   - Share prediction scenarios
   - Import external adjustments

5. **Advanced Visualization**
   - Player trajectory charts
   - Team target share pie charts
   - Tier distribution visualizations

6. **Predictive Insights**
   - Identify players with highest upside potential
   - Flag predictions with high variance
   - Suggest contrarian opportunities

### Success Metrics

**User Engagement**:
- Time spent in Stat Predictor section
- Number of prediction adjustments made
- Integration rate with Custom Rankings Builder

**Feature Adoption**:
- Percentage of users who customize predictions
- Usage of adjusted predictions in rankings
- Return visits to predictor section

**User Experience**:
- Reduction in external data source consultation
- Increased ranking creation completion rates
- User satisfaction with prediction accuracy

## Implementation Priority

**Phase 1 (MVP)**:
1. Basic table display with current vs. predicted stats
2. Position filtering (WR/TE)
3. Editable target share with team normalization
4. Integration point with Custom Rankings Builder

**Phase 2 (Enhancements)**:
1. Advanced editing for all prediction stats
2. Historical accuracy display
3. Scenario saving and comparison
4. Enhanced visualizations

**Phase 3 (Advanced Features)**:
1. Machine learning model integration
2. Real-time data updates
3. Social features (sharing scenarios)
4. API integration for live updates

## Technical Considerations

**Performance**:
- Efficient CSV loading and parsing
- Real-time calculation optimization for team normalization
- Table virtualization for large datasets

**Data Management**:
- Local state management for user modifications
- Persistence of customized predictions
- Sync with existing projection data structures

**UI Consistency**:
- Leverage existing MDS design system
- Follow established table and data display patterns
- Maintain consistent navigation and user flows

**Integration Points**:
- Seamless handoff to Custom Rankings Builder
- Preserve existing ranking functionality
- Backward compatibility with current data models

## Dependencies

**External**:
- R script data processing pipeline
- CSV data export from R analysis
- Existing player and projection data models

**Internal**:
- MDS design system components
- Existing projection and ranking services
- Custom Rankings Builder architecture

## Risk Mitigation

**Data Quality**: Validate prediction accuracy and handle missing data gracefully
**Performance**: Implement efficient algorithms for real-time normalization
**User Experience**: Extensive testing of editing workflows and team normalization
**Integration**: Careful testing of Custom Rankings Builder integration points

---

*This PRD provides a comprehensive roadmap for implementing the Player Stat Predictor feature while leveraging existing infrastructure and providing clear enhancement opportunities for future development.*