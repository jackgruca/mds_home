# TE Rankings Processing and Upload

This directory contains scripts to process TE rankings data from NFL play-by-play data and upload it to Firebase.

## Files

1. `process_te_rankings.R` - R script that processes NFL data and generates comprehensive TE rankings
2. `upload_te_rankings.js` - Node.js script that uploads the processed data to Firebase
3. `te_rankings_comprehensive.json` - Output file containing processed TE rankings data

## Prerequisites

### R Dependencies
```r
install.packages(c("nflfastR", "dplyr", "jsonlite"))
```

### Node.js Dependencies
```bash
npm install firebase-admin
```

### Firebase Configuration
- Ensure `serviceAccountKey.json` is present in the data_processing directory
- Firebase project should have collections: `te_rankings_comprehensive` and `rankings`

## Usage

### Step 1: Process TE Rankings Data
```bash
cd data_processing
Rscript process_te_rankings.R
```

This will:
- Load NFL play-by-play data from 2016-2024
- Process receiving stats, target share, explosive plays, red zone efficiency
- Calculate percentile ranks for all stats
- Generate composite rankings using weighted formula
- Output JSON file with comprehensive TE rankings

### Step 2: Upload to Firebase
```bash
node upload_te_rankings.js
```

This will:
- Clear existing TE rankings from both collections
- Upload new data to `te_rankings_comprehensive` collection
- Upload to main `rankings` collection for backward compatibility
- Verify successful upload

## Data Structure

The processed data includes these fields for each TE:

### Core Fields
- `receiver_player_id` - Unique player identifier
- `receiver_player_name` - Player name
- `team` - Team abbreviation
- `season` - NFL season year
- `qbTier` - Tier ranking (1-8)
- `myRankNum` - Overall ranking number
- `myRank` - Composite ranking score (0-1)

### Raw Statistics
- `totalEPA` - Total Expected Points Added
- `totalTD` - Total touchdowns
- `numGames` - Games played
- `tgt_share` - Target share percentage
- `numYards` - Total receiving yards
- `numRec` - Total receptions
- `conversion` - Red zone conversion rate
- `explosive_rate` - Rate of 15+ yard plays
- `avg_separation` - Average separation at catch
- `avg_intended_air_yards` - Average intended air yards
- `catch_percentage` - Catch percentage
- `yac_above_expected` - YAC above expected
- `third_down_rate` - Third down conversion rate

### Percentile Ranks (0-1)
- `EPA_rank` - EPA percentile rank
- `td_rank` - TD per game percentile rank
- `tgt_rank` - Target share percentile rank
- `YPG_rank` - Yards per game percentile rank
- `conversion_rank` - Red zone conversion percentile rank
- `explosive_rank` - Explosive play percentile rank
- `sep_rank` - Separation percentile rank
- `intended_air_rank` - Intended air yards percentile rank
- `catch_rank` - Catch percentage percentile rank
- `third_down_rank` - Third down rate percentile rank
- `yacOE_rank` - YAC over expected percentile rank

## Ranking Formula

The composite ranking (`myRank`) uses this weighted formula:
- Target Share: 25%
- Yards per Game: 25%
- EPA: 15%
- YAC over Expected: 10%
- Third Down Rate: 10%
- Touchdowns: 5%
- Explosive Rate: 5%
- Separation: 5%

## Troubleshooting

### Common Issues

1. **Missing serviceAccountKey.json**
   - Ensure Firebase service account key is in the data_processing directory
   - File should have proper Firebase admin credentials

2. **R package errors**
   - Install required packages: `install.packages(c("nflfastR", "dplyr", "jsonlite"))`
   - Update to latest versions if needed

3. **Memory issues in R**
   - NFL data is large; ensure sufficient RAM available
   - Consider processing seasons separately if needed

4. **Firebase upload errors**
   - Check Firebase project permissions
   - Verify collection names match expectations
   - Check network connectivity

### Verification

After running both scripts, verify:
- JSON file exists and contains TE data only
- Firebase collections have new data
- Player positions are correctly filtered to TE
- Ranking numbers are sequential and make sense

## Notes

- Data is filtered to only include TEs with >3 games played
- Rankings are calculated within each season
- Tiers are based on overall ranking position
- All stats are from regular season games only