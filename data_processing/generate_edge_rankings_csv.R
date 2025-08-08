# data_processing/generate_edge_rankings_csv.R
# Generate EDGE rankings data for trade analyzer and rankings screen

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)

cat("🏈 NFL EDGE Rankings Generator\n")
cat("Loading EDGE rankings data from nflreadr...\n")

# Load required datasets
cat("Loading play-by-play data...\n")
pbp_2024 <- load_pbp(2024)
pbp_2023 <- load_pbp(2023)
pbp_2022 <- load_pbp(2022)
pbp_2021 <- load_pbp(2021)
pbp_2020 <- load_pbp(2020)
pbp_2019 <- load_pbp(2019)
pbp_2018 <- load_pbp(2018)
pbp_2017 <- load_pbp(2017)
pbp_2016 <- load_pbp(2016)

# Function to convert full names to PBP format (First Initial.LastName)
convert_to_pbp_format <- function(full_name) {
  # Handle cases with Jr., Sr., III, etc.
  cleaned_name <- str_replace_all(full_name, " Jr\\.|Sr\\.|III|II|IV", "")
  
  # Split into parts
  name_parts <- str_split(cleaned_name, " ", simplify = TRUE)
  
  # Get first initial and last name
  if (ncol(name_parts) >= 2) {
    first_initial <- substr(name_parts[1], 1, 1)
    last_name <- name_parts[length(name_parts[1,])]  # Get last element
    return(paste0(first_initial, ".", last_name))
  } else {
    return(full_name)  # Return original if can't parse
  }
}

# EDGE position filter
edge_positions <- load_rosters(seasons = 2016:2024) %>%
  filter(depth_chart_position %in% c("DE", "OLB", "EDGE")) %>%
  mutate(player_pbp_format = sapply(full_name, convert_to_pbp_format)) %>%
  select(player_pbp_format, season, team, depth_chart_position) %>%
  rename(player_name = player_pbp_format)

# Base EDGE defensive stats
EDGE_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG") %>%
  {bind_rows(
    # Full sacks
    filter(., !is.na(sack_player_name)) %>%
      group_by(sack_player_name, season) %>%
      summarise(sacks = n(), .groups = 'drop') %>%
      rename(player_name = sack_player_name),
    # Half sacks
    filter(., !is.na(half_sack_1_player_name)) %>%
      group_by(half_sack_1_player_name, season) %>%
      summarise(half_sacks = n() * 0.5, .groups = 'drop') %>%
      rename(player_name = half_sack_1_player_name),
    filter(., !is.na(half_sack_2_player_name)) %>%
      group_by(half_sack_2_player_name, season) %>%
      summarise(half_sacks = n() * 0.5, .groups = 'drop') %>%
      rename(player_name = half_sack_2_player_name)
  )} %>%
  group_by(player_name, season) %>%
  summarise(total_sacks = sum(c(sacks, half_sacks), na.rm = TRUE), .groups = 'drop')

# QB Hits for EDGE
qb_hits <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG") %>%
  {bind_rows(
    filter(., !is.na(qb_hit_1_player_name)) %>%
      group_by(qb_hit_1_player_name, season) %>%
      summarise(qb_hits = n(), .groups = 'drop') %>%
      rename(player_name = qb_hit_1_player_name),
    filter(., !is.na(qb_hit_2_player_name)) %>%
      group_by(qb_hit_2_player_name, season) %>%
      summarise(qb_hits = n(), .groups = 'drop') %>%
      rename(player_name = qb_hit_2_player_name)
  )} %>%
  group_by(player_name, season) %>%
  summarise(total_qb_hits = sum(qb_hits, na.rm = TRUE), .groups = 'drop')

# Tackles for Loss
tfls <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG") %>%
  {bind_rows(
    filter(., !is.na(tackle_for_loss_1_player_name)) %>%
      group_by(tackle_for_loss_1_player_name, season) %>%
      summarise(tfls = n(), .groups = 'drop') %>%
      rename(player_name = tackle_for_loss_1_player_name),
    filter(., !is.na(tackle_for_loss_2_player_name)) %>%
      group_by(tackle_for_loss_2_player_name, season) %>%
      summarise(tfls = n(), .groups = 'drop') %>%
      rename(player_name = tackle_for_loss_2_player_name)
  )} %>%
  group_by(player_name, season) %>%
  summarise(total_tfls = sum(tfls, na.rm = TRUE), .groups = 'drop')

