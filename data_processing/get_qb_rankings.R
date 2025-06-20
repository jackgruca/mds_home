# data_processing/get_qb_rankings.R

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

# Define seasons to load - getting comprehensive historical data
seasons_to_load <- 2016:2024

cat("Fetching play-by-play data for QB rankings for seasons:", paste(seasons_to_load, collapse=", "), "\n")

# 2. DATA FETCHING
# ------------------------------------------------
# Load play-by-play data from nflreadr for multiple seasons
cat("Loading play-by-play data...\n")
pbp_data <- nflreadr::load_pbp(seasons = seasons_to_load)

cat("Successfully downloaded", nrow(pbp_data), "plays.\n")
print(dim(pbp_data))

# 3. QB RANKINGS CALCULATION
# ------------------------------------------------
cat("Calculating QB rankings with passing and rushing stats...\n")

# First, calculate passing stats with EARLY minimum pass filter
QB_passing <- pbp_data %>%
  group_by(passer_player_id, posteam, season) %>% 
  filter(season_type == "REG", pass_attempt == 1) %>%
  # Apply minimum pass filter EARLY to ensure even tier distribution
  filter(sum(pass_attempt) >= 100) %>%
  summarise(
    passer_player_name = first(passer_player_name),
    numGames = n_distinct(game_id), 
    numPass = sum(pass_attempt), 
    totalEPA = sum(epa, na.rm = TRUE), 
    totalEP = sum(ep, na.rm = TRUE), 
    avgCPOE = mean(cpoe, na.rm = TRUE), 
    YPG = sum(yards_gained) / n_distinct(game_id), 
    TDperGame = sum(touchdown) / n_distinct(game_id), 
    intPerGame = sum(interception) / n_distinct(game_id), 
    thirdConvert = sum(third_down_converted) / (sum(third_down_converted) + sum(third_down_failed)), 
    actualization = (sum(yards_gained, na.rm = TRUE) / n()) / mean(air_yards, na.rm = TRUE),
    .groups = 'drop'
  ) %>% 
  unique()

# Then, calculate rushing stats for QBs
QB_rushing <- pbp_data %>% 
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>% 
  filter(season_type == "REG") %>%
  summarise(
    rtotalEPA = sum(epa, na.rm = TRUE), 
    rtotalEP = sum(ep, na.rm = TRUE), 
    rYPG = sum(yards_gained) / n_distinct(game_id), 
    rTDperGame = sum(touchdown) / n_distinct(game_id), 
    rthirdConvert = sum(third_down_converted) / (sum(third_down_converted) + sum(third_down_failed)),
    .groups = 'drop'
  ) %>%
  rename(passer_player_id = rusher_player_id, passer_player_name = rusher_player_name)

