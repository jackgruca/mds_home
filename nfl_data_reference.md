# NFL Data Reference Guide
*Complete field inventory for efficient analysis planning*

## 🎯 Quick Reference

**Total Packages:** 2 (nflfastR, nflreadr)  
**Core Datasets:** 10+  
**Field Count:** 500+ unique fields  
**Coverage:** 2009-2024 seasons  

---

## 📊 CORE DATASETS

### Play-by-Play Data (nflfastR)
**Function:** `load_pbp(seasons)`  
**Coverage:** 2009-2024 | **Size:** ~1M+ rows × 372 columns

**Key ID Fields:**
- `play_id` - Unique play identifier
- `game_id` - Unique game identifier (format: YYYY_WW_AWAY_HOME)
- `old_game_id` - Legacy game ID for older data
- `nflverse_game_id` - Standardized game identifier

**Player Fields:**
- `passer_player_name`, `passer_player_id`, `passer_id`
- `rusher_player_name`, `rusher_player_id`, `rusher_id`
- `receiver_player_name`, `receiver_player_id`, `receiver_id`
- `fantasy_player_name`, `fantasy_player_id`

**Team Fields:**
- `posteam` - Team with possession
- `defteam` - Defending team
- `home_team`, `away_team`
- `timeout_team`, `penalty_team`

**Game Context:**
- `season`, `week`, `season_type`
- `game_date`, `game_seconds_remaining`
- `quarter_seconds_remaining`, `half_seconds_remaining`
- `yardline_100` - Distance to goal line

**Advanced Metrics:**
- `epa` - Expected Points Added
- `wpa` - Win Probability Added
- `ep` - Expected Points
- `wp` - Win Probability
- `air_epa`, `yac_epa`
- `comp_air_epa`, `comp_yac_epa`

---

### Player Stats (nflfastR)
**Function:** `load_player_stats(seasons)`  
**Coverage:** 2009-2024 | **Size:** Variable by position

**Passing Stats:**
- `attempts`, `completions`, `passing_yards`
- `passing_tds`, `interceptions`, `sacks`
- `sack_yards`, `sack_fumbles`, `sack_fumbles_lost`
- `passing_air_yards`, `passing_yards_after_catch`
- `passing_first_downs`, `passing_epa`
- `passing_2pt_conversions`, `pacr` (Passing Air Conversion Rate)

**Rushing Stats:**
- `carries`, `rushing_yards`, `rushing_tds`
- `rushing_fumbles`, `rushing_fumbles_lost`
- `rushing_first_downs`, `rushing_epa`
- `rushing_2pt_conversions`

**Receiving Stats:**
- `receptions`, `targets`, `receiving_yards`
- `receiving_tds`, `receiving_fumbles`, `receiving_fumbles_lost`
- `receiving_air_yards`, `receiving_yards_after_catch`
- `receiving_first_downs`, `receiving_epa`
- `receiving_2pt_conversions`, `racr`, `target_share`
- `air_yards_share`, `wopr` (Weighted Opportunity Rating)

---

### Rosters (nflreadr)
**Function:** `load_rosters(seasons)`  
**Coverage:** 2009-2024 | **Size:** ~3000 rows/season × 19 columns

**Player Identification:**
- `player_name` - Full player name
- `player_id` - nflverse player ID
- `gsis_id` - NFL GSIS identifier
- `esb_id` - ESPN identifier
- `gsis_it_id` - Alternative GSIS ID

**Physical/Biographical:**
- `position` - Player position
- `depth_chart_position` - Depth chart listing
- `jersey_number`, `status`
- `birth_date`, `age`
- `height`, `weight`
- `college`, `high_school`

**Career Info:**
- `entry_year`, `rookie_year`
- `draft_club`, `draft_number`
- `years_exp` - Years of experience

---

### Schedules (nflreadr)
**Function:** `load_schedules(seasons)`  
**Coverage:** 1999-2024 | **Size:** ~270 games/season × 36 columns

**Game Identification:**
- `game_id` - Primary game identifier
- `old_game_id` - Legacy identifier
- `nflverse_game_id` - Standardized ID

**Teams & Timing:**
- `home_team`, `away_team`
- `season`, `week`, `season_type`
- `gameday`, `weekday`, `gametime`

**Results:**
- `result` - Point differential (home team perspective)
- `total` - Combined points scored
- `overtime` - OT indicator
- `home_score`, `away_score`

**Advanced Context:**
- `location` - Game location
- `roof` - Stadium roof type
- `surface` - Playing surface
- `temp`, `wind` - Weather conditions
- `home_rest`, `away_rest` - Days rest
- `home_moneyline`, `away_moneyline` - Betting odds
- `spread_line`, `total_line` - Point spread and total
- `div_game` - Division game indicator

