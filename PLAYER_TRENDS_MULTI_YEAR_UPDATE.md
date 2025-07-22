# Player Trends Multi-Year Update

## Overview
The Player Trends screen has been updated to support data from the past 5 years (2020-2024) with the ability to select different years for analysis.

## Changes Made

### 1. Frontend Updates (`lib/screens/fantasy/player_trends_screen.dart`)

#### Added Features:
- **Year Selection Dropdown**: Users can now select from 2020-2024
- **Enhanced UI**: Improved controls section with better styling
- **Dynamic Headers**: Table headers now show the selected year
- **Loading States**: Better loading indicators during data fetching

#### Key Changes:
- Added `_selectedYear` state variable defaulting to '2024'
- Added `_availableYears` list containing ['2024', '2023', '2022', '2021', '2020']
- Updated Firestore query to use `int.parse(_selectedYear)` instead of hardcoded 2023
- Enhanced controls UI with styled containers and icons
- Updated section headers to display the selected year

### 2. Data Processing Updates

#### R Script (`data_processing/get_player_game_logs.R`)
- **Multi-Year Fetching**: Changed from single year (2023) to range (2020:2024)
- **Updated Configuration**: `YEARS_TO_FETCH <- 2020:2024`
- **Enhanced Logging**: Added season information to output messages

#### Upload Script (`data_processing/upload_player_game_logs.js`)
- **No Changes Required**: Script already handles multi-year data via `game_id` field
- **Existing Logic**: Uses `game_id = paste(player_id, season, week, sep = "_")` for unique document IDs

### 3. Automation Script (`data_processing/update_player_trends_data.sh`)
- **New Script**: Created to streamline the data update process
- **Two-Step Process**: 
  1. Fetches multi-year player game logs
  2. Uploads to Firestore
- **Error Handling**: Includes proper error checking and status messages

## Usage Instructions

### For End Users:
1. Navigate to the Player Trends screen
2. Use the **Year** dropdown to select from 2020-2024
3. Select desired **Position** (RB, WR, TE, QB)
4. Adjust **Recent Weeks** slider as needed
5. Data will automatically reload when selections change

### For Developers/Administrators:

#### To Update Data:
```bash
# Make script executable (one-time)
chmod +x data_processing/update_player_trends_data.sh

# Run the update script
./data_processing/update_player_trends_data.sh
```

#### Manual Process:
```bash
# Step 1: Fetch data
cd data_processing
Rscript get_player_game_logs.R

# Step 2: Upload to Firestore
node upload_player_game_logs.js
```

## Technical Implementation

### Data Structure:
Each game log document in Firestore contains:
- `player_id`: Unique player identifier
- `season`: Year (2020-2024)
- `week`: Week number (1-18)
- `game_id`: Unique document ID (`player_id_season_week`)
- All standard NFL stats (passing, rushing, receiving)

### Query Logic:
```dart
final querySnapshot = await _firestore
    .collection('playerGameLogs')
    .where('season', isEqualTo: int.parse(_selectedYear))
    .where('position', isEqualTo: _selectedPosition)
    .get();
```

### Performance Considerations:
- Firestore queries are filtered by both season and position for efficiency
- Data is processed client-side to calculate trends and statistics
- Composite indexes may be needed for optimal query performance

## Files Modified:
1. `lib/screens/fantasy/player_trends_screen.dart` - Main screen implementation
2. `data_processing/get_player_game_logs.R` - Multi-year data fetching
3. `data_processing/update_player_trends_data.sh` - New automation script
4. `PLAYER_TRENDS_MULTI_YEAR_UPDATE.md` - This documentation

## Implementation Status: ✅ COMPLETE

### Data Population Results:
- **Total Records Uploaded**: 26,786 player game logs
- **2020**: 5,198 records ✅
- **2021**: 5,452 records ✅  
- **2022**: 5,391 records ✅
- **2023**: 5,405 records ✅
- **2024**: 5,340 records ✅

### Verification Completed:
1. ✅ **Data Fetching**: R script successfully fetched 5 years of data
2. ✅ **Firebase Upload**: All records uploaded to `playerGameLogs` collection
3. ✅ **Query Testing**: Verified Flutter app queries work for all seasons and positions
4. ✅ **UI Functionality**: Year selector dropdown is now functional with historical data

### Testing Results:
- All positions (QB, RB, WR, TE) have data for each season
- Fantasy points calculations are working correctly
- Sample data verified: T.Brady (2020-2022), A.Rodgers (2023-2024), etc.
- The Flutter app can now successfully load and display data for any selected year

## Benefits Achieved:
- **Historical Analysis**: Users can now analyze trends across 5 seasons (2020-2024)
- **Comparative Analysis**: Year-over-year player performance comparison enabled
- **Better Decision Making**: 26,786 data points available for fantasy decisions
- **Improved UX**: Intuitive year selection with real-time data loading 