# Combine passing and rushing stats for INDIVIDUAL QB rankings
QB_ranks <- QB_passing %>%
  left_join(QB_rushing, by = c("passer_player_id", "passer_player_name", "posteam", "season")) %>% 
  group_by(passer_player_id, passer_player_name, posteam, season) %>% 
  summarise(
    numGames = first(numGames),
    numPass = first(numPass),
    ctotalEPA = totalEPA + coalesce(rtotalEPA, 0), 
    ctotalEP = totalEP + coalesce(rtotalEP, 0), 
    cCPOE = first(avgCPOE), 
    cactualization = first(actualization), 
    cYPG = coalesce(rYPG, 0) + YPG, 
    cTDperGame = TDperGame + coalesce(rTDperGame, 0), 
    intPerGame = first(intPerGame), 
    cthirdConvert = mean(c(thirdConvert, coalesce(rthirdConvert, thirdConvert)), na.rm = TRUE),
    .groups = 'drop'
  ) %>% 
  group_by(season) %>% 
  mutate(
    EPA_rank = percent_rank(ctotalEPA), 
    EP_rank = percent_rank(ctotalEP), 
    CPOE_rank = percent_rank(cCPOE), 
    YPG_rank = percent_rank(cYPG), 
    TD_rank = percent_rank(cTDperGame), 
    int_rank = 1 - percent_rank(intPerGame),  # Lower interceptions = better rank
    third_rank = percent_rank(cthirdConvert)
  ) %>%
  mutate(
    myRank = EPA_rank + YPG_rank + TD_rank + third_rank + cactualization
  ) %>%
  group_by(season) %>%
  arrange(desc(myRank)) %>%
  mutate(myRankNum = row_number()) %>%
  mutate(
    qbTier = case_when(
      myRankNum <= 4 ~ 1,
      myRankNum <= 8 ~ 2,
      myRankNum <= 12 ~ 3,
      myRankNum <= 16 ~ 4,
      myRankNum <= 20 ~ 5,
      myRankNum <= 24 ~ 6,
      myRankNum <= 28 ~ 7,
      TRUE ~ 8
    )
  ) %>%
  ungroup() %>%
  # Clean up data and add additional useful fields
  mutate(
    # Round numeric values for cleaner display
    ctotalEPA = round(ctotalEPA, 2),
    ctotalEP = round(ctotalEP, 2),
    cCPOE = round(cCPOE, 3),
    cactualization = round(cactualization, 3),
    cYPG = round(cYPG, 1),
    cTDperGame = round(cTDperGame, 2),
    intPerGame = round(intPerGame, 2),
    cthirdConvert = round(cthirdConvert, 3),
    myRank = round(myRank, 3),
    
    # Add display names and clean up missing values
    player_display_name = passer_player_name,
    team = posteam,
    position = "QB",
    
    # Replace NaN and infinite values
    across(where(is.numeric), ~ifelse(is.nan(.) | is.infinite(.), 0, .))
  ) %>%
  # Filter out players with insufficient data (this filter is now redundant but kept for safety)
  filter(!is.na(passer_player_id), !is.na(passer_player_name)) %>%
  # Select and rename columns for consistency
  select(
    player_id = passer_player_id,
    player_name = passer_player_name,
    player_display_name,
    position,
    team,
    season,
    games = numGames,
    pass_attempts = numPass,
    total_epa = ctotalEPA,
    total_ep = ctotalEP,
    avg_cpoe = cCPOE,
    actualization = cactualization,
    yards_per_game = cYPG,
    tds_per_game = cTDperGame,
    ints_per_game = intPerGame,
    third_down_conversion_rate = cthirdConvert,
    composite_rank_score = myRank,
    rank_number = myRankNum,
    qb_tier = qbTier
  ) %>%
  arrange(season, rank_number)

# 4. TEAM QB TIER CALCULATION
# ------------------------------------------------
cat("Calculating team QB tiers based on games-played weighting...\n")

# Calculate team QB tiers by weighting individual QB tiers by games played
team_qb_rankings <- QB_ranks %>%
  group_by(team, season) %>%
  summarise(
    # Calculate weighted average tier based on games played
    total_games = sum(games),
    weighted_tier_sum = sum(qb_tier * games),
    team_qb_score_raw = weighted_tier_sum / total_games,
    
    # Additional team stats
    primary_qb = first(player_name[which.max(games)]),  # QB who played most games
    primary_qb_games = max(games),
    primary_qb_tier = first(qb_tier[which.max(games)]),
    total_qbs_used = n(),
    
    # Team performance metrics (weighted averages)
    team_total_epa = sum(total_epa * games) / total_games,
    team_yards_per_game = sum(yards_per_game * games) / total_games,
    team_tds_per_game = sum(tds_per_game * games) / total_games,
    team_ints_per_game = sum(ints_per_game * games) / total_games,
    
    .groups = 'drop'
  ) %>%
  # Now rank teams within each season and assign tiers of exactly 4 teams each
  group_by(season) %>%
  arrange(team_qb_score_raw) %>%  # Lower weighted tier score = better (Tier 1 is best)
  mutate(team_rank_number = row_number()) %>%
  mutate(
    # Assign team tiers: exactly 4 teams per tier (1-8)
    team_qb_tier = case_when(
      team_rank_number <= 4 ~ 1,
      team_rank_number <= 8 ~ 2,
      team_rank_number <= 12 ~ 3,
      team_rank_number <= 16 ~ 4,
      team_rank_number <= 20 ~ 5,
      team_rank_number <= 24 ~ 6,
      team_rank_number <= 28 ~ 7,
      TRUE ~ 8  # Teams 29-32
    )
  ) %>%
  ungroup() %>%
  # Clean up numeric values
  mutate(
    team_qb_score_raw = round(team_qb_score_raw, 2),
    team_total_epa = round(team_total_epa, 2),
    team_yards_per_game = round(team_yards_per_game, 1),
    team_tds_per_game = round(team_tds_per_game, 2),
    team_ints_per_game = round(team_ints_per_game, 2)
  ) %>%
  # Select and rename columns for consistency
  select(
    team,
    season,
    team_qb_tier,
    team_rank_number,
    team_qb_score = team_qb_score_raw,
    primary_qb,
    primary_qb_games,
    primary_qb_tier,
    total_qbs_used,
    total_games,
    team_total_epa,
    team_yards_per_game,
    team_tds_per_game,
    team_ints_per_game
  ) %>%
  arrange(season, team_qb_tier, team_qb_score)

