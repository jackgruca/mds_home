# Generate weekly EPA and NGS data for advanced stats tab
library(nflreadr)
library(tidyverse)
library(dplyr)

cat("===========================================\n")
cat("GENERATING WEEKLY ADVANCED STATS DATA\n")
cat("===========================================\n\n")

# Get current season
current_year <- as.numeric(format(Sys.Date(), "%Y"))
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
    .groups = 'drop'
  ) %>%
  rename(
    player_id = passer_player_id,
    player_name = passer_player_name,
    team = posteam,
    opponent = defteam
  )

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
    .groups = 'drop'
  ) %>%
  rename(
    player_id = rusher_player_id,
    player_name = rusher_player_name,
    team = posteam,
    opponent = defteam
  )

# Receiving EPA by week
weekly_epa_receiving <- pbp_data %>%
  filter(!is.na(receiver_player_id), pass == 1, complete_pass == 1, !is.na(epa)) %>%
  group_by(season, week, game_id, receiver_player_id, receiver_player_name, posteam, defteam) %>%
  summarise(
    receiving_plays = n(),
    receiving_epa_total = round(sum(epa, na.rm = TRUE), 2),
    receiving_epa_per_play = round(mean(epa, na.rm = TRUE), 3),
    receptions = n(),
    targets = sum(!is.na(receiver_player_id)),
    receiving_yards = sum(receiving_yards, na.rm = TRUE),
    receiving_tds = sum(pass_touchdown, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  rename(
    player_id = receiver_player_id,
    player_name = receiver_player_name,
    team = posteam,
    opponent = defteam
  )

# Combine all EPA types
weekly_epa_all <- bind_rows(
  weekly_epa_passing %>% mutate(stat_type = "passing"),
  weekly_epa_rushing %>% mutate(stat_type = "rushing"),
  weekly_epa_receiving %>% mutate(stat_type = "receiving")
) %>%
  arrange(player_id, week)

# 2. Load Next Gen Stats by week
cat("\nLoading weekly Next Gen Stats...\n")

# Weekly NGS Passing
weekly_ngs_passing <- data.frame()  # Initialize empty
tryCatch({
  ngs_pass_raw <- load_nextgen_stats(seasons = current_season, stat_type = "passing")
  cat("Raw NGS Passing columns:", paste(colnames(ngs_pass_raw), collapse=", "), "\n")
  
  # Only select columns that exist
  weekly_ngs_passing <- ngs_pass_raw %>%
    filter(season_type == "REG") %>%
    rename(player_id = player_gsis_id) %>%
    mutate(stat_type = "passing") %>%
    select(any_of(c(
      "season", "week", "player_id", "player_display_name", "team_abbr",
      "avg_time_to_throw", "avg_completed_air_yards", "avg_intended_air_yards",
      "completion_percentage_above_expectation", "aggressiveness", 
      "max_completed_air_distance", "attempts", "completions", "passing_yards",
      "pass_touchdowns", "interceptions", "stat_type"
    )))
  
  if("team_abbr" %in% colnames(weekly_ngs_passing)) {
    weekly_ngs_passing <- weekly_ngs_passing %>% rename(team = team_abbr)
  }
  
  cat("Weekly NGS Passing: ", nrow(weekly_ngs_passing), " records\n")
}, error = function(e) {
  cat("Error loading passing NGS:", e$message, "\n")
})

# Weekly NGS Rushing
tryCatch({
  weekly_ngs_rushing <- load_nextgen_stats(seasons = current_season, stat_type = "rushing") %>%
    filter(season_type == "REG") %>%
    rename(player_id = player_gsis_id) %>%
    mutate(stat_type = "rushing") %>%
    select(
      season, week, player_id, player_display_name, team = team_abbr,
      efficiency, percent_attempts_gte_eight_defenders, avg_time_to_los,
      expected_rush_yards, rush_yards_over_expected, rush_pct_over_expected,
      rush_attempts, rush_yards, rush_touchdowns, stat_type
    )
  cat("Weekly NGS Rushing: ", nrow(weekly_ngs_rushing), " records\n")
}, error = function(e) {
  cat("Error loading rushing NGS:", e$message, "\n")
  weekly_ngs_rushing <- data.frame()
})

# Weekly NGS Receiving
tryCatch({
  weekly_ngs_receiving <- load_nextgen_stats(seasons = current_season, stat_type = "receiving") %>%
    filter(season_type == "REG") %>%
    rename(player_id = player_gsis_id) %>%
    mutate(stat_type = "receiving") %>%
    select(
      season, week, player_id, player_display_name, team = team_abbr,
      avg_cushion, avg_separation, avg_intended_air_yards,
      percent_share_of_intended_air_yards, catch_percentage,
      avg_yac, avg_expected_yac, avg_yac_above_expectation,
      targets, receptions, yards, rec_touchdowns, stat_type
    )
  cat("Weekly NGS Receiving: ", nrow(weekly_ngs_receiving), " records\n")
}, error = function(e) {
  cat("Error loading receiving NGS:", e$message, "\n")
  weekly_ngs_receiving <- data.frame()
})

# Combine all NGS types
weekly_ngs_all <- bind_rows(
  if(exists("weekly_ngs_passing") && nrow(weekly_ngs_passing) > 0) weekly_ngs_passing else NULL,
  if(exists("weekly_ngs_rushing") && nrow(weekly_ngs_rushing) > 0) weekly_ngs_rushing else NULL,
  if(exists("weekly_ngs_receiving") && nrow(weekly_ngs_receiving) > 0) weekly_ngs_receiving else NULL
) %>%
  arrange(player_id, week)

# 3. Get schedules for opponent info
schedules <- load_schedules(current_season) %>%
  select(season, week, home_team, away_team, game_id)

# 4. Export files
cat("\nExporting weekly advanced stats CSV files...\n")

# Add path to assets directory
output_path <- "assets/data/"

# Export weekly EPA
write.csv(weekly_epa_all, paste0(output_path, "player_weekly_epa.csv"), row.names = FALSE)

# Export weekly NGS
if(exists("weekly_ngs_all") && nrow(weekly_ngs_all) > 0) {
  write.csv(weekly_ngs_all, paste0(output_path, "player_weekly_ngs.csv"), row.names = FALSE)
}

# Create season summary for EPA (for the expandable header)
season_epa_summary <- weekly_epa_all %>%
  group_by(player_id, player_name, season, stat_type) %>%
  summarise(
    games = n_distinct(week),
    total_plays = sum(coalesce(passing_plays, rushing_plays, receiving_plays, 0)),
    total_epa = sum(coalesce(passing_epa_total, rushing_epa_total, receiving_epa_total, 0)),
    avg_epa_per_play = mean(coalesce(passing_epa_per_play, rushing_epa_per_play, receiving_epa_per_play, 0)),
    .groups = 'drop'
  )

write.csv(season_epa_summary, paste0(output_path, "player_season_epa_summary.csv"), row.names = FALSE)

# Create season summary for NGS
if(exists("weekly_ngs_all") && nrow(weekly_ngs_all) > 0) {
  # Separate summaries by stat type to avoid column conflicts
  ngs_passing_summary <- weekly_ngs_all %>%
    filter(stat_type == "passing") %>%
    group_by(player_id, player_display_name, season, stat_type) %>%
    summarise(
      games = n_distinct(week),
      avg_time_to_throw = mean(avg_time_to_throw, na.rm = TRUE),
      avg_cpoe = mean(completion_percentage_above_expectation, na.rm = TRUE),
      avg_aggressiveness = mean(aggressiveness, na.rm = TRUE),
      .groups = 'drop'
    )
  
  ngs_rushing_summary <- weekly_ngs_all %>%
    filter(stat_type == "rushing") %>%
    group_by(player_id, player_display_name, season, stat_type) %>%
    summarise(
      games = n_distinct(week),
      avg_efficiency = mean(efficiency, na.rm = TRUE),
      total_ryoe = sum(rush_yards_over_expected, na.rm = TRUE),
      avg_ryoe = mean(rush_yards_over_expected, na.rm = TRUE),
      .groups = 'drop'
    )
  
  ngs_receiving_summary <- weekly_ngs_all %>%
    filter(stat_type == "receiving") %>%
    group_by(player_id, player_display_name, season, stat_type) %>%
    summarise(
      games = n_distinct(week),
      avg_separation = mean(avg_separation, na.rm = TRUE),
      avg_yac_above_exp = mean(avg_yac_above_expectation, na.rm = TRUE),
      .groups = 'drop'
    )
  
  season_ngs_summary <- bind_rows(
    if(nrow(ngs_passing_summary) > 0) ngs_passing_summary else NULL,
    if(nrow(ngs_rushing_summary) > 0) ngs_rushing_summary else NULL,
    if(nrow(ngs_receiving_summary) > 0) ngs_receiving_summary else NULL
  )
  
  write.csv(season_ngs_summary, paste0(output_path, "player_season_ngs_summary.csv"), row.names = FALSE)
}

cat("\n===========================================\n")
cat("✅ WEEKLY ADVANCED STATS GENERATED!\n")
cat("===========================================\n")
cat("Files created:\n")
cat("- player_weekly_epa.csv (", nrow(weekly_epa_all), " records)\n", sep = "")
if(exists("weekly_ngs_all") && nrow(weekly_ngs_all) > 0) {
  cat("- player_weekly_ngs.csv (", nrow(weekly_ngs_all), " records)\n", sep = "")
}
cat("- player_season_epa_summary.csv\n")
if(exists("season_ngs_summary")) {
  cat("- player_season_ngs_summary.csv\n")
}
cat("\nReady for Flutter integration!\n")