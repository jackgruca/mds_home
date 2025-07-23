# data_processing/get_draft_picks.R

# 1. SETUP
# ------------------------------------------------
# Install packages if you don't have them
# install.packages("nflreadr")
# install.packages("tidyverse")
# install.packages("jsonlite")

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)
library(dplyr)

cat("Loaded libraries: nflreadr, tidyverse, jsonlite\n")

# Define the last 15 years of draft data to load
current_year <- as.numeric(format(Sys.Date(), "%Y"))
draft_years <- (current_year - 14):current_year  # Last 15 years (2010-2024 if current year is 2024)

cat("Fetching NFL draft picks for years:", paste(draft_years, collapse=", "), "\n")

# 2. DATA FETCHING AND CLEANING
# ------------------------------------------------
# Load draft picks data from nflreadr
cat("Loading draft picks data...\n")
draft_picks <- nflreadr::load_draft_picks(seasons = draft_years)

cat("Successfully downloaded", nrow(draft_picks), "draft pick records.\n")
print(paste("Columns available:", paste(names(draft_picks), collapse=", ")))
print(dim(draft_picks))

# Clean and process the data
draft_picks_cleaned <- draft_picks %>%
  # Filter out rows with missing essential data
  filter(
    !is.na(season) & 
    !is.na(round) & 
    !is.na(pick) & 
    !is.na(pfr_player_name)
  ) %>%
  # Select and rename columns for consistency
  select(
    year = season,
    round = round,
    pick = pick,
    player = pfr_player_name,
    position = position,
    school = college,
    team = team
  ) %>%
  # Clean up the data
  mutate(
    # Ensure proper data types
    year = as.integer(year),
    round = as.integer(round),
    pick = as.integer(pick),
    player = as.character(player),
    position = as.character(position),
    school = as.character(school),
    team = as.character(team),
    
    # Handle missing values
    position = ifelse(is.na(position) | position == "", "Unknown", position),
    school = ifelse(is.na(school) | school == "", "Unknown", school),
    team = ifelse(is.na(team) | team == "", "Unknown", team),
    
    # Create a unique ID for each pick
    pick_id = paste(year, round, pick, sep = "_"),
    
    # Add timestamp for when data was processed
    last_updated = Sys.time()
  ) %>%
  # Sort by year (newest first), then round, then pick
  arrange(desc(year), round, pick)

cat("Processed data. Found", nrow(draft_picks_cleaned), "draft pick records.\n")

# Display summary statistics
cat("\n--- DATA SUMMARY ---\n")
cat("Years covered:", min(draft_picks_cleaned$year), "to", max(draft_picks_cleaned$year), "\n")
cat("Total picks:", nrow(draft_picks_cleaned), "\n")
cat("Picks per year:", round(nrow(draft_picks_cleaned) / length(unique(draft_picks_cleaned$year)), 1), "\n")

# Show breakdown by position
position_summary <- draft_picks_cleaned %>%
  count(position, sort = TRUE) %>%
  head(10)
cat("\nTop 10 positions drafted:\n")
print(position_summary)

# Show sample of recent picks
cat("\nSample of most recent picks:\n")
recent_picks <- draft_picks_cleaned %>%
  filter(year == max(year)) %>%
  head(10) %>%
  select(year, round, pick, player, position, school, team)
print(recent_picks)

# 3. EXPORT TO JSON
# ------------------------------------------------
# Define the output file path
output_file <- "draft_picks.json"

# Convert the data frame to a JSON array format and write to file
# Remove the last_updated timestamp column for JSON export (keep as character for consistency)
export_data <- draft_picks_cleaned %>%
  mutate(last_updated = as.character(last_updated))

json_data <- toJSON(export_data, pretty = TRUE, auto_unbox = TRUE, digits = 4)
write(json_data, file = output_file)

cat("\n--- EXPORT COMPLETE ---\n")
cat("Successfully exported", nrow(export_data), "draft pick records to", output_file, "\n")
cat("File size:", round(file.size(output_file) / 1024 / 1024, 2), "MB\n")
cat("You can now use the 'upload_draft_picks.js' script to upload this file to Firestore.\n")

# 4. DATA VALIDATION
# ------------------------------------------------
cat("\n--- DATA VALIDATION ---\n")

# Check for any duplicates
duplicates <- draft_picks_cleaned %>%
  group_by(year, round, pick) %>%
  filter(n() > 1)

if (nrow(duplicates) > 0) {
  cat("WARNING: Found", nrow(duplicates), "duplicate picks:\n")
  print(duplicates)
} else {
  cat("✅ No duplicate picks found\n")
}

# Check for missing essential data
missing_players <- sum(is.na(draft_picks_cleaned$player) | draft_picks_cleaned$player == "")
missing_teams <- sum(is.na(draft_picks_cleaned$team) | draft_picks_cleaned$team == "")

cat("Missing player names:", missing_players, "\n")
cat("Missing team assignments:", missing_teams, "\n")

# Validate pick numbers make sense
invalid_picks <- draft_picks_cleaned %>%
  filter(pick < 1 | pick > 300 | round < 1 | round > 10)

if (nrow(invalid_picks) > 0) {
  cat("WARNING: Found", nrow(invalid_picks), "picks with invalid round/pick numbers:\n")
  print(invalid_picks)
} else {
  cat("✅ All pick numbers appear valid\n")
}

cat("\n--- SCRIPT COMPLETE ---\n")