---

### Draft Picks (nflreadr)
**Function:** `load_draft_picks()`  
**Coverage:** 1936-2024 | **Size:** ~24K picks × 15 columns

**Draft Context:**
- `season` - Draft year
- `round`, `pick` - Round and overall pick number
- `team` - Drafting team

**Player Info:**
- `pfr_player_name` - Pro Football Reference name
- `pfr_player_id` - PFR identifier
- `cfb_player_id` - College Football identifier
- `position` - Draft position
- `age` - Age at draft
- `to`, `ap1`, `pb`, `st` - Career achievements
- `car_av`, `dr_av` - Approximate Value metrics
- `college` - College attended

---

### Combine Data (nflreadr)
**Function:** `load_combine()`  
**Coverage:** 1987-2024 | **Size:** ~8600 participants × 18 columns

**Identification:**
- `pfr_id` - Pro Football Reference ID
- `player_name` - Full name
- `season` - Combine year

**Measurables:**
- `ht` - Height (inches)
- `wt` - Weight (pounds)
- `forty` - 40-yard dash (seconds)
- `vertical` - Vertical jump (inches)
- `bench` - Bench press reps
- `broad_jump` - Broad jump (inches)
- `cone` - 3-cone drill (seconds)
- `shuttle` - 20-yard shuttle (seconds)

**Context:**
- `pos` - Position
- `school` - College
- `draft_year` - Year drafted
- `draft_team` - Team that drafted player
- `draft_round`, `draft_ovr` - Draft round and overall pick

---

### Contracts (nflreadr)
**Function:** `load_contracts()`  
**Coverage:** Current contracts | **Size:** ~2700 players × 19 columns

**Contract Details:**
- `player` - Player name
- `team` - Current team
- `pos` - Position
- `value` - Total contract value
- `guaranteed` - Guaranteed money
- `aav` - Average Annual Value
- `years` - Contract length
- `apy_cap_pct` - APY as % of salary cap

**Years & Structure:**
- `year_signed`, `years_left`
- `inflated_value`, `inflated_guaranteed`
- `player_id`, `otc_id` - Player identifiers

---

### Injuries (nflreadr)
**Function:** `load_injuries(seasons)`  
**Coverage:** 2009-2024 | **Size:** Variable × 10 columns

**Injury Tracking:**
- `season`, `week`
- `team` - Player's team
- `full_name` - Complete player name
- `first_name`, `last_name`
- `position` - Player position
- `injury_status` - Status (Out, Questionable, etc.)
- `report_primary_injury` - Primary injury description
- `report_secondary_injury` - Secondary injury
- `practice_status` - Practice participation

---

### Next Gen Stats (nflreadr)
**Function:** `load_nextgen_stats(seasons, stat_type)`  
**Types:** "passing", "rushing", "receiving"

**Passing NGS:**
- `player_gsis_id`, `player_display_name`
- `position`, `team`, `season`, `week`
- `attempts`, `pass_yards`, `pass_touchdowns`
- `interceptions`, `passer_rating`
- `completion_percentage`, `expected_completion_percentage`
- `completion_percentage_above_expectation`
- `avg_time_to_throw`, `avg_completed_air_yards`
- `avg_intended_air_yards`, `avg_air_yards_differential`
- `aggressiveness`, `max_completed_air_distance`
- `avg_air_yards_to_sticks`, `passer_rating`

**Rushing NGS:**
- `efficiency`, `percent_attempts_gte_eight_defenders`
- `avg_time_to_los` - Average time to line of scrimmage
- `expected_rush_yards`, `rush_yards_over_expected`
- `avg_rush_yards`, `rush_attempts`
- `rush_yards`, `rush_touchdowns`
- `rush_pct_above_expectation`

**Receiving NGS:**
- `avg_cushion`, `avg_separation`
- `avg_intended_air_yards`, `percent_share_of_intended_air_yards`
- `receptions`, `targets`, `catch_percentage`
- `yards`, `rec_touchdowns`
- `avg_yac`, `avg_expected_yac`, `avg_yac_above_expectation`

---

## 🔗 JOIN STRATEGIES

### Universal Join Keys

**Player Analysis Joins:**
```r
# Primary: player_name + season (most reliable)
pbp %>% left_join(rosters, by = c("passer_player_name" = "player_name", "season"))

# Secondary: gsis_id (when available)
rosters %>% left_join(combine, by = c("gsis_id" = "pfr_id"))

# Tertiary: Fuzzy matching for name variations
```

**Game Analysis Joins:**
```r
# Primary: game_id (most datasets)
pbp %>% left_join(schedules, by = "game_id")

# Secondary: team + season + week + date
schedules %>% left_join(injuries, by = c("home_team" = "team", "season", "week"))
```

