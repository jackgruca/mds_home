# data_processing/get_depth_charts.R

# 1. SETUP
# ------------------------------------------------
# Install packages if you don't have them
# install.packages(c("nflreadr", "tidyverse", "jsonlite"))

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)
library(dplyr)

cat("Loaded libraries: nflreadr, tidyverse, jsonlite\n")

# Define seasons to load - let's get recent years (only through 2024)
current_year <- 2024  # Set to 2024 to avoid trying to load future seasons
seasons_to_load <- (current_year - 3):current_year  # Last 4 seasons: 2021-2024

cat("Fetching depth chart data for seasons:", paste(seasons_to_load, collapse=", "), "\n")

# 2. DATA FETCHING AND CLEANING
# ------------------------------------------------
# Load depth charts data from nflreadr
depth_charts_raw <- nflreadr::load_depth_charts(seasons = seasons_to_load)

cat("Successfully downloaded", nrow(depth_charts_raw), "depth chart records.\n")
print(dim(depth_charts_raw))

# Display available columns to understand the data structure
cat("\nAvailable columns:\n")
print(colnames(depth_charts_raw))

# Display first few rows to understand the data
cat("\nFirst 3 rows:\n")
print(head(depth_charts_raw, 3))

# Clean and process the data
depth_charts_processed <- depth_charts_raw %>%
  # Remove any rows with missing essential data
  filter(!is.na(season) & !is.na(club_code) & !is.na(week)) %>%
  
  # Create additional useful fields
  mutate(
    # Create a unique identifier for each depth chart entry (sanitized for Firestore)
    depth_chart_id = paste(season, club_code, week, game_type, gsis_id, position, depth_position, sep = "_") %>%
      str_replace_all("[^a-zA-Z0-9_-]", "_"),  # Replace any non-alphanumeric chars with underscores
    
    # Clean and standardize names
    display_name = case_when(
      !is.na(football_name) & football_name != "" ~ football_name,
      !is.na(full_name) & full_name != "" ~ full_name,
      !is.na(first_name) & !is.na(last_name) ~ paste(first_name, last_name),
      !is.na(last_name) ~ last_name,
      TRUE ~ "Unknown"
    ),
    
    # Standardize position groups for easier filtering
    position_group = case_when(
      position %in% c("QB") ~ "Quarterback",
      position %in% c("RB", "FB", "HB") ~ "Running Back",
      position %in% c("WR", "FL", "SE") ~ "Wide Receiver", 
      position %in% c("TE", "Y") ~ "Tight End",
      position %in% c("LT", "LG", "C", "RG", "RT", "G", "T", "OL") ~ "Offensive Line",
      position %in% c("DE", "DT", "NT", "DL") ~ "Defensive Line",
      position %in% c("LB", "ILB", "OLB", "MLB") ~ "Linebacker",
      position %in% c("CB", "S", "SS", "FS", "DB") ~ "Defensive Back",
      position %in% c("K") ~ "Kicker",
      position %in% c("P") ~ "Punter",
      position %in% c("LS", "LP") ~ "Long Snapper",
      position %in% c("KR", "PR") ~ "Return Specialist",
      TRUE ~ "Other"
    ),
    
    # Create depth level categories
    depth_level = case_when(
      depth_position == 1 ~ "Starter",
      depth_position == 2 ~ "Backup",
      depth_position == 3 ~ "Third String",
      depth_position >= 4 ~ "Reserve",
      TRUE ~ "Unknown"
    ),
    
    # Season context
    season_week = paste("Week", week),
    season_type_display = case_when(
      game_type == "REG" ~ "Regular Season",
      game_type == "PRE" ~ "Preseason", 
      game_type == "POST" ~ "Playoffs",
      TRUE ~ game_type
    ),
    
    # Team standardization (club_code should already be standardized)
    team = club_code
  ) %>%
  
  # Select and order columns for final dataset
  select(
    # Identifiers
    depth_chart_id, season, week, game_type, season_type_display, season_week,
    
    # Team and player info
    team, club_code, depth_team,
    
    # Player details
    gsis_id, elias_id, jersey_number, 
    display_name, first_name, last_name, football_name, full_name,
    
    # Position info
    position, position_group, formation, depth_position, depth_level,
    
    # Additional context would go here if we had injury status, etc.
  ) %>%
  
  # Replace NaN and infinite values with appropriate defaults
  mutate_if(is.numeric, ~replace(., is.nan(.), 0)) %>%
  mutate_if(is.numeric, ~replace(., is.infinite(.), 0)) %>%
  mutate_if(is.numeric, ~replace(., is.na(.), 0)) %>%
  
  # Replace character NAs with empty strings for cleaner JSON
  mutate_if(is.character, ~replace(., is.na(.), "")) %>%
  
  # Sort by most recent first, then by team, position, and depth
  arrange(desc(season), desc(week), team, position_group, position, depth_position, display_name)

cat("Processed data. Found", nrow(depth_charts_processed), "depth chart entries.\n")

# Print some summary statistics
cat("\n--- SUMMARY STATISTICS ---\n")
cat("Total depth chart entries:", nrow(depth_charts_processed), "\n")
cat("Seasons covered:", paste(unique(depth_charts_processed$season), collapse=", "), "\n")
cat("Teams:", length(unique(depth_charts_processed$team)), "\n")
cat("Unique players:", length(unique(depth_charts_processed$gsis_id[depth_charts_processed$gsis_id != ""])), "\n")
cat("Position groups:", paste(unique(depth_charts_processed$position_group), collapse=", "), "\n")
cat("Game types:", paste(unique(depth_charts_processed$game_type), collapse=", "), "\n")

# Position breakdown
position_summary <- depth_charts_processed %>%
  count(position_group, position, sort = TRUE)
cat("\nPosition breakdown:\n")
print(position_summary)

# Team breakdown by season
team_season_summary <- depth_charts_processed %>%
  count(season, team, sort = TRUE) %>%
  group_by(season) %>%
  summarise(teams = n(), .groups = 'drop')
cat("\nTeam coverage by season:\n")
print(team_season_summary)

cat("-------------------------\n")

# 3. EXPORT TO JSON
# ------------------------------------------------
# Define the output file path
output_file <- "depth_charts.json"

# Convert the data frame to a JSON array format and write to file
json_data <- toJSON(depth_charts_processed, pretty = TRUE, auto_unbox = TRUE)
write(json_data, file = output_file)

cat("Successfully exported data to", output_file, "\n")
cat("File size:", round(file.size(output_file) / 1024 / 1024, 2), "MB\n")
cat("You can now use the 'upload_depth_charts.js' script to upload this file to Firestore.\n") 