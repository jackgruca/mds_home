#!/usr/bin/env Rscript

# Load required libraries
library(nflreadr)
library(dplyr)
library(readr)

cat("🏈 Starting weekly passing NGS data generation...\n")

# Load weekly passing NGS data from nflreadr
cat("📊 Loading weekly passing NGS data from nflreadr...\n")
weekly_passing_ngs <- load_nextgen_stats(stat_type = "passing", seasons = 2024)

cat("✅ Loaded", nrow(weekly_passing_ngs), "weekly passing NGS records\n")
cat("📋 Columns available:", paste(names(weekly_passing_ngs), collapse = ", "), "\n")

# Display sample data
cat("📊 Sample data (first 3 rows):\n")
print(head(weekly_passing_ngs, 3))

# Clean and standardize the data
cat("🔧 Processing and cleaning passing NGS data...\n")

weekly_passing_clean <- weekly_passing_ngs %>%
  # Standardize column names to match our existing structure
  select(
    season,
    week,
    player_id = player_gsis_id,
    player_display_name,
    team = team_abbr,
    # Passing NGS metrics
    avg_time_to_throw,
    avg_completed_air_yards,
    avg_intended_air_yards,
    completion_percentage_above_expectation,
    aggressiveness,
    max_completed_air_distance,
    # Traditional passing stats that come with NGS data
    attempts,
    completions,
    passing_yards = pass_yards,
    passing_tds = pass_touchdowns,
    interceptions
  ) %>%
  # Add stat_type column to match our existing NGS structure
  mutate(
    stat_type = "passing",
    # Ensure player_id is character type
    player_id = as.character(player_id)
  ) %>%
  # Filter out Week 0 and invalid weeks
  filter(week > 0 & week <= 18) %>%
  # Remove rows with no meaningful data
  filter(!is.na(player_id) & !is.na(player_display_name)) %>%
  # Sort by player, season, week
  arrange(player_id, season, week)

cat("✅ Processed", nrow(weekly_passing_clean), "clean passing NGS records\n")

# Check for any QBs in the data
sample_players <- weekly_passing_clean %>% 
  distinct(player_display_name, player_id) %>% 
  head(10)

cat("👤 Sample QB players in data:\n")
print(sample_players)

# Save to CSV file
output_file <- "data_processing/assets/data/player_weekly_passing_ngs.csv"
cat("💾 Saving to", output_file, "...\n")

write_csv(weekly_passing_clean, output_file)

cat("✅ Weekly passing NGS data generation complete!\n")
cat("📁 File saved:", output_file, "\n")
cat("📊 Total records:", nrow(weekly_passing_clean), "\n")

# Display summary statistics
cat("\n📈 Summary by week:\n")
weekly_summary <- weekly_passing_clean %>%
  group_by(week) %>%
  summarise(
    players = n_distinct(player_id),
    records = n(),
    avg_time_to_throw = round(mean(avg_time_to_throw, na.rm = TRUE), 2),
    avg_completion_pct_above_exp = round(mean(completion_percentage_above_expectation, na.rm = TRUE), 2),
    .groups = 'drop'
  )
print(weekly_summary)

cat("\n🎉 Passing NGS data ready for integration!\n")