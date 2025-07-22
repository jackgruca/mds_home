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
    target_share = mean(target_share, na.rm = TRUE),
    air_yards_share = mean(air_yards_share, na.rm = TRUE),

    # Fantasy Points
    fantasy_points = sum(fantasy_points, na.rm = TRUE),
    fantasy_points_ppr = sum(fantasy_points_ppr, na.rm = TRUE),

    .groups = 'drop'
  )

# Aggregate and join NextGen passing stats for QBs
nextgen_passing_agg <- nextgen_passing %>%
  group_by(player_display_name, recent_team, season) %>%
  summarise(
    avg_time_to_throw = as.numeric(mean(avg_time_to_throw, na.rm = TRUE)),
    avg_completed_air_yards = as.numeric(mean(avg_completed_air_yards, na.rm = TRUE)),
    avg_intended_air_yards = as.numeric(mean(avg_intended_air_yards, na.rm = TRUE)),
    avg_air_yards_differential = as.numeric(mean(avg_air_yards_differential, na.rm = TRUE)),
    aggressiveness = as.numeric(mean(aggressiveness, na.rm = TRUE)),
    max_completed_air_distance = as.numeric(max(max_completed_air_distance, na.rm = TRUE)),
    avg_air_distance = as.numeric(mean(avg_air_distance, na.rm = TRUE)),
    avg_air_yards_to_sticks = as.numeric(mean(avg_air_yards_to_sticks, na.rm = TRUE)),
    completion_percentage_above_expectation = as.numeric(mean(completion_percentage_above_expectation, na.rm = TRUE)),
    .groups = 'drop'
  )

# Aggregate and join NextGen rushing stats for RBs
nextgen_rushing_agg <- nextgen_rushing %>%
  group_by(player_display_name, recent_team, season) %>%
  summarise(
    rush_efficiency = as.numeric(mean(efficiency, na.rm = TRUE)),
    avg_time_to_los = as.numeric(mean(avg_time_to_los, na.rm = TRUE)),
    rush_yards_over_expected = as.numeric(mean(rush_yards_over_expected, na.rm = TRUE)),
    rush_yards_over_expected_per_att = as.numeric(mean(rush_yards_over_expected_per_att, na.rm = TRUE)),
    rush_pct_over_expected = as.numeric(mean(rush_pct_over_expected, na.rm = TRUE)),
    .groups = 'drop'
  )