**Team Analysis Joins:**
```r
# Standard team abbreviations work across most datasets
pbp %>% left_join(schedules, by = c("posteam" = "home_team", "game_id"))
```

### Common Field Name Mappings

**Player Identifiers:**
- `gsis_id` = `player_id` (in some contexts)
- `passer_player_name` = `player_name` = `player_display_name`
- `fantasy_player_name` = cleaned version of `player_name`

**Team Identifiers:**
- `posteam` = `team` = `home_team`/`away_team`
- Team abbreviations standardized across datasets

**Time Identifiers:**
- `season` + `week` universal across datasets
- `game_date` format: YYYY-MM-DD
- `gameday` in schedules = `game_date` in pbp

---

## 🧩 ANALYSIS CAPABILITY MATRIX

### What Each Dataset Enables

**Play-by-Play (nflfastR):**
- ✅ Situational analysis (down, distance, field position)
- ✅ Player performance in specific game contexts
- ✅ Advanced metrics (EPA, WPA, leverage)
- ✅ Drive and series analysis
- ✅ Penalty and turnover analysis

**Player Stats (nflfastR):**
- ✅ Season/career statistical summaries
- ✅ Fantasy football analysis
- ✅ Efficiency metrics (PACR, RACR, WOPR)
- ✅ Position group comparisons
- ✅ Weekly performance tracking

**Rosters (nflreadr):**
- ✅ Player biographical analysis
- ✅ Draft class studies
- ✅ Age/experience curves
- ✅ College production correlation
- ✅ Physical measurable impact

**Schedules (nflreadr):**
- ✅ Home/away splits
- ✅ Weather impact analysis
- ✅ Rest advantage studies
- ✅ Betting line analysis
- ✅ Divisional rivalry patterns

**Next Gen Stats (nflreadr):**
- ✅ Advanced passing metrics (time to throw, separation)
- ✅ Rushing efficiency and expected values
- ✅ Pressure and coverage analysis
- ✅ Player tracking data insights

### Multi-Dataset Analysis Examples

**QB Under Pressure Analysis:**
```r
# Combine: PBP + NGS + Rosters
pbp_pressure <- pbp %>% 
  filter(qb_hit == 1 | was_pressure == 1) %>%
  left_join(ngs_passing, by = c("passer_player_name" = "player_display_name", "season", "week")) %>%
  left_join(rosters, by = c("passer_player_name" = "player_name", "season"))
```

**Draft Pick Value Analysis:**
```r
# Combine: Draft + Rosters + Player Stats
draft_value <- draft_picks %>%
  left_join(rosters, by = c("pfr_player_name" = "player_name")) %>%
  left_join(player_stats, by = c("player_name", "season"))
```

**Weather Impact on Passing:**
```r
# Combine: PBP + Schedules + NGS
weather_passing <- pbp %>%
  filter(pass == 1) %>%
  left_join(schedules, by = "game_id") %>%
  left_join(ngs_passing, by = c("passer_player_name" = "player_display_name", "season", "week"))
```

---

## ⚡ EFFICIENCY TIPS

### Quick Data Checks
```r
# Always verify data availability first
table(pbp_2024$season, pbp_2024$week)  # Check coverage
length(unique(rosters_2024$player_name))  # Player count
colnames(ngs_passing)[grepl("time|throw", colnames(ngs_passing))]  # Find relevant fields
```

### Common Filters
```r
# Regular season only
filter(season_type == "REG")

# Exclude preseason/special teams
filter(play_type %in% c("pass", "run"))

# Minimum attempt thresholds
filter(attempts >= 100)  # For QB analysis
filter(targets >= 50)    # For WR analysis
```

### Performance Considerations
- **Large datasets:** Use `slice_sample()` for development
- **Multiple seasons:** Filter early in pipeline
- **Memory management:** Select only needed columns upfront
- **Join efficiency:** Use smaller dataset as primary table when possible

---

## 🚨 DATA LIMITATIONS & GOTCHAS

### Known Issues
- **2009-2011:** Limited advanced metrics in early nflfastR years
- **Player names:** Spelling variations across datasets require fuzzy matching
- **Team relocations:** Handle team abbreviation changes (LAR, LV, etc.)
- **Missing NGS:** Not all players/games have Next Gen Stats coverage
- **Combine participation:** Not all draft picks participated in combine

### Quality Checks
```r
# Check for data gaps
pbp %>% count(season, week, sort = TRUE)

# Verify join success rates
left_join_result %>% summarise(join_rate = mean(!is.na(joined_field)))

# Identify outliers
player_stats %>% filter(passing_yards > 6000)  # Unrealistic values
```

This reference enables instant analysis planning - you'll know exactly what data is available and how to combine it for any NFL question!