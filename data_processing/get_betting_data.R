# data_processing/get_betting_data.R

# 1. SETUP
# ------------------------------------------------
# Install packages if you don't have them
install.packages(c("nflreadr", "tidyverse", "jsonlite"))

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)
library(dplyr)

cat("Loaded libraries: nflreadr, tidyverse, jsonlite\n")

# Define seasons to load. Let's grab the last 5 years of data as a starting point.
current_year <- as.numeric(format(Sys.Date(), "%Y"))
seasons_to_load <- (current_year - 5):(current_year - 1)

cat("Fetching historical game data for seasons:", paste(seasons_to_load, collapse=", "), "\n")

# 2. DATA FETCHING AND CLEANING
# ------------------------------------------------
# Load schedules data from nflreadr - this contains games, betting lines, weather, etc.
schedules <- nflreadr::load_schedules(seasons = seasons_to_load)

cat("Successfully downloaded", nrow(schedules), "games.\n")
print(dim(schedules))

# Clean and process the data
# Focus on completed games only (exclude future games with NA scores)
historical_games <- schedules %>%
  filter(!is.na(away_score) & !is.na(home_score)) %>%
  mutate(
    # Basic game info
    game_date = as.Date(gameday),
    game_datetime = paste(gameday, gametime),
    total_points = away_score + home_score,
    point_differential = abs(away_score - home_score),
    
    # Game outcome classifications
    blowout = ifelse(point_differential >= 21, 1, 0),
    close_game = ifelse(point_differential <= 3, 1, 0),
    high_scoring = ifelse(total_points >= 50, 1, 0),
    low_scoring = ifelse(total_points <= 30, 1, 0),
    
    # Weather classifications
    cold_weather = ifelse(!is.na(temp) & temp <= 32, 1, 0),
    hot_weather = ifelse(!is.na(temp) & temp >= 85, 1, 0),
    windy_conditions = ifelse(!is.na(wind) & wind >= 15, 1, 0),
    dome_game = ifelse(roof %in% c("dome", "closed"), 1, 0),
    outdoor_game = ifelse(roof == "outdoors", 1, 0),
    
    # Betting outcome analysis
    favorite_covered = case_when(
      spread_line > 0 & (home_score - away_score) > spread_line ~ 1,  # Home favored and covered
      spread_line < 0 & (away_score - home_score) > abs(spread_line) ~ 1,  # Away favored and covered
      spread_line == 0 ~ 0,  # Pick'em game
      TRUE ~ 0  # Favorite didn't cover
    ),
    
    over_hit = ifelse(!is.na(total_line) & total_points > total_line, 1, 0),
    under_hit = ifelse(!is.na(total_line) & total_points < total_line, 1, 0),
    total_push = ifelse(!is.na(total_line) & total_points == total_line, 1, 0),
    
    # Rest advantage
    rest_advantage = abs(away_rest - home_rest),
    away_rest_advantage = ifelse(away_rest > home_rest, 1, 0),
    home_rest_advantage = ifelse(home_rest > away_rest, 1, 0),
    
    # Prime time games
    prime_time = case_when(
      weekday == "Sunday" & gametime >= "20:00" ~ 1,
      weekday == "Monday" ~ 1,
      weekday == "Thursday" ~ 1,
      weekday == "Friday" ~ 1,
      weekday == "Saturday" ~ 1,
      TRUE ~ 0
    ),
    
    # Season context
    early_season = ifelse(week <= 6, 1, 0),
    mid_season = ifelse(week >= 7 & week <= 12, 1, 0),
    late_season = ifelse(week >= 13, 1, 0),
    playoff_game = ifelse(game_type %in% c("WC", "DIV", "CON", "SB"), 1, 0)
  ) %>%
  # Select key columns for the historical games dataset
  select(
    # Game identifiers
    game_id, season, week, game_type, game_date, weekday, gametime, prime_time,
    
    # Teams and scores
    away_team, away_score, home_team, home_score, 
    total_points, point_differential, result, overtime,
    
    # Game classifications
    blowout, close_game, high_scoring, low_scoring, div_game, playoff_game,
    early_season, mid_season, late_season,
    
    # Betting lines and outcomes
    away_moneyline, home_moneyline, spread_line, away_spread_odds, home_spread_odds,
    total_line, under_odds, over_odds,
    favorite_covered, over_hit, under_hit, total_push,
    
    # Weather and venue
    stadium, stadium_id, roof, surface, temp, wind,
    cold_weather, hot_weather, windy_conditions, dome_game, outdoor_game,
    
    # Team context
    away_rest, home_rest, rest_advantage, away_rest_advantage, home_rest_advantage,
    away_qb_name, home_qb_name, away_coach, home_coach, referee,
    
    # External IDs for reference
    old_game_id, espn, pfr
  ) %>%
  # Replace NaN and infinite values with appropriate defaults
  mutate_if(is.numeric, ~replace(., is.nan(.), 0)) %>%
  mutate_if(is.numeric, ~replace(., is.infinite(.), 0)) %>%
  mutate_if(is.numeric, ~replace(., is.na(.), 0)) %>%
  # Replace character NAs with empty strings for cleaner JSON
  mutate_if(is.character, ~replace(., is.na(.), "")) %>%
  # Sort by most recent games first
  arrange(desc(game_date), desc(gametime))

cat("Processed data. Found", nrow(historical_games), "completed historical games.\n")

# Print some summary statistics
cat("\n--- SUMMARY STATISTICS ---\n")
cat("Total games:", nrow(historical_games), "\n")
cat("Seasons covered:", paste(unique(historical_games$season), collapse=", "), "\n")
cat("Game types:", paste(unique(historical_games$game_type), collapse=", "), "\n")
cat("Teams:", length(unique(c(historical_games$away_team, historical_games$home_team))), "\n")
cat("Venues:", length(unique(historical_games$stadium)), "\n")
cat("Prime time games:", sum(historical_games$prime_time), "\n")
cat("Playoff games:", sum(historical_games$playoff_game), "\n")
cat("Overtime games:", sum(historical_games$overtime), "\n")
cat("Games with weather data:", sum(!is.na(schedules$temp) & !is.na(schedules$wind)), "\n")
cat("Games with betting lines:", sum(!is.na(historical_games$spread_line)), "\n")
cat("-------------------------\n")

# 3. EXPORT TO JSON
# ------------------------------------------------
# Define the output file path
output_file <- "betting_data.json"

# Convert the data frame to a JSON array format and write to file
json_data <- toJSON(historical_games, pretty = TRUE, auto_unbox = TRUE)
write(json_data, file = output_file)

cat("Successfully exported data to", output_file, "\n")
cat("You can now use the 'upload_betting_data.js' script to upload this file to Firestore.\n") 