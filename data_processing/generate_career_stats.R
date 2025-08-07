#!/usr/bin/env Rscript

# Load required libraries
suppressPackageStartupMessages({
  library(nflreadr)
  library(dplyr)
  library(jsonlite)
})

cat("🏈 Starting career stats generation...\n")

# Define output files
output_dir <- "assets/data"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

career_stats_csv <- file.path(output_dir, "player_career_stats.csv")

cat("📊 Loading player season stats for multiple years...\n")

# Get stats for last 5 seasons (2020-2024)
years <- 2020:2024
all_season_stats <- data.frame()

for (year in years) {
  cat("  Loading", year, "season...\n")
  
  tryCatch({
    # Load season stats
    season_stats <- load_player_stats(seasons = year)
    
    if (nrow(season_stats) > 0) {
      # Add season column
      season_stats$season <- year
      
      # Combine with existing data
      all_season_stats <- bind_rows(all_season_stats, season_stats)
      
      cat("    ✅", nrow(season_stats), "player records for", year, "\n")
    }
  }, error = function(e) {
    cat("    ❌ Error loading", year, ":", e$message, "\n")
  })
}

cat("📈 Processing career statistics...\n")

if (nrow(all_season_stats) > 0) {
  # Get season-level stats by aggregating weekly data
  career_data <- all_season_stats %>%
    filter(!is.na(player_id), !is.na(player_name)) %>%
    filter(season_type == "REG") %>%  # Regular season only
    group_by(player_id, player_name, player_display_name, position, position_group, headshot_url, recent_team, season) %>%
    summarise(
      games = n(),  # Count of games played
      # Passing stats
      completions = sum(completions, na.rm = TRUE),
      attempts = sum(attempts, na.rm = TRUE),
      passing_yards = sum(passing_yards, na.rm = TRUE),
      passing_tds = sum(passing_tds, na.rm = TRUE),
      interceptions = sum(interceptions, na.rm = TRUE),
      # Rushing stats  
      carries = sum(carries, na.rm = TRUE),
      rushing_yards = sum(rushing_yards, na.rm = TRUE),
      rushing_tds = sum(rushing_tds, na.rm = TRUE),
      # Receiving stats
      receptions = sum(receptions, na.rm = TRUE),
      targets = sum(targets, na.rm = TRUE),
      receiving_yards = sum(receiving_yards, na.rm = TRUE),
      receiving_tds = sum(receiving_tds, na.rm = TRUE),
      # Fantasy stats
      fantasy_points_ppr = sum(fantasy_points_ppr, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    # Calculate per-game averages
    mutate(
      fantasy_ppg = ifelse(games > 0, fantasy_points_ppr / games, 0),
      pass_ypg = ifelse(games > 0, passing_yards / games, 0),
      rush_ypg = ifelse(games > 0, rushing_yards / games, 0),
      rec_ypg = ifelse(games > 0, receiving_yards / games, 0),
      total_tds = passing_tds + rushing_tds + receiving_tds
    ) %>%
    # Rename team column for consistency
    rename(team = recent_team) %>%
    # Filter to players with meaningful stats
    filter(
      fantasy_points_ppr > 0 | 
      attempts > 0 | 
      carries > 0 | 
      targets > 0
    )
  
  cat("💾 Exporting career stats to CSV...\n")
  write.csv(career_data, career_stats_csv, row.names = FALSE)
  
  cat("✅ Career stats export complete!\n")
  cat("📄 File saved as:", career_stats_csv, "\n")
  cat("📊 Total records:", nrow(career_data), "\n")
  cat("🏈 Unique players:", length(unique(career_data$player_id)), "\n")
  cat("📅 Seasons covered:", min(career_data$season), "-", max(career_data$season), "\n")
  
  # Show sample of data
  cat("\n📋 Sample career data:\n")
  sample_data <- career_data %>%
    filter(fantasy_points_ppr > 100) %>%
    arrange(desc(fantasy_points_ppr)) %>%
    head(5) %>%
    select(player_name, position, season, games, fantasy_points_ppr, fantasy_ppg)
  
  print(sample_data)
  
} else {
  cat("❌ No career stats data found!\n")
}

cat("\n🎯 Career stats generation complete!\n")