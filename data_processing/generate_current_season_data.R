# Quick script to generate only current season player data
# Use this for faster development and testing

library(nflreadr)
library(tidyverse)
library(dplyr)

cat("===========================================\n")
cat("GENERATING CURRENT SEASON PLAYER DATA\n")
cat("===========================================\n\n")

# Get current season - for 2025, we need to use 2024 data
current_year <- as.numeric(format(Sys.Date(), "%Y"))
# Since we're in 2025 and the 2025 season hasn't started yet, use 2024
current_season <- 2024

cat("Fetching data for", current_season, "season...\n\n")

# 1. Load current roster
cat("Loading roster data...\n")
roster_data <- load_rosters(seasons = current_season) %>%
  filter(!is.na(full_name), !is.na(team), !is.na(position)) %>%
  mutate(
    position_group = case_when(
      position %in% c("QB") ~ "QB",
      position %in% c("RB", "FB") ~ "RB",
      position %in% c("WR") ~ "WR", 
      position %in% c("TE") ~ "TE",
      position %in% c("T", "G", "C", "OT", "OG") ~ "OL",
      position %in% c("DE", "DT", "NT") ~ "DL",
      position %in% c("OLB", "ILB", "LB", "MLB") ~ "LB",
      position %in% c("CB", "S", "FS", "SS", "DB") ~ "DB",
      position %in% c("K") ~ "K",
      position %in% c("P") ~ "P",
      position %in% c("LS") ~ "LS",
      TRUE ~ "Other"
    )
  ) %>%
  select(
    player_id = gsis_id,
    full_name,
    position,
    position_group,
    team,
    any_of(c("jersey_number", "height", "weight", "age", "years_exp", "status", "college"))
  )

# 2. Load play-by-play data for EPA calculations
cat("Loading play-by-play data for EPA calculations...\n")
pbp_data <- load_pbp(seasons = current_season) %>%
  filter(season_type == "REG", !is.na(epa))

# Calculate EPA stats by player
cat("Calculating EPA metrics...\n")
epa_passing <- pbp_data %>%
  filter(!is.na(passer_player_id), pass == 1, !is.na(epa)) %>%
  group_by(passer_player_id, passer_player_name) %>%
  summarise(
    passing_epa_total = round(sum(epa, na.rm = TRUE), 2),
    passing_epa_per_play = round(mean(epa, na.rm = TRUE), 3),
    passing_plays = n(),
    .groups = 'drop'
  )

epa_rushing <- pbp_data %>%
  filter(!is.na(rusher_player_id), rush == 1, !is.na(epa)) %>%
  group_by(rusher_player_id, rusher_player_name) %>%
  summarise(
    rushing_epa_total = round(sum(epa, na.rm = TRUE), 2),
    rushing_epa_per_play = round(mean(epa, na.rm = TRUE), 3),
    rushing_plays = n(),
    .groups = 'drop'
  )

epa_receiving <- pbp_data %>%
  filter(!is.na(receiver_player_id), pass == 1, complete_pass == 1, !is.na(epa)) %>%
  group_by(receiver_player_id, receiver_player_name) %>%
  summarise(
    receiving_epa_total = round(sum(epa, na.rm = TRUE), 2),
    receiving_epa_per_play = round(mean(epa, na.rm = TRUE), 3),
    receiving_plays = n(),
    .groups = 'drop'
  )

# Load Next Gen Stats
cat("Loading Next Gen Stats...\n")
tryCatch({
  ngs_passing <- load_nextgen_stats(seasons = current_season, stat_type = "passing") %>%
    filter(season_type == "REG") %>%
    group_by(player_gsis_id, player_display_name) %>%
    summarise(
      avg_time_to_throw = mean(avg_time_to_throw, na.rm = TRUE),
      avg_completed_air_yards = mean(avg_completed_air_yards, na.rm = TRUE),
      avg_intended_air_yards = mean(avg_intended_air_yards, na.rm = TRUE),
      completion_percentage_above_expectation = mean(completion_percentage_above_expectation, na.rm = TRUE),
      aggressiveness = mean(aggressiveness, na.rm = TRUE),
      max_completed_air_distance = max(max_completed_air_distance, na.rm = TRUE),
      .groups = 'drop'
    )
  cat("NGS Passing: ", nrow(ngs_passing), " players\n")
}, error = function(e) {
  cat("Error loading passing NGS:", e$message, "\n")
  ngs_passing <- data.frame(player_gsis_id = character(0))
})

