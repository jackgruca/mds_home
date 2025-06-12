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
seasons_to_load <- 2021:nflreadr::most_recent_season()

cat("Fetching player stats for seasons:", paste(seasons_to_load, collapse=", "), "\n")

# 2. DATA FETCHING
# ------------------------------------------------
cat("-> Fetching seasonal player stats...\n")
player_stats <- nflreadr::load_player_stats(seasons = seasons_to_load, stat_type = "offense")

cat("-> Fetching player metadata (for joins)...\n")
players <- nflreadr::load_players()

cat("-> Fetching combine data...\n")
combine <- nflreadr::load_combine()

cat("-> Fetching draft picks...\n")
draft_picks <- nflreadr::load_draft_picks()

cat("-> Fetching weekly data (for share calculations)...\n")
weekly_stats <- nflreadr::load_player_stats(seasons = seasons_to_load, stat_type = "offense") %>% 
  filter(week > 0)

cat("-> Fetching Next Gen Stats (Passing)...\n")
ngs_pass <- nflreadr::load_nextgen_stats(seasons = seasons_to_load, stat_type = "passing")

cat("-> Fetching Next Gen Stats (Receiving)...\n")
ngs_receive <- nflreadr::load_nextgen_stats(seasons = seasons_to_load, stat_type = "receiving")

cat("Data fetching complete.\n")

# 3. DATA PROCESSING & MERGING
# ------------------------------------------------
cat("Starting data processing and merging...\n")

# --- Calculate Team Shares ---
team_shares <- weekly_stats %>%
  group_by(season, recent_team) %>%
  summarise(
    team_pass_attempts = sum(attempts, na.rm = TRUE),
    team_rush_attempts = sum(carries, na.rm = TRUE),
    team_targets = sum(targets, na.rm = TRUE),
    .groups = 'drop'
  )