# Forced Fumbles
forced_fumbles <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG") %>%
  {bind_rows(
    filter(., !is.na(forced_fumble_player_1_player_name)) %>%
      group_by(forced_fumble_player_1_player_name, season) %>%
      summarise(forced_fumbles = n(), .groups = 'drop') %>%
      rename(player_name = forced_fumble_player_1_player_name),
    filter(., !is.na(forced_fumble_player_2_player_name)) %>%
      group_by(forced_fumble_player_2_player_name, season) %>%
      summarise(forced_fumbles = n(), .groups = 'drop') %>%
      rename(player_name = forced_fumble_player_2_player_name)
  )} %>%
  group_by(player_name, season) %>%
  summarise(total_forced_fumbles = sum(forced_fumbles, na.rm = TRUE), .groups = 'drop')

# Third down pressure
third_down_pressure <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG", down == 3, play_type == "pass") %>%
  {bind_rows(
    group_by(., sack_player_name, season) %>%
      filter(!is.na(sack_player_name)) %>%
      summarise(third_down_pressures = n(), .groups = 'drop') %>%
      rename(player_name = sack_player_name),
    group_by(., qb_hit_1_player_name, season) %>%
      filter(!is.na(qb_hit_1_player_name)) %>%
      summarise(third_down_pressures = n(), .groups = 'drop') %>%
      rename(player_name = qb_hit_1_player_name),
    group_by(., qb_hit_2_player_name, season) %>%
      filter(!is.na(qb_hit_2_player_name)) %>%
      summarise(third_down_pressures = n(), .groups = 'drop') %>%
      rename(player_name = qb_hit_2_player_name)
  )} %>%
  group_by(player_name, season) %>%
  summarise(third_down_pressures = sum(third_down_pressures, na.rm = TRUE), .groups = 'drop')