tryCatch({
  ngs_rushing <- load_nextgen_stats(seasons = current_season, stat_type = "rushing") %>%
    filter(season_type == "REG") %>%
    group_by(player_gsis_id, player_display_name) %>%
    summarise(
      efficiency = mean(efficiency, na.rm = TRUE),
      percent_attempts_gte_eight_defenders = mean(percent_attempts_gte_eight_defenders, na.rm = TRUE),
      avg_time_to_los = mean(avg_time_to_los, na.rm = TRUE),
      expected_rush_yards = sum(expected_rush_yards, na.rm = TRUE),
      rush_yards_over_expected = sum(rush_yards_over_expected, na.rm = TRUE),
      rush_pct_over_expected = mean(rush_pct_over_expected, na.rm = TRUE),
      .groups = 'drop'
    )
  cat("NGS Rushing: ", nrow(ngs_rushing), " players\n")
}, error = function(e) {
  cat("Error loading rushing NGS:", e$message, "\n")
  ngs_rushing <- data.frame(player_gsis_id = character(0))
})

tryCatch({
  ngs_receiving <- load_nextgen_stats(seasons = current_season, stat_type = "receiving") %>%
    filter(season_type == "REG") %>%
    group_by(player_gsis_id, player_display_name) %>%
    summarise(
      avg_cushion = mean(avg_cushion, na.rm = TRUE),
      avg_separation = mean(avg_separation, na.rm = TRUE),
      avg_intended_air_yards = mean(avg_intended_air_yards, na.rm = TRUE),
      percent_share_of_intended_air_yards = mean(percent_share_of_intended_air_yards, na.rm = TRUE),
      catch_percentage = mean(catch_percentage, na.rm = TRUE),
      avg_yac = mean(avg_yac, na.rm = TRUE),
      avg_expected_yac = mean(avg_expected_yac, na.rm = TRUE),
      avg_yac_above_expectation = mean(avg_yac_above_expectation, na.rm = TRUE),
      .groups = 'drop'
    )
  cat("NGS Receiving: ", nrow(ngs_receiving), " players\n")
}, error = function(e) {
  cat("Error loading receiving NGS:", e$message, "\n")
  ngs_receiving <- data.frame(player_gsis_id = character(0))
})

