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
library(dplyr)

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
print(dim(player_stats))

# Load NextGen stats for QBs, RBs, and WRs
cat("Fetching NextGen stats for passing, rushing, and receiving...\n")
nextgen_passing <- nflreadr::load_nextgen_stats(seasons = seasons_to_load, stat_type = "passing") %>%
  rename(recent_team = team_abbr) %>%
  select(player_display_name, recent_team, season, week, 
         avg_time_to_throw, avg_completed_air_yards, avg_intended_air_yards, 
         avg_air_yards_differential, aggressiveness, max_completed_air_distance,
         avg_air_distance, avg_air_yards_to_sticks, completion_percentage_above_expectation)
print(dim(nextgen_passing))

nextgen_rushing <- nflreadr::load_nextgen_stats(seasons = seasons_to_load, stat_type = "rushing") %>%
  rename(recent_team = team_abbr) %>%
  select(player_display_name, recent_team, season, week, 
         efficiency, percent_attempts_gte_eight_defenders, avg_time_to_los, rush_yards_over_expected,
         rush_yards_over_expected_per_att, rush_pct_over_expected)
print(dim(nextgen_rushing))

nextgen_receiving <- nflreadr::load_nextgen_stats(seasons = seasons_to_load, stat_type = "receiving") %>%
  rename(recent_team = team_abbr) %>%
  select(player_display_name, recent_team, season, week, 
         avg_cushion, avg_separation, avg_intended_air_yards, percent_share_of_intended_air_yards,
         catch_percentage)
print(dim(nextgen_receiving))

cat("Successfully downloaded NextGen stats: ", 
    nrow(nextgen_passing), "passing rows, ",
    nrow(nextgen_rushing), "rushing rows, ",
    nrow(nextgen_receiving), "receiving rows.\n")

# Clean and process the data
# We want one row per player per season, so we need to aggregate the weekly data.
season_stats <- player_stats %>%
  group_by(player_id, player_name, player_display_name, position, season, recent_team) %>%
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
  )

# Aggregate and join NextGen passing stats for QBs
nextgen_passing_agg <- nextgen_passing %>%
  group_by(player_display_name, recent_team, season) %>%
  summarise(
    avg_time_to_throw = mean(avg_time_to_throw, na.rm = TRUE),
    avg_completed_air_yards = mean(avg_completed_air_yards, na.rm = TRUE),
    avg_intended_air_yards = mean(avg_intended_air_yards, na.rm = TRUE),
    avg_air_yards_differential = mean(avg_air_yards_differential, na.rm = TRUE),
    aggressiveness = mean(aggressiveness, na.rm = TRUE),
    max_completed_air_distance = max(max_completed_air_distance, na.rm = TRUE),
    avg_air_distance = mean(avg_air_distance, na.rm = TRUE),
    avg_air_yards_to_sticks = mean(avg_air_yards_to_sticks, na.rm = TRUE),
    completion_percentage_above_expectation = mean(completion_percentage_above_expectation, na.rm = TRUE),
    .groups = 'drop'
  )

# Aggregate and join NextGen rushing stats for RBs
nextgen_rushing_agg <- nextgen_rushing %>%
  group_by(player_display_name, recent_team, season) %>%
  summarise(
    rush_efficiency = mean(efficiency, na.rm = TRUE),
    pct_attempts_vs_eight_plus = mean(percent_attempts_gte_eight_defenders, na.rm = TRUE),
    avg_time_to_los = mean(avg_time_to_los, na.rm = TRUE),
    rush_yards_over_expected = mean(rush_yards_over_expected, na.rm = TRUE),
    rush_yards_over_expected_per_att = mean(rush_yards_over_expected_per_att, na.rm = TRUE),
    rush_pct_over_expected = mean(rush_pct_over_expected, na.rm = TRUE),
    .groups = 'drop'
  )

# Aggregate and join NextGen receiving stats for WRs and TEs
nextgen_receiving_agg <- nextgen_receiving %>%
  group_by(player_display_name, recent_team, season) %>%
  summarise(
    avg_cushion = mean(avg_cushion, na.rm = TRUE),
    avg_separation = mean(avg_separation, na.rm = TRUE),
    rec_avg_intended_air_yards = mean(avg_intended_air_yards, na.rm = TRUE),
    percent_share_of_intended_air_yards = mean(percent_share_of_intended_air_yards, na.rm = TRUE),
    catch_percentage = mean(catch_percentage, na.rm = TRUE),
    .groups = 'drop'
  )

# Join NextGen stats to player stats
season_stats_with_nextgen <- season_stats %>%
  # Join passing NextGen stats for QBs
  left_join(
    nextgen_passing_agg,
    by = c("player_display_name", "recent_team", "season")
  ) %>%
  # Join rushing NextGen stats for RBs 
  left_join(
    nextgen_rushing_agg,
    by = c("player_display_name", "recent_team", "season")
  ) %>%
  # Join receiving NextGen stats for WRs and TEs
  left_join(
    nextgen_receiving_agg,
    by = c("player_display_name", "recent_team", "season")
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
    player_id, player_name, player_display_name, position, season, recent_team, games,
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
    fantasy_points, fantasy_points_ppr,
    # NextGen Passing
    avg_time_to_throw, avg_completed_air_yards, avg_intended_air_yards,
    avg_air_yards_differential, aggressiveness, max_completed_air_distance,
    avg_air_distance, avg_air_yards_to_sticks, completion_percentage_above_expectation,
    # NextGen Rushing
    rush_efficiency, pct_attempts_vs_eight_plus, avg_time_to_los, rush_yards_over_expected,
    rush_yards_over_expected_per_att, rush_pct_over_expected,
    # NextGen Receiving
    avg_cushion, avg_separation, rec_avg_intended_air_yards, percent_share_of_intended_air_yards,
    catch_percentage
  ) %>%
  # Replace NaN with 0 for cleaner JSON
  mutate_if(is.numeric, ~replace(., is.nan(.), 0)) %>%
  mutate_if(is.numeric, ~replace(., is.na(.), 0))


cat("Processed data. Found", nrow(season_stats_with_nextgen), "aggregated player-season records with NextGen stats.\n")


# 3. EXPORT TO JSON
# ------------------------------------------------
# Define the output file path. This will be created in the same directory where the script is run.
output_file <- "player_stats.json"

# Convert the data frame to a JSON array format and write to file
# auto_unbox = TRUE makes single values not be in an array in JSON
json_data <- toJSON(season_stats_with_nextgen, pretty = TRUE, auto_unbox = TRUE)
write(json_data, file = output_file)

cat("Successfully exported data to", output_file, "\n")
cat("You can now use the 'upload_player_stats.js' script to upload this file to Firestore.\n") 