# --- Aggregate Seasonal Stats ---
seasonal_agg <- player_stats %>%
  group_by(player_id, player_name, position, season, recent_team) %>%
  summarise(
    games = n_distinct(week),
    # Passing
    completions = sum(completions, na.rm = TRUE),
    attempts = sum(attempts, na.rm = TRUE),
    passing_yards = sum(passing_yards, na.rm = TRUE),
    passing_tds = sum(passing_tds, na.rm = TRUE),
    interceptions = sum(interceptions, na.rm = TRUE),
    sacks = sum(sacks, na.rm = TRUE),
    # Rushing
    rushing_attempts = sum(carries, na.rm = TRUE),
    rushing_yards = sum(rushing_yards, na.rm = TRUE),
    rushing_tds = sum(rushing_tds, na.rm = TRUE),
    # Receiving
    receptions = sum(receptions, na.rm = TRUE),
    targets = sum(targets, na.rm = TRUE),
    receiving_yards = sum(receiving_yards, na.rm = TRUE),
    receiving_tds = sum(receiving_tds, na.rm = TRUE),
    # Fantasy
    fantasy_points = sum(fantasy_points, na.rm = TRUE),
    fantasy_points_ppr = sum(fantasy_points_ppr, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  # Key Fix: Rename player_id to gsis_id for joining with other data sources
  rename(player_gsis_id = player_id)

# --- Process Optional Data with Error Handling ---

# Initialize empty dataframes for our optional data
combine_info_mapped <- data.frame()
ngs_pass_agg <- data.frame()
ngs_receive_agg <- data.frame()
player_info_to_join <- data.frame()

# --- Try to process Player Info ---
tryCatch({
    cat("Attempting to process player info (height, weight, etc.)...\n")
    required_cols <- c("gsis_id", "display_name", "entry_year", "draft_number", "college_name", "position", "height", "weight")
    
    if (!all(required_cols %in% colnames(players))) {
      stop("Players data from nflreadr is missing required columns for the Player Info block.")
    }

    player_info_to_join <- players %>%
      select(all_of(required_cols)) %>%
      rename(player_gsis_id = gsis_id)
      
    cat("-> Successfully processed player info.\n")
}, error = function(e) {
    cat("--> WARNING: Could not process player info. Skipping. Error: ", e$message, "\n")
})

# --- Try to process Combine data ---
tryCatch({
  cat("Attempting to process combine data...\n")

  if (!"pfr_id" %in% colnames(players) || !"gsis_id" %in% colnames(players)) {
    stop("Cannot map combine stats without 'pfr_id' and 'gsis_id' in the 'players' data.")
  }

  combine_cols_desired <- c("pfr_id", "forty_yd", "vertical_jump", "broad_jump", "cone", "shuttle")
  combine_cols_available <- intersect(combine_cols_desired, colnames(combine))
  
  if (length(combine_cols_available) <= 1) stop("Not enough combine columns found.")

  combine_info <- combine %>% select(all_of(combine_cols_available))
  id_map <- players %>% select(gsis_id, pfr_id) %>% drop_na()

  combine_info_mapped <- combine_info %>%
    left_join(id_map, by = "pfr_id") %>%
    select(-pfr_id) %>%
    rename(player_gsis_id = gsis_id)
  
  cat("-> Successfully processed combine data.\n")
}, error = function(e) {
  cat("--> WARNING: Could not process combine data. Skipping. Error: ", e$message, "\n")
})


# --- Try to process NGS passing data ---
tryCatch({
  cat("Attempting to process NGS passing data...\n")
  required_cols <- c("season", "player_gsis_id", "avg_intended_air_yards", "aggressiveness", "completion_percentage_above_expectation")
  if (!all(required_cols %in% colnames(ngs_pass))) {
    stop("NGS passing data missing required columns.")
  }

  ngs_pass_agg <- ngs_pass %>%
    group_by(season, player_gsis_id) %>%
    summarise(
      avg_intended_air_yards = mean(avg_intended_air_yards, na.rm = TRUE),
      aggressiveness = mean(aggressiveness, na.rm = TRUE),
      completion_percentage_above_expectation = mean(completion_percentage_above_expectation, na.rm = TRUE),
      .groups = 'drop'
    )
  cat("-> Successfully processed NGS passing data.\n")
}, error = function(e) {
  cat("--> WARNING: Could not process NGS passing data. Skipping. Error: ", e$message, "\n")
})

# --- Try to process NGS receiving data ---
tryCatch({
  cat("Attempting to process NGS receiving data...\n")
  required_cols <- c("season", "player_gsis_id", "avg_cushion", "avg_separation", "avg_yac_above_expectation")
  if (!all(required_cols %in% colnames(ngs_receive))) {
    stop("NGS receiving data missing required columns.")
  }

  ngs_receive_agg <- ngs_receive %>%
    group_by(season, player_gsis_id) %>%
    summarise(
      avg_cushion = mean(avg_cushion, na.rm = TRUE),
      avg_separation = mean(avg_separation, na.rm = TRUE),
      avg_yac_above_expectation = mean(avg_yac_above_expectation, na.rm = TRUE),
      .groups = 'drop'
    )
  cat("-> Successfully processed NGS receiving data.\n")
}, error = function(e) {
  cat("--> WARNING: Could not process NGS receiving data. Skipping. Error: ", e$message, "\n")
})

# --- FINAL JOIN ---
cat("Performing final joins...\n")

final_data <- seasonal_agg %>%
  left_join(team_shares, by = c("season", "recent_team"))

# Safely join optional data only if it was successfully processed
if(nrow(player_info_to_join) > 0) {
  final_data <- final_data %>% left_join(player_info_to_join, by = "player_gsis_id", suffix = c("", ".roster"))
}
if(nrow(combine_info_mapped) > 0) {
  final_data <- final_data %>% left_join(combine_info_mapped, by = "player_gsis_id")
}
if(nrow(ngs_pass_agg) > 0) {
  final_data <- final_data %>% left_join(ngs_pass_agg, by = c("season", "player_gsis_id"))
}
if(nrow(ngs_receive_agg) > 0) {
  final_data <- final_data %>% left_join(ngs_receive_agg, by = c("season", "player_gsis_id"))
}

# --- CALCULATE NEW FIELDS ---
final_data <- final_data %>%
  mutate(
    # Safely calculate years_experience only if entry_year column exists
    years_experience = if("entry_year" %in% colnames(.)) season - entry_year else NA_integer_,
    target_share = if("team_targets" %in% colnames(.) & "targets" %in% colnames(.)) ifelse(team_targets > 0, targets / team_targets, 0) else NA_real_,
    rush_share = if("team_rush_attempts" %in% colnames(.) & "rushing_attempts" %in% colnames(.)) ifelse(team_rush_attempts > 0, rushing_attempts / team_rush_attempts, 0) else NA_real_,
    team_position_rank = NA
  )

# --- ADD CUSTOM TIER LOGIC (USER ACTION REQUIRED) ---
cat("Populating custom tiers...\n")
# This is where you should insert your proprietary logic for tiering.
# The columns 'qb_tier', 'offense_tier', etc. are created here.
final_data <- final_data %>%
  mutate(
    # EXAMPLE: Replace NA with your logic. This is just a sample based on team abbreviations.
    offense_tier = case_when(
      recent_team %in% c("KC", "BUF", "PHI", "MIA", "DET") ~ "Tier 1",
      recent_team %in% c("DAL", "CIN", "SF", "BAL", "JAX") ~ "Tier 2",
      TRUE ~ "Tier 3" # Default tier
    ),
    # Create other tiers here. They will default to NA if not defined.
    # You can load another CSV with your tier data and join it, or use more complex case_when() logic.
    qb_tier = NA,
    pass_offense_tier = NA,
    rush_offense_tier = NA,
    defense_vs_tier = NA # Note: this may require joining against a game/schedule dataset.
  )

# --- Final Column Selection ---
# Dynamically select all available columns for the final output
final_cols_desired <- c(
    "player_id", "player_name", "position", "season", "recent_team",
    # Basic Info
    "games", "years_experience", "college_name", "height", "weight", "draft_number",
    # Passing Stats
    "completions", "attempts", "passing_yards", "passing_tds", "interceptions",
    # Rushing Stats
    "rushing_attempts", "rushing_yards", "rushing_tds",
    # Receiving Stats
    "receptions", "targets", "receiving_yards", "receiving_tds",
    # Advanced / NGS
    "target_share", "rush_share", "completion_percentage_above_expectation", "avg_yac_above_expectation", "avg_cushion", "avg_separation", "aggressiveness", "avg_intended_air_yards",
    # Combine
    "forty_yd", "vertical_jump", "broad_jump", "cone", "shuttle",
    # Fantasy
    "fantasy_points", "fantasy_points_ppr",
    # Tiers
    "qb_tier", "offense_tier", "pass_offense_tier", "rush_offense_tier", "defense_vs_tier"
)

final_cols_available <- intersect(final_cols_desired, colnames(final_data))
cat("Exporting the following final columns:", paste(final_cols_available, collapse=", "), "\n")
final_data <- final_data %>% select(all_of(final_cols_available))

cat("Data processing complete. Final dataset has", ncol(final_data), "columns.\n")

# 4. EXPORT TO JSON
# ------------------------------------------------
json_output <- toJSON(final_data, pretty = TRUE, auto_unbox = TRUE, na = "null")
output_file <- "player_stats.json"
write(json_output, output_file)

cat("Successfully exported", nrow(final_data), "records to", output_file, "\n")
cat("You can now use the 'upload_player_stats.js' script to upload this file to Firestore.\n") 