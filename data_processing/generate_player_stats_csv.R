# Generate NFL Player Statistics CSV from nflreadr
# Following the same pattern as other R data export scripts

library(nflreadr)
library(dplyr)
library(readr)

# Load player stats data
cat("Loading NFL player statistics data...\n")
player_stats <- nflreadr::load_player_stats(seasons = 2019:2024)

# Clean and process player stats data
player_stats_cleaned <- player_stats %>%
  filter(
    !is.na(player_name),
    !is.na(recent_team),
    !is.na(position),
    season_type == "REG"  # Regular season only
  ) %>%
  select(
    season,
    season_type,
    week,
    player_id,
    player_name,
    player_display_name,
    position,
    position_group,
    team = recent_team,  # Rename for consistency
    
    # Passing stats
    attempts,
    completions,
    passing_yards,
    passing_tds,
    interceptions,
    sacks,
    sack_yards,
    sack_fumbles,
    sack_fumbles_lost,
    passing_air_yards,
    passing_yards_after_catch,
    passing_first_downs,
    passing_epa,
    passing_2pt_conversions,
    
    # Rushing stats  
    carries,
    rushing_yards,
    rushing_tds,
    rushing_fumbles,
    rushing_fumbles_lost,
    rushing_first_downs,
    rushing_epa,
    rushing_2pt_conversions,
    
    # Receiving stats
    targets,
    receptions,
    receiving_yards,
    receiving_tds,
    receiving_fumbles,
    receiving_fumbles_lost,
    receiving_air_yards,
    receiving_yards_after_catch,
    receiving_first_downs,
    receiving_epa,
    receiving_2pt_conversions,
    
    # Fantasy stats
    fantasy_points,
    fantasy_points_ppr
  ) %>%
  # Calculate additional derived stats
  mutate(
    # Passing efficiency
    completion_percentage = ifelse(attempts > 0, round(completions / attempts * 100, 1), 0),
    yards_per_attempt = ifelse(attempts > 0, round(passing_yards / attempts, 2), 0),
    touchdown_percentage = ifelse(attempts > 0, round(passing_tds / attempts * 100, 2), 0),
    interception_percentage = ifelse(attempts > 0, round(interceptions / attempts * 100, 2), 0),
    
    # Rushing efficiency
    yards_per_carry = ifelse(carries > 0, round(rushing_yards / carries, 2), 0),
    
    # Receiving efficiency  
    catch_percentage = ifelse(targets > 0, round(receptions / targets * 100, 1), 0),
    yards_per_reception = ifelse(receptions > 0, round(receiving_yards / receptions, 2), 0),
    yards_per_target = ifelse(targets > 0, round(receiving_yards / targets, 2), 0),
    
    # Total stats
    total_yards = coalesce(passing_yards, 0) + coalesce(rushing_yards, 0) + coalesce(receiving_yards, 0),
    total_tds = coalesce(passing_tds, 0) + coalesce(rushing_tds, 0) + coalesce(receiving_tds, 0),
    
    # Clean up NAs
    across(where(is.numeric), ~coalesce(.x, 0))
  ) %>%
  # Filter for players with meaningful stats
  filter(
    (attempts >= 1) | (carries >= 1) | (targets >= 1) | (fantasy_points > 0)
  ) %>%
  arrange(season, week, team, player_name)

cat(sprintf("Processed %d player stat records\n", nrow(player_stats_cleaned)))

# Sample the data to show what we have
cat("Sample player stats data:\n")
sample_data <- player_stats_cleaned %>%
  filter(season == 2024, week <= 5, position == "QB") %>%
  select(season, week, player_name, team, attempts, completions, passing_yards, passing_tds, fantasy_points) %>%
  head(10)
print(sample_data)

# Write to CSV
output_file <- "assets/nfl_player_stats.csv"
write_csv(player_stats_cleaned, output_file)
cat(sprintf("Player stats exported to %s\n", output_file))

# Generate summary stats
cat("\nPlayer stats summary:\n")
summary_stats <- player_stats_cleaned %>%
  group_by(season, position) %>%
  summarise(
    total_players = n_distinct(player_id),
    total_records = n(),
    avg_fantasy_points = round(mean(fantasy_points, na.rm = TRUE), 2),
    max_fantasy_points = round(max(fantasy_points, na.rm = TRUE), 2),
    .groups = "drop"
  ) %>%
  arrange(season, position)

print(summary_stats)

cat("Player stats CSV generation complete!\n")