# 3. Load current season stats
cat("Loading season stats...\n")
season_stats <- load_player_stats(seasons = current_season, stat_type = "offense") %>%
  filter(position %in% c('QB', 'RB', 'WR', 'TE')) %>%
  group_by(player_id, player_name, player_display_name, position, recent_team) %>%
  summarise(
    games = n_distinct(week),
    # Passing
    completions = sum(completions, na.rm = TRUE),
    attempts = sum(attempts, na.rm = TRUE),
    passing_yards = sum(passing_yards, na.rm = TRUE),
    passing_tds = sum(passing_tds, na.rm = TRUE),
    interceptions = sum(interceptions, na.rm = TRUE),
    # Rushing
    carries = sum(carries, na.rm = TRUE),
    rushing_yards = sum(rushing_yards, na.rm = TRUE),
    rushing_tds = sum(rushing_tds, na.rm = TRUE),
    # Receiving
    receptions = sum(receptions, na.rm = TRUE),
    targets = sum(targets, na.rm = TRUE),
    receiving_yards = sum(receiving_yards, na.rm = TRUE),
    receiving_tds = sum(receiving_tds, na.rm = TRUE),
    # Fantasy
    fantasy_points_ppr = sum(fantasy_points_ppr, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  # Join EPA data
  left_join(epa_passing, by = c("player_id" = "passer_player_id")) %>%
  left_join(epa_rushing, by = c("player_id" = "rusher_player_id")) %>%
  left_join(epa_receiving, by = c("player_id" = "receiver_player_id")) %>%
  # Join NGS data
  left_join(ngs_passing, by = c("player_id" = "player_gsis_id")) %>%
  left_join(ngs_rushing, by = c("player_id" = "player_gsis_id")) %>%
  left_join(ngs_receiving, by = c("player_id" = "player_gsis_id")) %>%
  mutate(
    # Calculate per-game averages
    fantasy_ppg = round(fantasy_points_ppr / games, 1),
    pass_ypg = round(passing_yards / games, 1),
    rush_ypg = round(rushing_yards / games, 1),
    rec_ypg = round(receiving_yards / games, 1),
    # Total TDs
    total_tds = passing_tds + rushing_tds + receiving_tds,
    # Fill missing EPA values with 0
    passing_epa_total = coalesce(passing_epa_total, 0),
    passing_epa_per_play = coalesce(passing_epa_per_play, 0),
    passing_plays = coalesce(passing_plays, 0),
    rushing_epa_total = coalesce(rushing_epa_total, 0),
    rushing_epa_per_play = coalesce(rushing_epa_per_play, 0),
    rushing_plays = coalesce(rushing_plays, 0),
    receiving_epa_total = coalesce(receiving_epa_total, 0),
    receiving_epa_per_play = coalesce(receiving_epa_per_play, 0),
    receiving_plays = coalesce(receiving_plays, 0),
    # Calculate total EPA across all play types
    total_epa = passing_epa_total + rushing_epa_total + receiving_epa_total,
    # Fill missing NGS values with 0/NA
    # Passing NGS
    ngs_avg_time_to_throw = coalesce(avg_time_to_throw, 0),
    ngs_avg_completed_air_yards = coalesce(avg_completed_air_yards, 0),
    ngs_avg_intended_air_yards = coalesce(avg_intended_air_yards.x, 0),
    ngs_completion_pct_above_expectation = coalesce(completion_percentage_above_expectation, 0),
    ngs_aggressiveness = coalesce(aggressiveness, 0),
    ngs_max_completed_air_distance = coalesce(max_completed_air_distance, 0),
    # Rushing NGS
    ngs_efficiency = coalesce(efficiency, 0),
    ngs_pct_attempts_gte_eight_defenders = coalesce(percent_attempts_gte_eight_defenders, 0),
    ngs_avg_time_to_los = coalesce(avg_time_to_los, 0),
    ngs_expected_rush_yards = coalesce(expected_rush_yards, 0),
    ngs_rush_yards_over_expected = coalesce(rush_yards_over_expected, 0),
    ngs_rush_pct_above_expectation = coalesce(rush_pct_over_expected, 0),
    # Receiving NGS
    ngs_avg_cushion = coalesce(avg_cushion, 0),
    ngs_avg_separation = coalesce(avg_separation, 0),
    ngs_rec_avg_intended_air_yards = coalesce(avg_intended_air_yards.y, 0),
    ngs_pct_share_intended_air_yards = coalesce(percent_share_of_intended_air_yards, 0),
    ngs_catch_percentage = coalesce(catch_percentage, 0),
    ngs_avg_yac = coalesce(avg_yac, 0),
    ngs_avg_expected_yac = coalesce(avg_expected_yac, 0),
    ngs_avg_yac_above_expectation = coalesce(avg_yac_above_expectation, 0)
  )

# 4. Get most recent week's game logs
cat("Loading recent game logs...\n")
recent_games <- load_player_stats(seasons = current_season, stat_type = "offense") %>%
  filter(
    position %in% c('QB', 'RB', 'WR', 'TE'),
    season_type == "REG"
  ) %>%
  group_by(player_id) %>%
  filter(week == max(week)) %>%
  ungroup() %>%
  select(
    player_id,
    player_name,
    position,
    team = recent_team,
    week,
    # Key stats
    completions, attempts, passing_yards, passing_tds, interceptions,
    carries, rushing_yards, rushing_tds,
    receptions, targets, receiving_yards, receiving_tds,
    fantasy_points_ppr
  )

# 5. Combine into a single current player dataset
cat("Creating combined player dataset...\n")
current_players <- roster_data %>%
  left_join(
    season_stats %>% select(-position, -player_name),
    by = c("player_id", "team" = "recent_team")
  ) %>%
  filter(position_group %in% c("QB", "RB", "WR", "TE")) %>%
  # Fill missing values
  mutate(across(where(is.numeric), ~replace_na(., 0))) %>%
  arrange(team, position_group, desc(fantasy_points_ppr))

# 6. Export files
cat("\nExporting CSV files...\n")

write.csv(current_players, "current_players_combined.csv", row.names = FALSE)
write.csv(recent_games, "recent_game_logs.csv", row.names = FALSE)

# 7. Create a simple team summary
team_summary <- current_players %>%
  group_by(team, position_group) %>%
  summarise(
    player_count = n(),
    top_player = first(full_name),
    top_player_ppg = first(fantasy_ppg),
    .groups = 'drop'
  ) %>%
  pivot_wider(
    names_from = position_group,
    values_from = c(player_count, top_player, top_player_ppg),
    values_fill = list(player_count = 0, top_player = "None", top_player_ppg = 0)
  )

write.csv(team_summary, "team_position_summary.csv", row.names = FALSE)

cat("\n===========================================\n")
cat("✅ CURRENT SEASON DATA GENERATED!\n")
cat("===========================================\n")
cat("Files created:\n")
cat("- current_players_combined.csv (", nrow(current_players), " players)\n", sep = "")
cat("- recent_game_logs.csv (", nrow(recent_games), " game logs)\n", sep = "")
cat("- team_position_summary.csv (", nrow(team_summary), " teams)\n", sep = "")
cat("\nReady for development!\n")