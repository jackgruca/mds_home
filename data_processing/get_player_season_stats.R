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
player_stats <- nflreadr::load_player_stats(seasons = seasons_to_load, stat_type = "offense")

cat("Successfully downloaded", nrow(player_stats), "player-season-week rows.\n")

# Clean and process the data
# We want one row per player per season, so we need to aggregate the weekly data.
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
  ) %>%
  # Select and reorder columns for clarity
  select(
    # Identifiers
    player_id, player_name, position, season, recent_team, games,
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
    # Fantasy
    fantasy_points, fantasy_points_ppr
  ) %>%
  # Replace NaN with 0 for cleaner JSON
  mutate_if(is.numeric, ~replace(., is.nan(.), 0))


cat("Processed data. Found", nrow(season_stats), "aggregated player-season records.\n")


# 3. EXPORT TO JSON
# ------------------------------------------------
# Define the output file path. This will be created in the same directory where the script is run.
output_file <- "player_stats.json"

# Convert the data frame to a JSON array format and write to file
# auto_unbox = TRUE makes single values not be in an array in JSON
json_data <- toJSON(season_stats, pretty = TRUE, auto_unbox = TRUE)
write(json_data, file = output_file)

cat("Successfully exported data to", output_file, "\n")
cat("You can now use the 'upload_player_stats.js' script to upload this file to Firestore.\n") 