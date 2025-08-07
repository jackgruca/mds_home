# Check what columns are available in nflreadr player stats data
library(nflreadr)
library(dplyr)

cat("Loading NFL player stats data to check available columns...\n")
player_stats <- nflreadr::load_player_stats(seasons = 2024)

cat("Available columns:\n")
print(names(player_stats))

cat("\nFirst few rows:\n")
print(head(player_stats, 3))

cat("\nColumn types:\n")
print(str(player_stats))