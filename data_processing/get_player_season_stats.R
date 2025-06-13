# data_processing/get_player_season_stats.R

# 1. SETUP
# ------------------------------------------------
# Install packages if you don't have them
# install.packages("nflreadr")
# install.packages("tidyverse")
# install.packages("jsonlite")

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)

cat("Loaded libraries: nflreadr, tidyverse, jsonlite\n")

# Define seasons to load. nflreadr can be slow for many seasons.
# Let's grab the last 5 years of data as a starting point.
current_year <- as.numeric(format(Sys.Date(), "%Y"))
seasons_to_load <- (current_year - 5):(current_year -1)

cat("Fetching player stats for seasons:", paste(seasons_to_load, collapse=", "), "\n")

# 2. DATA FETCHING AND CLEANING
# ------------------------------------------------
# Load seasonal player stats from nflreadr
player_stats <- nflreadr::load_player_stats(seasons = seasons_to_load)

cat("Successfully downloaded", nrow(player_stats), "player-season-week rows.\n")

# Load additional datasets with error handling
load_safe <- function(func, ..., dataset_name) {
  tryCatch({
    cat("Loading", dataset_name, "...\n")
    result <- func(...)
    cat("✅", dataset_name, "loaded:", nrow(result), "rows\n")
    return(result)
  }, error = function(e) {
    cat("⚠️", dataset_name, "failed to load:", e$message, "\n")
    return(NULL)
  })
}

# Load additional datasets
rosters <- load_safe(nflreadr::load_rosters, seasons = seasons_to_load, dataset_name = "Rosters")
snap_counts <- load_safe(nflreadr::load_snap_counts, seasons = seasons_to_load, dataset_name = "Snap Counts")
combine_data <- load_safe(nflreadr::load_combine, dataset_name = "Combine Data")

# Clean and process the main player stats data
season_stats <- player_stats %>%
  group_by(player_id, player_name, position, season, recent_team) %>%
  summarise(
    # General
    games = n_distinct(week),

    # Passing Stats
    completions = sum(completions, na.rm = TRUE),
    attempts = sum(attempts, na.rm = TRUE),
    passing_yards = sum(passing_yards, na.rm = TRUE),
    passing_tds = sum(passing_tds, na.rm = TRUE),
    interceptions = sum(interceptions, na.rm = TRUE),
    sacks = sum(sacks, na.rm = TRUE),
    sack_yards = sum(sack_yards, na.rm = TRUE),

    # Rushing Stats
    rushing_attempts = sum(carries, na.rm = TRUE),
    rushing_yards = sum(rushing_yards, na.rm = TRUE),
    rushing_tds = sum(rushing_tds, na.rm = TRUE),

    # Receiving Stats
    receptions = sum(receptions, na.rm = TRUE),
    targets = sum(targets, na.rm = TRUE),
    receiving_yards = sum(receiving_yards, na.rm = TRUE),
    receiving_tds = sum(receiving_tds, na.rm = TRUE),
    
    # Advanced Receiving
    wopr = mean(wopr, na.rm = TRUE),

    # Fantasy Points
    fantasy_points = sum(fantasy_points, na.rm = TRUE),
    fantasy_points_ppr = sum(fantasy_points_ppr, na.rm = TRUE),

    .groups = 'drop'
  ) %>%
  # Filter for relevant positions and players with activity
  filter(
    position %in% c('QB', 'RB', 'WR', 'TE') & (attempts > 0 | rushing_attempts > 0 | targets > 0)
  ) %>%
  # Create some useful rate stats. Avoid division by zero.
  mutate(
    passing_yards_per_attempt = ifelse(attempts > 0, passing_yards / attempts, 0),
    passing_tds_per_attempt = ifelse(attempts > 0, passing_tds / attempts, 0),
    rushing_yards_per_attempt = ifelse(rushing_attempts > 0, rushing_yards / rushing_attempts, 0),
    rushing_tds_per_attempt = ifelse(rushing_attempts > 0, rushing_tds / rushing_attempts, 0),
    yards_per_reception = ifelse(receptions > 0, receiving_yards / receptions, 0),
    receiving_tds_per_reception = ifelse(receptions > 0, receiving_tds / receptions, 0),
    yards_per_touch = ifelse((rushing_attempts + receptions) > 0, (rushing_yards + receiving_yards) / (rushing_attempts + receptions), 0)
  )

cat("Processed main player stats. Found", nrow(season_stats), "aggregated player-season records.\n")

# 3. ADD ROSTER DATA (Physical attributes, team info)
# ------------------------------------------------
if (!is.null(rosters)) {
  cat("\n-> Adding roster data...\n")
  
  # Check what columns are available in rosters
  roster_cols_available <- names(rosters)
  cat("Available roster columns:", paste(roster_cols_available[1:10], collapse = ", "), "...\n")
  
  # Select useful roster columns that exist
  roster_cols_desired <- c("gsis_id", "season", "full_name", "position", "team", "height", "weight", "birth_date", "entry_year", "draft_number")
  roster_cols_to_use <- intersect(roster_cols_desired, roster_cols_available)
  
  if (length(roster_cols_to_use) >= 2) {
    rosters_clean <- rosters %>%
      select(all_of(roster_cols_to_use)) %>%
      # Rename gsis_id to player_id to match our main dataset
      {if("gsis_id" %in% names(.)) rename(., player_id = gsis_id) else .} %>%
      # Remove duplicates
      {if(all(c("player_id", "season") %in% names(.))) distinct(., player_id, season, .keep_all = TRUE) else .}
    
    # Join with main data
    if ("player_id" %in% names(rosters_clean)) {
      season_stats <- season_stats %>%
        left_join(rosters_clean, by = c("player_id", "season"), suffix = c("", "_roster"))
      cat("✅ Roster data joined successfully\n")
    } else {
      cat("⚠️ Could not join roster data - no matching player_id\n")
    }
  } else {
    cat("⚠️ Not enough useful roster columns available\n")
  }
}

