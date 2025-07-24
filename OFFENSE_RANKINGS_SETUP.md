# Offense Rankings Setup Guide

This guide explains how to set up and populate the Pass Offense and Run Offense rankings that have been implemented.

## Files Created

### R Scripts
- `data_processing/pass_offense_rankings.R` - Calculates pass offense tiers using your provided logic
- `data_processing/run_offense_rankings.R` - Calculates run offense tiers using your provided logic

### Upload Scripts  
- `data_processing/upload_pass_offense_rankings.js` - Uploads pass offense data to Firebase
- `data_processing/upload_run_offense_rankings.js` - Uploads run offense data to Firebase

### UI Screens
- `lib/screens/rankings/pass_offense_rankings_screen.dart` - Pass offense rankings table
- `lib/screens/rankings/run_offense_rankings_screen.dart` - Run offense rankings table

### Navigation
- Added "Pass Offense" and "Run Offense" links to the Rankings section in top navigation

## Setup Steps

### 1. Generate Data
Run the R scripts to generate the JSON data files:

```bash
cd data_processing
Rscript pass_offense_rankings.R
Rscript run_offense_rankings.R
```

This will create:
- `pass_offense_rankings.json`
- `run_offense_rankings.json`

### 2. Upload to Firebase
Upload the data to Firebase using the Node.js scripts:

```bash
cd data_processing
node upload_pass_offense_rankings.js
node upload_run_offense_rankings.js
```

### 3. Access in UI
Navigate to:
- Rankings → Pass Offense (`/rankings/pass-offense`)
- Rankings → Run Offense (`/rankings/run-offense`)

## Features Implemented

### Ranking Tables
- **Season filtering** - Filter by specific seasons (2016-2024)
- **Tier filtering** - Filter by tiers 1-8 or show all
- **Sortable columns** - Click any column header to sort
- **Team logos** - NFL team logos displayed with team names
- **Tier color coding** - Visual tier indicators with color coding
- **Responsive design** - Horizontal scroll for smaller screens

### Metrics Displayed
- **Rank** - Overall ranking with tier color
- **Team** - Team name with logo
- **Tier** - Tier classification (1-8)
- **Total Yards** - Passing/rushing yards
- **Total TDs** - Passing/rushing touchdowns
- **Success Rate** - Down and distance success percentage
- **Expected Points** - EPA (Expected Points Added)

### Data Source
Both rankings use NFL play-by-play data from 2016-2024 and calculate:
- Success rates based on down and distance (60% on 1st, 40% on 2nd, 100% on 3rd/4th)
- Percentile rankings for yards, TDs, and success rate
- Composite rankings using: `yds_rank + TD_rank + success_rank`
- 8-tier system (1-4, 5-8, 9-12, etc.)

## Firebase Collections
The service expects these collections:
- `pass_offense_rankings` - Pass offense data
- `run_offense_rankings` - Run offense data

Each document should have the structure created by the R scripts with fields like:
- `posteam`, `season`, `myRankNum`, `passOffenseTier`/`runOffenseTier`, `totalYds`, `totalTD`, `successRate`, `totalEP`