# Snap counts for EDGE
EDGE_snaps <- load_snap_counts(seasons = 2016:2024) %>%
  mutate(player_pbp_format = sapply(player, convert_to_pbp_format)) %>%
  group_by(player_pbp_format, season) %>%
  summarise(
    total_def_snaps = sum(defense_snaps, na.rm = TRUE),
    games_played = n(),
    avg_snap_pct = mean(defense_pct, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  rename(player_name = player_pbp_format)

# Combine EDGE stats and filter to EDGE positions
EDGE_ranks <- left_join(EDGE_ranks, qb_hits) %>% 
  left_join(., tfls) %>% 
  left_join(., forced_fumbles) %>% 
  left_join(., third_down_pressure) %>%
  left_join(., EDGE_snaps) %>%
  # FILTER TO EDGE POSITIONS ONLY
  inner_join(., edge_positions) %>%
  filter(!is.na(total_def_snaps), total_def_snaps >= 200) %>%
  mutate(
    sacks_per_game = total_sacks / games_played,
    qb_hits_per_game = total_qb_hits / games_played,
    pressure_rate = (total_sacks + total_qb_hits) / total_def_snaps * 100,
    tfls_per_game = total_tfls / games_played
  ) %>%
  group_by(season) %>% 
  mutate(
    sacks_rank = percent_rank(total_sacks), 
    qb_hits_rank = percent_rank(total_qb_hits), 
    pressure_rank = percent_rank(pressure_rate),
    tfls_rank = percent_rank(total_tfls),
    forced_fumbles_rank = percent_rank(total_forced_fumbles),
    snap_pct_rank = percent_rank(avg_snap_pct),
    third_down_rank = percent_rank(third_down_pressures)
  ) %>%
  unique() %>% 
  group_by(player_name, season) %>% 
  arrange(desc(sacks_rank)) %>%
  # EDGE composite rank calculation
  mutate(myRank = 
           0.30*sacks_rank +
           0.25*pressure_rank +
           0.15*tfls_rank +
           0.10*qb_hits_rank +
           0.08*forced_fumbles_rank +
           0.07*snap_pct_rank +
           0.05*third_down_rank) %>% 
  unique() %>% arrange(desc(myRank)) %>% 
  group_by(season) %>% mutate(myRankNum = row_number()) %>%
  mutate(edgeTier = case_when(
    myRankNum <= 5 ~ 1,
    myRankNum <= 10 ~ 2,
    myRankNum <= 20 ~ 3,
    myRankNum <= 35 ~ 4,
    myRankNum <= 50 ~ 5,
    myRankNum <= 70 ~ 6,
    TRUE ~ 7
  ))

# Clean and format final dataset
edge_rankings_final <- EDGE_ranks %>%
  select(
    player_name, season, team, depth_chart_position,
    total_sacks, total_qb_hits, total_tfls, total_forced_fumbles,
    third_down_pressures, total_def_snaps, games_played, avg_snap_pct,
    sacks_per_game, qb_hits_per_game, pressure_rate, tfls_per_game,
    myRank, myRankNum, edgeTier
  ) %>%
  rename(
    name = player_name,
    position = depth_chart_position,
    sacks = total_sacks,
    qb_hits = total_qb_hits,
    tfls = total_tfls,
    forced_fumbles = total_forced_fumbles,
    def_snaps = total_def_snaps,
    snap_pct = avg_snap_pct,
    composite_rank = myRank,
    ranking = myRankNum,
    tier = edgeTier
  ) %>%
  # Handle missing values
  mutate(across(where(is.numeric), ~ifelse(is.na(.), 0, .))) %>%
  mutate(across(where(is.character), ~ifelse(is.na(.), "", .))) %>%
  arrange(season, ranking)

# Debug: Print column names
cat("Available columns in EDGE_ranks:", paste(names(EDGE_ranks), collapse = ", "), "\n")

cat("EDGE rankings data processed. Final shape:", nrow(edge_rankings_final), "rows,", ncol(edge_rankings_final), "columns\n")

# Data validation and summary
cat("\n=== EDGE RANKINGS SUMMARY ===\n")
cat("Total EDGE player-seasons:", nrow(edge_rankings_final), "\n")
cat("Seasons:", paste(sort(unique(edge_rankings_final$season)), collapse = ", "), "\n")
cat("Teams:", length(unique(edge_rankings_final$team)), "\n")

# Season breakdown
cat("\nSeason breakdown:\n")
season_summary <- edge_rankings_final %>%
  count(season, sort = TRUE)
print(season_summary)

# Tier distribution
cat("\nTier distribution:\n")
tier_summary <- edge_rankings_final %>%
  count(tier, sort = TRUE)
print(tier_summary)

# Top EDGE players by season
cat("\nTop 5 EDGE players by recent seasons:\n")
top_edge <- edge_rankings_final %>%
  filter(season >= 2022) %>%
  group_by(season) %>%
  slice_min(ranking, n = 5) %>%
  select(season, name, team, sacks, qb_hits, pressure_rate, tier, ranking) %>%
  arrange(season, ranking)
print(top_edge)

# Export to CSV
output_file_csv <- "../assets/rankings/edge_rankings.csv"

cat("\nExporting EDGE rankings to", output_file_csv, "...\n")

# Export to CSV without quotes
write.csv(edge_rankings_final, output_file_csv, row.names = FALSE, quote = FALSE)
cat("✅ CSV export complete! File saved as:", output_file_csv, "\n")

# Sample data preview
cat("\n=== SAMPLE EDGE RANKINGS ===\n")
cat("First few records:\n")
sample_rankings <- edge_rankings_final %>%
  head(5) %>%
  select(name, season, team, sacks, qb_hits, pressure_rate, ranking, tier)
print(sample_rankings)

cat("\n🎉 EDGE rankings generation complete!\n")
cat("📊 Total EDGE player-seasons exported:", nrow(edge_rankings_final), "\n")
cat("📁 File location: assets/edge_rankings.csv\n")
cat("🔧 Next step: Create EDGE rankings screen in Flutter app\n")