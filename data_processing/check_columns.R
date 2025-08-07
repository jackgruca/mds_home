#!/usr/bin/env Rscript

# Load required libraries
suppressPackageStartupMessages({
  library(nflreadr)
  library(dplyr)
})

# Load a sample to check column names
season_stats <- load_player_stats(seasons = 2024)

cat("Available columns in player stats:\n")
print(colnames(season_stats))

cat("\nFirst few rows:\n")
print(head(season_stats[1:10], 3))