# Generate weekly EPA data for advanced stats tab
library(nflreadr)
library(tidyverse)
library(dplyr)

cat("===========================================\n")
cat("GENERATING WEEKLY EPA STATS DATA\n")
cat("===========================================\n\n")

# Get current season
current_season <- 2024

cat("Generating data for", current_season, "season...\n\n")

# 1. Load play-by-play data for EPA calculations
cat("Loading play-by-play data for weekly EPA...\n")
pbp_data <- load_pbp(seasons = current_season) %>%
  filter(season_type == "REG", !is.na(epa))

# Calculate weekly EPA stats by player
cat("Calculating weekly EPA metrics...\n")

# Passing EPA by week
weekly_epa_passing <- pbp_data %>%
  filter(!is.na(passer_player_id), pass == 1, !is.na(epa)) %>%
  group_by(season, week, game_id, passer_player_id, passer_player_name, posteam, defteam) %>%
  summarise(
    passing_plays = n(),
    passing_epa_total = round(sum(epa, na.rm = TRUE), 2),
    passing_epa_per_play = round(mean(epa, na.rm = TRUE), 3),
    completions = sum(complete_pass, na.rm = TRUE),
    attempts = sum(pass_attempt, na.rm = TRUE),
    passing_yards = sum(passing_yards, na.rm = TRUE),
    passing_tds = sum(pass_touchdown, na.rm = TRUE),
    interceptions = sum(interception, na.rm = TRUE),
    sacks = sum(sack, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  rename(
    player_id = passer_player_id,
    player_name = passer_player_name,
    team = posteam,
    opponent = defteam
  ) %>%
  mutate(stat_type = "passing")

# Rushing EPA by week
weekly_epa_rushing <- pbp_data %>%
  filter(!is.na(rusher_player_id), rush == 1, !is.na(epa)) %>%
  group_by(season, week, game_id, rusher_player_id, rusher_player_name, posteam, defteam) %>%
  summarise(
    rushing_plays = n(),
    rushing_epa_total = round(sum(epa, na.rm = TRUE), 2),
    rushing_epa_per_play = round(mean(epa, na.rm = TRUE), 3),
    carries = n(),
    rushing_yards = sum(rushing_yards, na.rm = TRUE),
    rushing_tds = sum(rush_touchdown, na.rm = TRUE),
    rushing_first_downs = sum(first_down_rush, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  rename(
    player_id = rusher_player_id,
    player_name = rusher_player_name,
    team = posteam,
    opponent = defteam
  ) %>%
  mutate(stat_type = "rushing")

# Receiving EPA by week  
weekly_epa_receiving <- pbp_data %>%
  filter(!is.na(receiver_player_id), pass == 1, !is.na(epa)) %>%
  group_by(season, week, game_id, receiver_player_id, receiver_player_name, posteam, defteam) %>%
  summarise(
    receiving_plays = n(),
    receiving_epa_total = round(sum(epa[complete_pass == 1], na.rm = TRUE), 2),
    receiving_epa_per_play = round(mean(epa[complete_pass == 1], na.rm = TRUE), 3),
    targets = n(),
    receptions = sum(complete_pass, na.rm = TRUE),
    receiving_yards = sum(receiving_yards, na.rm = TRUE),
    receiving_tds = sum(pass_touchdown & complete_pass, na.rm = TRUE),
    receiving_first_downs = sum(first_down_pass & complete_pass, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  rename(
    player_id = receiver_player_id,
    player_name = receiver_player_name,
    team = posteam,
    opponent = defteam
  ) %>%
  mutate(stat_type = "receiving")

# Combine all EPA types into single rows per player per week
weekly_epa_all <- bind_rows(
  weekly_epa_passing %>% mutate(stat_type = "passing"),
  weekly_epa_rushing %>% mutate(stat_type = "rushing"), 
  weekly_epa_receiving %>% mutate(stat_type = "receiving")
) %>%
  group_by(season, week, game_id, player_id, player_name, team, opponent) %>%
  summarise(
    # Combined EPA totals
    total_plays = sum(c(passing_plays, rushing_plays, receiving_plays), na.rm = TRUE),
    total_epa = sum(c(passing_epa_total, rushing_epa_total, receiving_epa_total), na.rm = TRUE),
    epa_per_play = ifelse(total_plays > 0, total_epa / total_plays, 0),
    
    # Individual EPA by type
    passing_plays = sum(passing_plays, na.rm = TRUE),
    passing_epa_total = sum(passing_epa_total, na.rm = TRUE),
    passing_epa_per_play = ifelse(passing_plays > 0, passing_epa_total / passing_plays, 0),
    
    rushing_plays = sum(rushing_plays, na.rm = TRUE), 
    rushing_epa_total = sum(rushing_epa_total, na.rm = TRUE),
    rushing_epa_per_play = ifelse(rushing_plays > 0, rushing_epa_total / rushing_plays, 0),
    
    receiving_plays = sum(receiving_plays, na.rm = TRUE),
    receiving_epa_total = sum(receiving_epa_total, na.rm = TRUE), 
    receiving_epa_per_play = ifelse(receiving_plays > 0, receiving_epa_total / receiving_plays, 0),
    
    # Traditional stats - take max values to avoid double counting
    completions = max(completions, na.rm = TRUE),
    attempts = max(attempts, na.rm = TRUE),
    passing_yards = max(passing_yards, na.rm = TRUE),
    passing_tds = max(passing_tds, na.rm = TRUE),
    interceptions = max(interceptions, na.rm = TRUE),
    sacks = max(sacks, na.rm = TRUE),
    
    carries = max(carries, na.rm = TRUE),
    rushing_yards = max(rushing_yards, na.rm = TRUE),
    rushing_tds = max(rushing_tds, na.rm = TRUE),
    rushing_first_downs = max(rushing_first_downs, na.rm = TRUE),
    
    targets = max(targets, na.rm = TRUE),
    receptions = max(receptions, na.rm = TRUE),
    receiving_yards = max(receiving_yards, na.rm = TRUE),
    receiving_tds = max(receiving_tds, na.rm = TRUE),
    receiving_first_downs = max(receiving_first_downs, na.rm = TRUE),
    
    .groups = 'drop'
  ) %>%
  # Replace -Inf values with 0
  mutate(across(where(is.numeric), ~ ifelse(is.infinite(.), 0, .))) %>%
  arrange(player_id, week)

# Create season summary for EPA (for the expandable header)
season_epa_summary <- weekly_epa_all %>%
  group_by(player_id, player_name, season) %>%
  summarise(
    games = n_distinct(week),
    # Passing
    passing_plays_total = sum(passing_plays, na.rm = TRUE),
    passing_epa_total = sum(passing_epa_total, na.rm = TRUE),
    passing_epa_avg = round(mean(passing_epa_per_play[passing_plays > 0], na.rm = TRUE), 3),
    # Rushing  
    rushing_plays_total = sum(rushing_plays, na.rm = TRUE),
    rushing_epa_total = sum(rushing_epa_total, na.rm = TRUE),
    rushing_epa_avg = round(mean(rushing_epa_per_play[rushing_plays > 0], na.rm = TRUE), 3),
    # Receiving
    receiving_plays_total = sum(receiving_plays, na.rm = TRUE),
    receiving_epa_total = sum(receiving_epa_total, na.rm = TRUE),
    receiving_epa_avg = round(mean(receiving_epa_per_play[receiving_plays > 0], na.rm = TRUE), 3),
    # Total EPA
    total_epa = round(sum(c(passing_epa_total, rushing_epa_total, receiving_epa_total), na.rm = TRUE), 2),
    .groups = 'drop'
  )

# 4. Export files
cat("\nExporting weekly EPA CSV files...\n")

# Add path to assets directory
output_path <- "assets/data/"

# Export weekly EPA
write.csv(weekly_epa_all, paste0(output_path, "player_weekly_epa.csv"), row.names = FALSE)

# Export season summary
write.csv(season_epa_summary, paste0(output_path, "player_season_epa_summary.csv"), row.names = FALSE)

cat("\n===========================================\n")
cat("✅ WEEKLY EPA STATS GENERATED!\n")
cat("===========================================\n")
cat("Files created:\n")
cat("- player_weekly_epa.csv (", nrow(weekly_epa_all), " records)\n", sep = "")
cat("- player_season_epa_summary.csv (", nrow(season_epa_summary), " players)\n", sep = "")
cat("\nReady for Flutter integration!\n")