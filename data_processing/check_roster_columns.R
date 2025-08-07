# Check what columns are available in nflreadr roster data
library(nflreadr)
library(dplyr)

cat("Loading NFL roster data to check available columns...\n")
roster_data <- nflreadr::load_rosters(seasons = 2024)

cat("Available columns:\n")
print(names(roster_data))

cat("\nFirst few rows:\n")
print(head(roster_data, 3))

cat("\nColumn types:\n")
print(str(roster_data))