cat("Processed team QB tiers. Found", nrow(team_qb_rankings), "team seasons.\n")

# Print some summary statistics
cat("\n--- QB RANKINGS SUMMARY ---\n")
cat("Individual QB seasons:", nrow(QB_ranks), "\n")
cat("Team QB seasons:", nrow(team_qb_rankings), "\n")
cat("Seasons covered:", paste(unique(QB_ranks$season), collapse=", "), "\n")
cat("Unique QBs:", length(unique(QB_ranks$player_id)), "\n")
cat("Individual QBs by tier (most recent season):\n")
recent_season <- max(QB_ranks$season)
tier_counts <- QB_ranks %>% 
  filter(season == recent_season) %>% 
  count(qb_tier) %>% 
  arrange(qb_tier)
for(i in 1:nrow(tier_counts)) {
  cat("  Tier", tier_counts$qb_tier[i], ":", tier_counts$n[i], "QBs\n")
}
cat("Team QB tiers (most recent season):\n")
team_tier_counts <- team_qb_rankings %>% 
  filter(season == recent_season) %>% 
  count(team_qb_tier) %>% 
  arrange(team_qb_tier)
for(i in 1:nrow(team_tier_counts)) {
  cat("  Team Tier", team_tier_counts$team_qb_tier[i], ":", team_tier_counts$n[i], "teams\n")
}
cat("Top 5 individual QBs in", recent_season, ":\n")
top_qbs <- QB_ranks %>% 
  filter(season == recent_season) %>% 
  head(5) %>%
  select(player_name, team, composite_rank_score, qb_tier)
for(i in 1:nrow(top_qbs)) {
  cat("  ", i, ".", top_qbs$player_name[i], "(", top_qbs$team[i], ") - Tier", top_qbs$qb_tier[i], "\n")
}
cat("Top 5 team QB situations in", recent_season, ":\n")
top_teams <- team_qb_rankings %>% 
  filter(season == recent_season) %>% 
  head(5) %>%
  select(team, team_qb_tier, primary_qb, primary_qb_games, total_qbs_used)
for(i in 1:nrow(top_teams)) {
  cat("  ", i, ".", top_teams$team[i], "- Team Tier", top_teams$team_qb_tier[i], 
      "(", top_teams$primary_qb[i], ",", top_teams$primary_qb_games[i], "games,", 
      top_teams$total_qbs_used[i], "QBs used)\n")
}
cat("---------------------------\n")

# 5. EXPORT TO JSON
# ------------------------------------------------
# Create a combined dataset with both individual and team data
combined_data <- list(
  individual_qb_rankings = QB_ranks,
  team_qb_tiers = team_qb_rankings
)

# Define the output file path
output_file <- "qb_rankings.json"

# Convert the data frame to a JSON array format and write to file
json_data <- toJSON(combined_data, pretty = TRUE, auto_unbox = TRUE)
write(json_data, file = output_file)

cat("Successfully exported QB rankings to", output_file, "\n")
cat("You can now use the 'upload_qb_rankings.js' script to upload this file to Firestore.\n") 