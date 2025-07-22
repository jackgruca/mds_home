# Ranking System Documentation

## Overview
This document provides comprehensive details on the data population code, structure, and multi-year support for the NFL player ranking system.

## Data Structure

### Collections
- **wrRankings**: Wide receiver rankings and stats
- **rb_rankings**: Running back rankings and stats  
- **te_rankings**: Tight end rankings and stats
- **qbRankings**: Quarterback rankings and stats

### Field Naming Conventions

#### Wide Receivers (wrRankings)
- `receiver_player_name`: Player name (matches original data source)
- `receiver_player_id`: Unique player identifier
- `season`: Year (integer for 2024, string for others)
- `totalEPA`: Expected Points Added
- `tgt_share`: Target share percentage (0-1)
- `numYards`: Receiving yards
- `numTD`: Touchdowns
- `numRec`: Receptions
- `conversion_rate`: First down conversion rate
- `explosive_rate`: Explosive play rate
- `avg_intended_air_yards`: Average intended air yards
- `myRank`: Calculated composite score
- `myRankNum`: Rank number (1-N)
- `wr_tier`: Tier assignment (1-8)

#### Running Backs (rb_rankings) 
- `player_name`: Player name (standardized field name)
- `season`: Year (string format)
- `totalEPA`: Expected Points Added
- `rush_share`: Rush share percentage (0-1)
- `numYards`: Rushing yards
- `numTD`: Touchdowns
- `numRec`: Receptions
- `tgt_share`: Target share percentage
- `conversion_rate`: First down conversion rate
- `explosive_rate`: Explosive play rate
- `myRank`: Calculated composite score
- `myRankNum`: Rank number (1-N)
- `rb_tier`: Tier assignment (1-8)

#### Tight Ends (te_rankings)
- `player_name`: Player name (standardized field name)
- `season`: Year (string format)
- `totalEPA`: Expected Points Added
- `tgt_share`: Target share percentage (0-1)
- `numYards`: Receiving yards
- `numTD`: Touchdowns
- `numRec`: Receptions
- `conversion_rate`: First down conversion rate
- `explosive_rate`: Explosive play rate
- `avg_separation`: Average separation yards
- `catch_percentage`: Catch percentage (0-1)
- `myRank`: Calculated composite score
- `myRankNum`: Rank number (1-N)
- `te_tier`: Tier assignment (1-8)

## Ranking Calculation Methodology

### Wide Receiver Formula
```
myRank = (2 * EPA_rank) + tgt_rank + yards_rank + (0.5 * conversion_rank) + 
         (0.5 * explosive_rank) + sep_rank + (0.3 * air_yards_rank)
```

### Running Back Formula
```
myRank = (2 * EPA_rank) + rush_share_rank + yards_rank + (0.5 * conversion_rank) + 
         (0.5 * explosive_rank) + target_share_rank + reception_rank
```

### Tight End Formula
```
myRank = (2 * EPA_rank) + tgt_rank + yards_rank + (0.5 * conversion_rank) + 
         (0.5 * explosive_rank) + sep_rank + catch_rank
```

### Tier Assignment
8-tier system based on percentiles:
- Tier 1: Top 12.5% (87.5+ percentile)
- Tier 2: 75-87.5% percentile
- Tier 3: 62.5-75% percentile
- Tier 4: 50-62.5% percentile
- Tier 5: 37.5-50% percentile
- Tier 6: 25-37.5% percentile
- Tier 7: 12.5-25% percentile
- Tier 8: Bottom 12.5% (0-12.5 percentile)

## Data Import Scripts

### Current Year Data (2025)
Located in `data_processing/`:

1. **Wide Receivers**: `import_2025_wr_rankings.js`
   - Reads CSV with comprehensive WR data
   - Calculates ranking scores and tiers
   - Imports to `wrRankings` collection

2. **Running Backs**: `create_2025_rb_data.js`
   - Enhanced dataset with realistic projections
   - Calculates RB-specific ranking methodology
   - Imports to `rb_rankings` collection

3. **Tight Ends**: `create_2025_te_data.js`
   - Comprehensive TE dataset with advanced metrics
   - Calculates TE-specific ranking methodology
   - Imports to `te_rankings` collection

