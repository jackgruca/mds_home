#### Bust Evaluation Data Generator ####
# This script generates comprehensive bust evaluation data for NFL players
# Based on comparing actual career performance vs peer averages by position and draft round

library(dplyr)
library(nflreadr)
library(jsonlite)

# Load roster & draft info
print("Loading roster and draft data...")
rosters <- load_rosters() %>%
  select(gsis_id, full_name, position, team)

drafts <- load_players() %>%
  select(gsis_id, draftround, rookie_year) %>%
  rename(draft_round = draftround) %>%
  filter(!is.na(draft_round), draft_round <= 7, rookie_year >= 2010)

rosters <- rosters %>%
  left_join(drafts, by = "gsis_id") %>%
  filter(!is.na(position), !is.na(draft_round))

print(paste("Loaded", nrow(rosters), "players with draft data"))

# Load play-by-play data for receiving stats
print("Loading play-by-play data...")
pbp <- nflfastR::load_pbp(2010:2024) %>%
  filter(play_type == "pass", !is.na(receiver_player_id))

# Load player stats for rushing, passing, and additional metrics
print("Loading player stats...")
player_stats <- load_player_stats(2010:2024)

# RECEIVING STATS (WR, TE, RB)
print("Processing receiving stats...")
receiving_stats <- pbp %>%
  group_by(season, receiver_player_id, receiver_player_name) %>%
  summarise(
    season_rec_yds = sum(yards_gained, na.rm = TRUE),
    season_targets = n(),
    season_receptions = sum(complete_pass, na.rm = TRUE),
    season_rec_td = sum(touchdown == 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(
    gsis_id = receiver_player_id,
    player_name = receiver_player_name,
    league_year = season
  )

# RUSHING STATS (RB, QB)
print("Processing rushing stats...")
rushing_stats <- player_stats %>%
  filter(season >= 2010, season <= 2024) %>%
  select(player_id, player_name, season, carries, rushing_yards, rushing_tds) %>%
  rename(
    gsis_id = player_id,
    league_year = season,
    season_carries = carries,
    season_rush_yds = rushing_yards,
    season_rush_td = rushing_tds
  ) %>%
  filter(!is.na(season_carries)) %>%
  # CRITICAL FIX: Deduplicate by summing stats for each player-season
  group_by(gsis_id, league_year) %>%
  summarise(
    player_name = first(player_name),
    season_carries = sum(season_carries, na.rm = TRUE),
    season_rush_yds = sum(season_rush_yds, na.rm = TRUE),
    season_rush_td = sum(season_rush_td, na.rm = TRUE),
    .groups = "drop"
  )

# PASSING STATS (QB)
print("Processing passing stats...")
passing_stats <- player_stats %>%
  filter(season >= 2010, season <= 2024) %>%
  select(player_id, player_name, season, attempts, passing_yards, passing_tds, interceptions) %>%
  rename(
    gsis_id = player_id,
    league_year = season,
    season_attempts = attempts,
    season_pass_yds = passing_yards,
    season_pass_td = passing_tds,
    season_int = interceptions
  ) %>%
  filter(!is.na(season_attempts)) %>%
  # CRITICAL FIX: Deduplicate by summing stats for each player-season
  group_by(gsis_id, league_year) %>%
  summarise(
    player_name = first(player_name),
    season_attempts = sum(season_attempts, na.rm = TRUE),
    season_pass_yds = sum(season_pass_yds, na.rm = TRUE),
    season_pass_td = sum(season_pass_td, na.rm = TRUE),
    season_int = sum(season_int, na.rm = TRUE),
    .groups = "drop"
  )

# Merge all stats with roster info
print("Merging all stats...")
all_stats <- rosters %>%
  select(gsis_id, full_name, position, team, draft_round, rookie_year) %>%
  # Add receiving stats
  left_join(receiving_stats, by = "gsis_id") %>%
  # Add rushing stats
  left_join(rushing_stats, by = c("gsis_id", "league_year")) %>%
  # Add passing stats
  left_join(passing_stats, by = c("gsis_id", "league_year")) %>%
  # Use the name from roster if available, otherwise from stats
  mutate(
    player_name = coalesce(full_name, player_name.x, player_name.y, player_name),
    # Fill missing stats with 0
    season_rec_yds = coalesce(season_rec_yds, 0),
    season_targets = coalesce(season_targets, 0),
    season_receptions = coalesce(season_receptions, 0),
    season_rec_td = coalesce(season_rec_td, 0),
    season_carries = coalesce(season_carries, 0),
    season_rush_yds = coalesce(season_rush_yds, 0),
    season_rush_td = coalesce(season_rush_td, 0),
    season_attempts = coalesce(season_attempts, 0),
    season_pass_yds = coalesce(season_pass_yds, 0),
    season_pass_td = coalesce(season_pass_td, 0),
    season_int = coalesce(season_int, 0),
    # Add fumbles placeholder
    season_fumbles = 0  # Placeholder until fumble data is available
  ) %>%
  select(-full_name, -player_name.x, -player_name.y) %>%
  filter(!is.na(league_year))

# Filter for relevant positions and years
relevant_positions <- c("WR", "RB", "TE", "QB")
all_stats <- all_stats %>%
  filter(position %in% relevant_positions, league_year >= rookie_year)

print(paste("Processing", nrow(all_stats), "player-season records"))

# Calculate cumulative career stats
print("Calculating career totals...")
player_career <- all_stats %>%
  arrange(gsis_id, league_year) %>%
  group_by(gsis_id) %>%
  mutate(
    seasons_played = row_number(),
    career_rec_yds = cumsum(season_rec_yds),
    career_targets = cumsum(season_targets),
    career_receptions = cumsum(season_receptions),
    career_rec_td = cumsum(season_rec_td),
    career_carries = cumsum(season_carries),
    career_rush_yds = cumsum(season_rush_yds),
    career_rush_td = cumsum(season_rush_td),
    career_attempts = cumsum(season_attempts),
    career_pass_yds = cumsum(season_pass_yds),
    career_pass_td = cumsum(season_pass_td),
    career_int = cumsum(season_int),
    # Add fumbles as placeholder for now (to be populated when data becomes available)
    career_fumbles = cumsum(coalesce(season_fumbles, 0))
  ) %>%
  ungroup()

# Calculate peer averages by position, draft round, and Nth season in the league
print("Calculating peer averages based on seasons played...")
peer_season_avg <- player_career %>%
  group_by(position, draft_round, seasons_played) %>%
  summarise(
    avg_rec_yds = mean(season_rec_yds, na.rm = TRUE),
    avg_targets = mean(season_targets, na.rm = TRUE),
    avg_receptions = mean(season_receptions, na.rm = TRUE),
    avg_rec_td = mean(season_rec_td, na.rm = TRUE),
    avg_carries = mean(season_carries, na.rm = TRUE),
    avg_rush_yds = mean(season_rush_yds, na.rm = TRUE),
    avg_rush_td = mean(season_rush_td, na.rm = TRUE),
    avg_attempts = mean(season_attempts, na.rm = TRUE),
    avg_pass_yds = mean(season_pass_yds, na.rm = TRUE),
    avg_pass_td = mean(season_pass_td, na.rm = TRUE),
    avg_int = mean(season_int, na.rm = TRUE),
    avg_fumbles = mean(coalesce(season_fumbles, 0), na.rm = TRUE),
    peer_count = n(),
    .groups = "drop"
  )

# Calculate expected career totals based on peer averages
print("Calculating expected career totals...")
expected_career_stats <- player_career %>%
  select(gsis_id, position, draft_round, seasons_played) %>%
  distinct() %>%
  # Join with peer averages based on Nth season
  left_join(peer_season_avg, by = c("position", "draft_round", "seasons_played")) %>%
  # Now, calculate the CUMULATIVE expected stats for each player's career progression
  group_by(gsis_id) %>%
  arrange(seasons_played) %>%
  mutate(
    expected_rec_yds = cumsum(coalesce(avg_rec_yds, 0)),
    expected_targets = cumsum(coalesce(avg_targets, 0)),
    expected_receptions = cumsum(coalesce(avg_receptions, 0)),
    expected_rec_td = cumsum(coalesce(avg_rec_td, 0)),
    expected_carries = cumsum(coalesce(avg_carries, 0)),
    expected_rush_yds = cumsum(coalesce(avg_rush_yds, 0)),
    expected_rush_td = cumsum(coalesce(avg_rush_td, 0)),
    expected_attempts = cumsum(coalesce(avg_attempts, 0)),
    expected_pass_yds = cumsum(coalesce(avg_pass_yds, 0)),
    expected_pass_td = cumsum(coalesce(avg_pass_td, 0)),
    expected_int = cumsum(coalesce(avg_int, 0)),
    expected_fumbles = cumsum(coalesce(avg_fumbles, 0))
  ) %>%
  ungroup() %>%
  select(gsis_id, seasons_played, starts_with("expected_"))

# Create final dataset
print("Creating final dataset...")
final_data <- player_career %>%
  left_join(expected_career_stats, by = c("gsis_id", "seasons_played")) %>%
  # Calculate performance ratios
  mutate(
    # Add a small epsilon to avoid division by zero
    expected_rec_yds_safe = ifelse(expected_rec_yds == 0, 1, expected_rec_yds),
    expected_rush_yds_safe = ifelse(expected_rush_yds == 0, 1, expected_rush_yds),
    expected_pass_yds_safe = ifelse(expected_pass_yds == 0, 1, expected_pass_yds),

    # Receiving ratios
    rec_yds_ratio = career_rec_yds / expected_rec_yds_safe,
    targets_ratio = career_targets / ifelse(expected_targets == 0, 1, expected_targets),
    receptions_ratio = career_receptions / ifelse(expected_receptions == 0, 1, expected_receptions),
    rec_td_ratio = career_rec_td / ifelse(expected_rec_td == 0, 1, expected_rec_td),
    
    # Rushing ratios
    carries_ratio = career_carries / ifelse(expected_carries == 0, 1, expected_carries),
    rush_yds_ratio = career_rush_yds / expected_rush_yds_safe,
    rush_td_ratio = career_rush_td / ifelse(expected_rush_td == 0, 1, expected_rush_td),

    # Passing ratios
    attempts_ratio = career_attempts / ifelse(expected_attempts == 0, 1, expected_attempts),
    pass_yds_ratio = career_pass_yds / expected_pass_yds_safe,
    pass_td_ratio = career_pass_td / ifelse(expected_pass_td == 0, 1, expected_pass_td),
    # Invert interception ratio so lower is better; cap at 2 to avoid extreme scores
    int_ratio = ifelse(career_int > 0, expected_int / career_int, 2),
    # Invert fumbles ratio so lower is better; cap at 2 to avoid extreme scores  
    fumbles_ratio = ifelse(career_fumbles > 0, expected_fumbles / career_fumbles, 2),

    # Overall performance score based on primary stats by position
    performance_score = case_when(
      position %in% c("WR", "TE") & expected_rec_yds > 10 ~ (rec_yds_ratio * 0.5 + receptions_ratio * 0.3 + rec_td_ratio * 0.2),
      position == "RB" & (expected_rush_yds + expected_rec_yds) > 10 ~ (rush_yds_ratio * 0.5 + rec_yds_ratio * 0.2 + rush_td_ratio * 0.15 + rec_td_ratio * 0.15),
      position == "QB" & expected_pass_yds > 10 ~ (pass_yds_ratio * 0.6 + pass_td_ratio * 0.3 + int_ratio * 0.1),
      TRUE ~ 0
    ),
    performance_score = pmin(pmax(performance_score, 0), 3), # Clamp score between 0 and 3 for stability
    # Bust classification
    bust_category = case_when(
      performance_score >= 1.5 ~ "Steal",
      performance_score >= 0.9 ~ "Met Expectations", 
      performance_score >= 0.6 ~ "Disappointing",
      performance_score < 0.6 ~ "Bust",
      TRUE ~ "Insufficient Data"
    )
  ) %>%
  select(
    gsis_id, player_name, position, team, draft_round, rookie_year, league_year, seasons_played,
    # Season stats
    season_rec_yds, season_targets, season_receptions, season_rec_td,
    season_carries, season_rush_yds, season_rush_td,
    season_attempts, season_pass_yds, season_pass_td, season_int,
    # Career totals
    career_rec_yds, career_targets, career_receptions, career_rec_td,
    career_carries, career_rush_yds, career_rush_td,
    career_attempts, career_pass_yds, career_pass_td, career_int, career_fumbles,
    # Expected totals
    expected_rec_yds, expected_targets, expected_receptions, expected_rec_td,
    expected_carries, expected_rush_yds, expected_rush_td,
    expected_attempts, expected_pass_yds, expected_pass_td, expected_int, expected_fumbles,
    # Performance metrics
    rec_yds_ratio, targets_ratio, receptions_ratio, rec_td_ratio,
    carries_ratio, rush_yds_ratio, rush_td_ratio,
    attempts_ratio, pass_yds_ratio, pass_td_ratio, int_ratio,
    fumbles_ratio,
    performance_score, bust_category
  )

# Get the most recent season for each player (for the main evaluation)
print("Creating player summaries...")
player_summaries <- final_data %>%
  group_by(gsis_id) %>%
  filter(league_year == max(league_year)) %>%
  ungroup() %>%
  # Remove the 2-season filter to include rookies like Kincaid
  arrange(desc(performance_score))

# Create season-by-season data for timeline charts
season_data <- final_data %>%
  select(gsis_id, player_name, position, league_year, seasons_played, performance_score, bust_category) %>%
  arrange(gsis_id, league_year)

print(paste("Generated data for", nrow(player_summaries), "players"))
print(paste("Bust distribution:"))
print(table(player_summaries$bust_category))

# Save data as JSON for Flutter app
print("Saving data...")

# Main player data
writeLines(toJSON(player_summaries, pretty = TRUE), "bust_evaluation_data.json")

# Season timeline data
writeLines(toJSON(season_data, pretty = TRUE), "bust_evaluation_timeline.json")

# Position-specific peer averages for context
peer_context <- peer_season_avg %>%
  group_by(position, draft_round) %>%
  summarise(
    avg_career_rec_yds = mean(avg_rec_yds * 5, na.rm = TRUE), # Estimate 5-year career
    avg_career_targets = mean(avg_targets * 5, na.rm = TRUE),
    avg_career_receptions = mean(avg_receptions * 5, na.rm = TRUE),
    avg_career_rec_td = mean(avg_rec_td * 5, na.rm = TRUE),
    avg_career_carries = mean(avg_carries * 5, na.rm = TRUE),
    avg_career_rush_yds = mean(avg_rush_yds * 5, na.rm = TRUE),
    avg_career_rush_td = mean(avg_rush_td * 5, na.rm = TRUE),
    avg_career_attempts = mean(avg_attempts * 5, na.rm = TRUE),
    avg_career_pass_yds = mean(avg_pass_yds * 5, na.rm = TRUE),
    avg_career_pass_td = mean(avg_pass_td * 5, na.rm = TRUE),
    avg_career_int = mean(avg_int * 5, na.rm = TRUE),
    .groups = "drop"
  )

writeLines(toJSON(peer_context, pretty = TRUE), "bust_evaluation_context.json")

print("✅ Bust evaluation data generation complete!")
print("📁 Files saved:")
print("  - bust_evaluation_data.json (main player data)")
print("  - bust_evaluation_timeline.json (season-by-season data)")
print("  - bust_evaluation_context.json (peer context data)") 