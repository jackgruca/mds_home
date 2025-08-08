# data_processing/generate_idl_rankings_csv.R
# Generate IDL rankings data for trade analyzer and rankings screen

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)

cat("🏈 NFL IDL Rankings Generator\n")
cat("Loading IDL rankings data from nflreadr...\n")

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

# IDL position filter
idl_positions <- load_rosters(seasons = 2016:2024) %>%
  filter(depth_chart_position %in% c("DT", "NT", "DL")) %>%
  mutate(player_pbp_format = sapply(full_name, convert_to_pbp_format)) %>%
  select(player_pbp_format, season, team, depth_chart_position) %>%
  rename(player_name = player_pbp_format)

# Base IDL defensive stats (same extractions)
IDL_sacks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG") %>%
  {bind_rows(
    filter(., !is.na(sack_player_name)) %>%
      group_by(sack_player_name, season) %>%
      summarise(sacks = n(), .groups = 'drop') %>%
      rename(player_name = sack_player_name),
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

# Solo tackles for IDL
solo_tackles <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG") %>%
  {bind_rows(
    filter(., !is.na(solo_tackle_1_player_name)) %>%
      group_by(solo_tackle_1_player_name, season) %>%
      summarise(solo_tackles = n(), .groups = 'drop') %>%
      rename(player_name = solo_tackle_1_player_name),
    filter(., !is.na(solo_tackle_2_player_name)) %>%
      group_by(solo_tackle_2_player_name, season) %>%
      summarise(solo_tackles = n(), .groups = 'drop') %>%
      rename(player_name = solo_tackle_2_player_name)
  )} %>%
  group_by(player_name, season) %>%
  summarise(total_solo_tackles = sum(solo_tackles, na.rm = TRUE), .groups = 'drop')

# Run stuffs for IDL
run_stuffs <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG", play_type == "run") %>%
  {bind_rows(
    filter(., !is.na(tackle_for_loss_1_player_name)) %>%
      group_by(tackle_for_loss_1_player_name, season) %>%
      summarise(run_stuffs = n(), .groups = 'drop') %>%
      rename(player_name = tackle_for_loss_1_player_name),
    filter(., !is.na(tackle_for_loss_2_player_name)) %>%
      group_by(tackle_for_loss_2_player_name, season) %>%
      summarise(run_stuffs = n(), .groups = 'drop') %>%
      rename(player_name = tackle_for_loss_2_player_name)
  )} %>%
  group_by(player_name, season) %>%
  summarise(total_run_stuffs = sum(run_stuffs, na.rm = TRUE), .groups = 'drop')

# Interior pressure rate 
idl_pressure <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
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

# IDL TFLs
idl_tfls <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
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

# IDL Snap counts
IDL_snaps <- load_snap_counts(seasons = 2016:2024) %>%
  mutate(player_pbp_format = sapply(player, convert_to_pbp_format)) %>%
  group_by(player_pbp_format, season) %>%
  summarise(
    total_def_snaps = sum(defense_snaps, na.rm = TRUE),
    games_played = n(),
    avg_snap_pct = mean(defense_pct, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  rename(player_name = player_pbp_format)

# Combine IDL stats and filter to IDL positions
IDL_ranks <- left_join(IDL_sacks, solo_tackles) %>% 
  left_join(., run_stuffs) %>% 
  left_join(., idl_pressure) %>% 
  left_join(., idl_tfls) %>%
  left_join(., IDL_snaps) %>%
  # FILTER TO IDL POSITIONS ONLY
  inner_join(., idl_positions) %>%
  filter(!is.na(total_def_snaps), total_def_snaps >= 200) %>%
  mutate(
    tackles_per_game = total_solo_tackles / games_played,
    run_stuff_rate = total_run_stuffs / total_def_snaps * 100,
    tfls_per_game = total_tfls / games_played,
    interior_pressure_rate = (total_sacks + total_qb_hits) / total_def_snaps * 100
  ) %>%
  group_by(season) %>% 
  mutate(
    run_stuff_rank = percent_rank(total_run_stuffs), 
    tackles_rank = percent_rank(total_solo_tackles), 
    tfls_rank = percent_rank(total_tfls),
    interior_pressure_rank = percent_rank(interior_pressure_rate),
    snap_pct_rank = percent_rank(avg_snap_pct),
    sacks_rank = percent_rank(total_sacks)
  ) %>%
  unique() %>% 
  group_by(player_name, season) %>% 
  arrange(desc(tackles_rank)) %>%
  # IDL composite rank calculation (run defense focused)
  mutate(myRank = 
           0.25*tfls_rank +
           0.25*tackles_rank +
           0.15*run_stuff_rank +
           0.20*interior_pressure_rank +
           0.08*snap_pct_rank +
           0.05*sacks_rank) %>% 
  unique() %>% arrange(desc(myRank)) %>% 
  group_by(season) %>% mutate(myRankNum = row_number()) %>%
  mutate(idlTier = case_when(
    myRankNum <= 5 ~ 1,
    myRankNum <= 10 ~ 2,
    myRankNum <= 20 ~ 3,
    myRankNum <= 35 ~ 4,
    myRankNum <= 50 ~ 5,
    myRankNum <= 70 ~ 6,
    TRUE ~ 7
  ))

# Clean and format final dataset
idl_rankings_final <- IDL_ranks %>%
  select(
    player_name, season, team, depth_chart_position,
    total_sacks, total_qb_hits, total_tfls, total_solo_tackles, 
    total_run_stuffs, total_def_snaps, games_played, avg_snap_pct,
    tackles_per_game, run_stuff_rate, tfls_per_game, interior_pressure_rate,
    myRank, myRankNum, idlTier
  ) %>%
  rename(
    name = player_name,
    position = depth_chart_position,
    sacks = total_sacks,
    qb_hits = total_qb_hits,
    tfls = total_tfls,
    solo_tackles = total_solo_tackles,
    run_stuffs = total_run_stuffs,
    def_snaps = total_def_snaps,
    snap_pct = avg_snap_pct,
    composite_rank = myRank,
    ranking = myRankNum,
    tier = idlTier
  ) %>%
  # Handle missing values
  mutate(across(where(is.numeric), ~ifelse(is.na(.), 0, .))) %>%
  mutate(across(where(is.character), ~ifelse(is.na(.), "", .))) %>%
  arrange(season, ranking)

cat("IDL rankings data processed. Final shape:", nrow(idl_rankings_final), "rows,", ncol(idl_rankings_final), "columns\n")

# Data validation and summary
cat("\n=== IDL RANKINGS SUMMARY ===\n")
cat("Total IDL player-seasons:", nrow(idl_rankings_final), "\n")
cat("Seasons:", paste(sort(unique(idl_rankings_final$season)), collapse = ", "), "\n")
cat("Teams:", length(unique(idl_rankings_final$team)), "\n")

# Season breakdown
cat("\nSeason breakdown:\n")
season_summary <- idl_rankings_final %>%
  count(season, sort = TRUE)
print(season_summary)

# Tier distribution
cat("\nTier distribution:\n")
tier_summary <- idl_rankings_final %>%
  count(tier, sort = TRUE)
print(tier_summary)

# Top IDL players by season
cat("\nTop 5 IDL players by recent seasons:\n")
top_idl <- idl_rankings_final %>%
  filter(season >= 2022) %>%
  group_by(season) %>%
  slice_min(ranking, n = 5) %>%
  select(season, name, team, solo_tackles, tfls, run_stuff_rate, tier, ranking) %>%
  arrange(season, ranking)
print(top_idl)

# Export to CSV
output_file_csv <- "../assets/rankings/idl_rankings.csv"

cat("\nExporting IDL rankings to", output_file_csv, "...\n")

# Export to CSV without quotes
write.csv(idl_rankings_final, output_file_csv, row.names = FALSE, quote = FALSE)
cat("✅ CSV export complete! File saved as:", output_file_csv, "\n")

# Sample data preview
cat("\n=== SAMPLE IDL RANKINGS ===\n")
cat("First few records:\n")
sample_rankings <- idl_rankings_final %>%
  head(5) %>%
  select(name, season, team, solo_tackles, tfls, run_stuff_rate, ranking, tier)
print(sample_rankings)

cat("\n🎉 IDL rankings generation complete!\n")
cat("📊 Total IDL player-seasons exported:", nrow(idl_rankings_final), "\n")
cat("📁 File location: assets/idl_rankings.csv\n")
cat("🔧 Next step: Create IDL rankings screen in Flutter app\n")