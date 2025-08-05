#!/usr/bin/env Rscript

# Load required libraries
suppressPackageStartupMessages({
  library(nflreadr)
  library(dplyr)
  library(jsonlite)
})

cat("🏈 Starting game logs generation...\n")

# Define output files
output_dir <- "assets/data"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

game_logs_csv <- file.path(output_dir, "player_game_logs.csv")

cat("📊 Loading weekly player stats for 2024 season...\n")

tryCatch({
  # Load weekly stats for 2024 (default is offense which includes weekly data)
  weekly_stats <- load_player_stats(seasons = 2024)
  
  if (nrow(weekly_stats) > 0) {
    cat("✅ Loaded", nrow(weekly_stats), "weekly stat records\n")
    
    # Process game logs
    game_logs <- weekly_stats %>%
      filter(!is.na(player_id), !is.na(player_name)) %>%
      filter(season_type == "REG") %>%  # Regular season only
      select(
        player_id,
        player_name,
        player_display_name,
        position,
        position_group,
        recent_team,
        season,
        week,
        opponent_team,
        # Passing stats
        completions, attempts, passing_yards, passing_tds, interceptions,
        # Rushing stats  
        carries, rushing_yards, rushing_tds,
        # Receiving stats
        receptions, targets, receiving_yards, receiving_tds,
        # Fantasy stats
        fantasy_points_ppr
      ) %>%
      # Calculate total TDs and add games column
      mutate(
        total_tds = coalesce(passing_tds, 0) + coalesce(rushing_tds, 0) + coalesce(receiving_tds, 0),
        games = 1  # Each row is one game
      ) %>%
      # Rename team column for consistency
      rename(team = recent_team) %>%
      # Replace NA values with 0 for numeric columns
      mutate(across(where(is.numeric), ~coalesce(.x, 0))) %>%
      # Filter to players with meaningful stats
      filter(
        fantasy_points_ppr > 0 | 
        attempts > 0 | 
        carries > 0 | 
        targets > 0
      ) %>%
      # Sort by player and week
      arrange(player_id, week)
    
    cat("💾 Exporting game logs to CSV...\n")
    write.csv(game_logs, game_logs_csv, row.names = FALSE)
    
    cat("✅ Game logs export complete!\n")
    cat("📄 File saved as:", game_logs_csv, "\n")
    cat("📊 Total game records:", nrow(game_logs), "\n")
    cat("🏈 Unique players:", length(unique(game_logs$player_id)), "\n")
    cat("📅 Weeks covered:", min(game_logs$week, na.rm = TRUE), "-", max(game_logs$week, na.rm = TRUE), "\n")
    
    # Show sample of data
    cat("\n📋 Sample game log data:\n")
    sample_data <- game_logs %>%
      filter(fantasy_points_ppr > 15) %>%
      arrange(desc(fantasy_points_ppr)) %>%
      head(5) %>%
      select(player_name, position, week, opponent_team, fantasy_points_ppr, passing_yards, rushing_yards, receiving_yards)
    
    print(sample_data)
    
  } else {
    cat("❌ No weekly stats data found!\n")
  }
  
}, error = function(e) {
  cat("❌ Error loading weekly stats:", e$message, "\n")
})

cat("\n🎯 Game logs generation complete!\n")