# 4. ADD SNAP COUNT DATA (Usage/workload info)
# ------------------------------------------------
if (!is.null(snap_counts)) {
  cat("\n-> Adding snap count data...\n")
  
  # Check snap counts structure
  snap_cols_available <- names(snap_counts)
  cat("Available snap count columns:", paste(snap_cols_available[1:8], collapse = ", "), "...\n")
  
  # Aggregate snap counts by player and season
  if (all(c("player", "season", "offense_snaps") %in% snap_cols_available)) {
    snaps_agg <- snap_counts %>%
      group_by(player, season) %>%
      summarise(
        total_offense_snaps = sum(offense_snaps, na.rm = TRUE),
        avg_offense_pct = mean(offense_pct, na.rm = TRUE),
        total_defense_snaps = sum(defense_snaps, na.rm = TRUE),
        avg_defense_pct = mean(defense_pct, na.rm = TRUE),
        total_st_snaps = sum(st_snaps, na.rm = TRUE),
        avg_st_pct = mean(st_pct, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Only keep records with meaningful snap data
      filter(total_offense_snaps > 0 | total_defense_snaps > 0 | total_st_snaps > 0) %>%
      # Rename player to match our join key
      rename(player_name = player)
    
    # Join with main data using player_name
    season_stats <- season_stats %>%
      left_join(snaps_agg, by = c("player_name", "season"), suffix = c("", "_snaps"))
    
    cat("✅ Snap count data joined successfully\n")
  } else {
    cat("⚠️ Could not process snap count data - missing expected columns\n")
  }
}

# 5. ADD COMBINE DATA (Athletic measurements)
# ------------------------------------------------
if (!is.null(combine_data)) {
  cat("\n-> Adding combine data...\n")
  
  # Check combine data structure
  combine_cols_available <- names(combine_data)
  cat("Available combine columns:", paste(combine_cols_available[1:8], collapse = ", "), "...\n")
  
  # Select useful combine metrics
  combine_cols_desired <- c("player_name", "forty", "vertical", "broad_jump", "cone", "shuttle", "bench")
  combine_cols_to_use <- intersect(combine_cols_desired, combine_cols_available)
  
  if (length(combine_cols_to_use) >= 2) {
    combine_clean <- combine_data %>%
      select(all_of(combine_cols_to_use)) %>%
      # Remove duplicates (keep first non-NA values)
      group_by(player_name) %>%
      summarise(across(everything(), ~first(.x[!is.na(.x)])), .groups = 'drop') %>%
      # Rename combine metrics for clarity
      rename_with(~paste0("combine_", .x), .cols = -player_name)
    
    # Join with main data
    season_stats <- season_stats %>%
      left_join(combine_clean, by = "player_name", suffix = c("", "_combine"))
    
    cat("✅ Combine data joined successfully\n")
  } else {
    cat("⚠️ Could not process combine data - not enough useful columns\n")
  }
}

# 6. FINAL CLEANUP AND COLUMN SELECTION
# ------------------------------------------------
cat("\n-> Final data cleanup...\n")

# Select and reorder columns for final output
final_stats <- season_stats %>%
  # Replace NaN with 0 for cleaner JSON
  mutate_if(is.numeric, ~replace(., is.nan(.), 0)) %>%
  # Select columns in logical order (keeping all the original ones plus new ones)
  select(
    # Identifiers
    player_id, player_name, position, season, recent_team, games,
    
    # Physical attributes (from rosters, if available)
    any_of(c("height", "weight", "birth_date", "entry_year", "draft_number")),
    
    # Passing
    completions, attempts, passing_yards, passing_tds, interceptions, sacks, sack_yards,
    passing_yards_per_attempt, passing_tds_per_attempt,
    
    # Rushing
    rushing_attempts, rushing_yards, rushing_tds,
    rushing_yards_per_attempt, rushing_tds_per_attempt,
    
    # Receiving
    receptions, targets, receiving_yards, receiving_tds,
    yards_per_reception, receiving_tds_per_reception,
    
    # Advanced
    wopr, yards_per_touch,
    
    # Usage data (from snap counts, if available)
    any_of(c("total_offense_snaps", "avg_offense_pct", "total_defense_snaps", "avg_defense_pct", "total_st_snaps", "avg_st_pct")),
    
    # Athletic measurements (from combine, if available)
    any_of(c("combine_forty", "combine_vertical", "combine_broad_jump", "combine_cone", "combine_shuttle", "combine_bench")),
    
    # Fantasy
    fantasy_points, fantasy_points_ppr
  )

cat("Final dataset prepared with", nrow(final_stats), "rows and", ncol(final_stats), "columns\n")
cat("Final columns:", paste(names(final_stats), collapse = ", "), "\n")

# 7. EXPORT TO JSON
# ------------------------------------------------
# Define the output file path
output_file <- "player_stats.json"

# Convert the data frame to a JSON array format and write to file
json_data <- toJSON(final_stats, pretty = TRUE, auto_unbox = TRUE)
write(json_data, file = output_file)

cat("\n✅ Successfully exported data to", output_file, "\n")
cat("You can now use the 'upload_player_stats.js' script to upload this file to Firestore.\n")