# Aggregate and join NextGen receiving stats for WRs and TEs
nextgen_receiving_agg <- nextgen_receiving %>%
  group_by(player_display_name, recent_team, season) %>%
  summarise(
    avg_cushion = as.numeric(mean(avg_cushion, na.rm = TRUE)),
    avg_separation = as.numeric(mean(avg_separation, na.rm = TRUE)),
    rec_avg_intended_air_yards = as.numeric(mean(avg_intended_air_yards, na.rm = TRUE)),
    percent_share_of_intended_air_yards = as.numeric(mean(percent_share_of_intended_air_yards, na.rm = TRUE)),
    catch_percentage = as.numeric(mean(catch_percentage, na.rm = TRUE)),
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
    # Passing efficiency metrics
    completion_percentage = as.numeric(ifelse(attempts > 0, (completions / attempts) * 100, 0)),
    passing_yards_per_attempt = as.numeric(ifelse(attempts > 0, passing_yards / attempts, 0)),
    passing_tds_per_attempt = as.numeric(ifelse(attempts > 0, passing_tds / attempts, 0)),
    
    # Calculate passer rating using NFL formula
    passer_rating = as.numeric(ifelse(attempts > 0, {
      a = pmax(0, pmin(2.375, (completion_percentage/100 - 0.3) * 5))
      b = pmax(0, pmin(2.375, (passing_yards_per_attempt - 3) * 0.25))
      c = pmax(0, pmin(2.375, (passing_tds / attempts) * 20))
      d = pmax(0, pmin(2.375, 2.375 - (interceptions / attempts) * 25))
      ((a + b + c + d) / 6) * 100
    }, 0)),
    
    # Rushing efficiency metrics
    yards_per_carry = as.numeric(ifelse(rushing_attempts > 0, rushing_yards / rushing_attempts, 0)),
    rushing_yards_per_attempt = as.numeric(ifelse(rushing_attempts > 0, rushing_yards / rushing_attempts, 0)),
    rushing_tds_per_attempt = as.numeric(ifelse(rushing_attempts > 0, rushing_tds / rushing_attempts, 0)),
    
    # Receiving efficiency metrics  
    yards_per_reception = as.numeric(ifelse(receptions > 0, receiving_yards / receptions, 0)),
    receiving_tds_per_reception = as.numeric(ifelse(receptions > 0, receiving_tds / receptions, 0)),
    catch_percentage = as.numeric(ifelse(targets > 0, (receptions / targets) * 100, 0)),  # Our calculated catch rate
    
    # Fantasy metrics
    fantasy_points_per_game = as.numeric(ifelse(games > 0, fantasy_points / games, 0)),
    fantasy_points_ppr_per_game = as.numeric(ifelse(games > 0, fantasy_points_ppr / games, 0)),
    
    # Advanced receiving metrics - ensure proper data types
    target_share = as.numeric(ifelse(is.finite(target_share) & !is.na(target_share), target_share * 100, 0)),  # Convert to percentage
    air_yards_share = as.numeric(ifelse(is.finite(air_yards_share) & !is.na(air_yards_share), air_yards_share * 100, 0)),  # Convert to percentage
    avg_depth_of_target = as.numeric(ifelse(targets > 0, receiving_yards / targets, 0)), # Approximation
    racr = as.numeric(ifelse(rec_avg_intended_air_yards > 0, receiving_yards / rec_avg_intended_air_yards, 0)),
    
    # Multi-purpose metrics
    yards_per_touch = as.numeric(ifelse((rushing_attempts + receptions) > 0, (rushing_yards + receiving_yards) / (rushing_attempts + receptions), 0)),
    
    # Ensure NextGen stats are proper doubles and handle NaN/Inf values
    avg_time_to_throw = as.numeric(ifelse(is.finite(avg_time_to_throw), avg_time_to_throw, 0)),
    avg_completed_air_yards = as.numeric(ifelse(is.finite(avg_completed_air_yards), avg_completed_air_yards, 0)),
    avg_intended_air_yards = as.numeric(ifelse(is.finite(avg_intended_air_yards), avg_intended_air_yards, 0)),
    avg_air_yards_differential = as.numeric(ifelse(is.finite(avg_air_yards_differential), avg_air_yards_differential, 0)),
    aggressiveness = as.numeric(ifelse(is.finite(aggressiveness), aggressiveness, 0)),
    max_completed_air_distance = as.numeric(ifelse(is.finite(max_completed_air_distance), max_completed_air_distance, 0)),
    avg_air_distance = as.numeric(ifelse(is.finite(avg_air_distance), avg_air_distance, 0)),
    avg_air_yards_to_sticks = as.numeric(ifelse(is.finite(avg_air_yards_to_sticks), avg_air_yards_to_sticks, 0)),
    completion_percentage_above_expectation = as.numeric(ifelse(is.finite(completion_percentage_above_expectation), completion_percentage_above_expectation, 0)),
    rush_efficiency = as.numeric(ifelse(is.finite(rush_efficiency), rush_efficiency, 0)),
    avg_time_to_los = as.numeric(ifelse(is.finite(avg_time_to_los), avg_time_to_los, 0)),
    rush_yards_over_expected = as.numeric(ifelse(is.finite(rush_yards_over_expected), rush_yards_over_expected, 0)),
    rush_yards_over_expected_per_att = as.numeric(ifelse(is.finite(rush_yards_over_expected_per_att), rush_yards_over_expected_per_att, 0)),
    rush_pct_over_expected = as.numeric(ifelse(is.finite(rush_pct_over_expected), rush_pct_over_expected * 100, 0)),  # Convert from decimal to percentage
    avg_cushion = as.numeric(ifelse(is.finite(avg_cushion), avg_cushion, 0)),
    avg_separation = as.numeric(ifelse(is.finite(avg_separation), avg_separation, 0)),
    rec_avg_intended_air_yards = as.numeric(ifelse(is.finite(rec_avg_intended_air_yards), rec_avg_intended_air_yards, 0)),
    percent_share_of_intended_air_yards = as.numeric(ifelse(is.finite(percent_share_of_intended_air_yards), percent_share_of_intended_air_yards, 0))
  ) %>%
  # Add lowercase player name for search functionality
  mutate(
    player_display_name_lower = tolower(player_display_name)
  ) %>%
  # Select and reorder columns for clarity
  select(
    # Identifiers
    player_id, player_name, player_display_name, player_display_name_lower, position, season, recent_team, games,
    # Passing
    completions, attempts, passing_yards, passing_tds, interceptions, sacks, sack_yards,
    completion_percentage, passer_rating, passing_yards_per_attempt, passing_tds_per_attempt,
    # Rushing
    rushing_attempts, rushing_yards, rushing_tds,
    yards_per_carry, rushing_yards_per_attempt, rushing_tds_per_attempt,
    # Receiving
    receptions, targets, receiving_yards, receiving_tds,
    yards_per_reception, receiving_tds_per_reception, catch_percentage,
    # Advanced receiving
    air_yards_share, avg_depth_of_target, racr, wopr, target_share,
    # Multi-purpose
    yards_per_touch,
    # Fantasy
    fantasy_points, fantasy_points_ppr, fantasy_points_per_game, fantasy_points_ppr_per_game,
    # NextGen Passing
    avg_time_to_throw, avg_completed_air_yards, avg_intended_air_yards,
    avg_air_yards_differential, aggressiveness, max_completed_air_distance,
    avg_air_distance, avg_air_yards_to_sticks, completion_percentage_above_expectation,
    # NextGen Rushing
    rush_efficiency, avg_time_to_los, rush_yards_over_expected,
    rush_yards_over_expected_per_att, rush_pct_over_expected,
    # NextGen Receiving
    avg_cushion, avg_separation, rec_avg_intended_air_yards, percent_share_of_intended_air_yards
  ) %>%
  # Final cleanup - ensure all numeric columns are proper doubles
  mutate_if(is.numeric, ~as.numeric(.)) %>%
  mutate_if(is.numeric, ~replace(., is.nan(.), 0)) %>%
  mutate_if(is.numeric, ~replace(., is.na(.), 0)) %>%
  mutate_if(is.numeric, ~replace(., is.infinite(.), 0))


cat("Processed data. Found", nrow(season_stats_with_nextgen), "aggregated player-season records with NextGen stats.\n")


# 3. EXPORT TO JSON
# ------------------------------------------------
# Define the output file path. This will be created in the same directory where the script is run.
output_file <- "player_stats.json"

# Convert the data frame to a JSON array format and write to file
# auto_unbox = TRUE makes single values not be in an array in JSON
# digits = 4 ensures proper decimal precision
json_data <- toJSON(season_stats_with_nextgen, pretty = TRUE, auto_unbox = TRUE, digits = 4)
write(json_data, file = output_file)

cat("Successfully exported data to", output_file, "\n")
cat("You can now use the 'upload_player_stats.js' script to upload this file to Firestore.\n") 