### Multi-Year Data Import Process

#### Step 1: Prepare Data Files
For each historical year (2016-2024), create CSV files with consistent field names:
- WR: `{year}_wr_rankings.csv`
- RB: `{year}_rb_rankings.csv`  
- TE: `{year}_te_rankings.csv`

#### Step 2: Required CSV Columns

**WR Data:**
- `player`: Player name
- `posteam`: Team abbreviation
- `season`: Year
- `tgt_share`: Target share (decimal)
- `numYards`: Receiving yards
- `numTD`: Touchdowns
- `numRec`: Receptions
- `conv_rate` or `conversion_rate`: Conversion rate
- `explosive_rate`: Explosive play rate
- `avg_intended_air_yards`: Average air yards

**RB Data:**
- `player_name`: Player name
- `posteam`: Team abbreviation
- `season`: Year
- `rush_share`: Rush share (decimal)
- `numYards`: Rushing yards
- `numTD`: Touchdowns
- `numRec`: Receptions
- `tgt_share`: Target share
- `conversion_rate`: Conversion rate
- `explosive_rate`: Explosive play rate

**TE Data:**
- `player_name`: Player name
- `posteam`: Team abbreviation
- `season`: Year
- `tgt_share`: Target share (decimal)
- `numYards`: Receiving yards
- `numTD`: Touchdowns
- `numRec`: Receptions
- `conversion_rate`: Conversion rate
- `explosive_rate`: Explosive play rate
- `avg_separation`: Average separation
- `catch_percentage`: Catch percentage

#### Step 3: Create Historical Import Scripts
Copy and modify existing scripts for each year:

```javascript
// Example: import_2024_wr_rankings.js
const csvPath = './2024_wr_rankings.csv';
// ... modify season to 2024
season: 2024,
// ... rest of logic remains the same
```

#### Step 4: Run Import Scripts
```bash
cd data_processing
node import_2024_wr_rankings.js
node import_2024_rb_rankings.js
node import_2024_te_rankings.js
# Repeat for each year
```

#### Step 5: Verify Data
Check Firestore collections to ensure:
- Proper season filtering works
- Field names are consistent
- Calculations are correct
- Tier distributions are reasonable

## Data Type Considerations

### Season Field Handling
- **WR**: Uses integer season (2024) for newer data
- **RB/TE**: Uses string season ("2024") for consistency
- Services handle both formats appropriately

### Field Name Mapping
- **WR**: `receiver_player_name` (historical format)
- **RB/TE**: `player_name` (standardized format)
- UI components updated to use correct field names

## Current Data Coverage

### 2025 Season (Projections)
- ✅ WR: 134 players with comprehensive stats
- ✅ RB: 24 players with enhanced metrics
- ✅ TE: 22 players with detailed analytics

### Historical Data (2016-2024)
- ⚠️ Partial coverage - requires systematic import
- 🔄 Process documented above for full historical import

## Troubleshooting

### Common Issues

1. **No Player Names Displaying**
   - Check field name mapping in UI components
   - Verify `player_name` vs `*_player_name` usage

2. **Season Filter Not Working**
   - Ensure season field type consistency
   - Check integer vs string handling in services

3. **Permission Errors**
   - Verify Firestore security rules include all collections
   - Ensure read access for ranking collections

4. **Empty Rankings**
   - Check data import success in Firestore console
   - Verify season filtering logic
   - Confirm collection names match service expectations

### Debug Tools
1. Firestore console for data verification
2. Browser dev tools for network requests
3. Service logs for query debugging
4. Import script output for data validation

## Future Enhancements

1. **Automated Data Pipeline**
   - Schedule regular data updates
   - API integration for real-time stats
   - Automated calculation refresh

2. **Advanced Analytics**
   - Player comparison tools
   - Historical trend analysis
   - Predictive modeling integration

3. **Data Quality**
   - Validation rules for imports
   - Data consistency checks
   - Anomaly detection

4. **Performance Optimization**
   - Indexed queries for large datasets
   - Cached calculations
   - Pagination for large result sets 