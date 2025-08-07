# Master script to generate all player data CSVs
# This script runs all individual data generation scripts and ensures consistent player IDs

library(tidyverse)

cat("===========================================\n")
cat("GENERATING ALL PLAYER DATA FOR MDS HOME\n")
cat("===========================================\n\n")

# Set working directory to data_processing folder
if (!grepl("data_processing$", getwd())) {
  if (dir.exists("data_processing")) {
    setwd("data_processing")
  }
}

# 1. Generate roster data
cat("Step 1: Generating roster data...\n")
source("get_roster_data.R")
cat("\n")

# 2. Generate season stats
cat("Step 2: Generating season stats...\n")
source("get_player_season_stats.R")
cat("\n")

# 3. Generate game logs
cat("Step 3: Generating game logs...\n")
source("get_player_game_logs.R")
cat("\n")

# 4. Create a player ID mapping file for consistent lookups
cat("Step 4: Creating player ID mapping...\n")

# Read the generated CSVs
roster_df <- read.csv("player_roster_info.csv", stringsAsFactors = FALSE)
stats_df <- read.csv("player_season_stats.csv", stringsAsFactors = FALSE)
logs_df <- read.csv("player_game_logs.csv", stringsAsFactors = FALSE)

# Create a comprehensive player mapping
player_mapping <- roster_df %>%
  select(player_id, full_name, position, team) %>%
  distinct() %>%
  # Add player_name variations from stats
  left_join(
    stats_df %>%
      select(player_id, player_display_name) %>%
      distinct(),
    by = "player_id"
  ) %>%
  # Ensure we have the most recent team for each player
  group_by(player_id) %>%
  arrange(desc(player_id)) %>%
  slice(1) %>%
  ungroup() %>%
  # Create search-friendly fields
  mutate(
    search_name = tolower(gsub("[^a-zA-Z0-9 ]", "", full_name)),
    name_parts = strsplit(full_name, " "),
    first_name = sapply(name_parts, function(x) if(length(x) > 0) x[1] else ""),
    last_name = sapply(name_parts, function(x) if(length(x) > 1) paste(x[-1], collapse = " ") else "")
  ) %>%
  select(-name_parts)

# Write the mapping file
write.csv(player_mapping, "player_id_mapping.csv", row.names = FALSE)
cat("✅ Player ID mapping created with", nrow(player_mapping), "unique players\n")

# 5. Create a current season roster file for quick lookups
cat("\nStep 5: Creating current season roster...\n")

current_season <- max(roster_df$season)
current_roster <- roster_df %>%
  filter(season == current_season) %>%
  arrange(team, position, full_name)

write.csv(current_roster, "current_season_roster.csv", row.names = FALSE)
cat("✅ Current season roster created with", nrow(current_roster), "players\n")

# 6. Summary report
cat("\n===========================================\n")
cat("DATA GENERATION COMPLETE!\n")
cat("===========================================\n")
cat("Files created:\n")
cat("- player_roster_info.csv (", nrow(roster_df), " rows)\n", sep = "")
cat("- player_season_stats.csv (", nrow(stats_df), " rows)\n", sep = "")
cat("- player_game_logs.csv (", nrow(logs_df), " rows)\n", sep = "")
cat("- player_id_mapping.csv (", nrow(player_mapping), " unique players)\n", sep = "")
cat("- current_season_roster.csv (", nrow(current_roster), " current players)\n", sep = "")
cat("\nAll CSV files are ready for use in the MDS Home app!\n")