library(nflfastR)
library(dplyr)
library(tidyr)
library(jsonlite)

# Load play-by-play data
pbp_2024 <- load_pbp(2024)
pbp_2023 <- load_pbp(2023)
pbp_2022 <- load_pbp(2022)
pbp_2021 <- load_pbp(2021)
pbp_2020 <- load_pbp(2020)
pbp_2019 <- load_pbp(2019)
pbp_2018 <- load_pbp(2018)
pbp_2017 <- load_pbp(2017)
pbp_2016 <- load_pbp(2016)

pbp <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016)
pbp_data <- pbp  # Alias for compatibility

print("✅ Loaded play-by-play data for 2016-2024")

#### WR tgt share & status ####

# Calculate active games from play-by-play data
active_games <- pbp %>%
  filter(season_type == "REG", !is.na(receiver_player_id)) %>%
  group_by(receiver_player_id, season, week, posteam) %>%
  summarise(plays = n(), .groups = 'drop') %>%
  group_by(receiver_player_id, season, posteam) %>%
  mutate(numGames = n_distinct(week)) %>%
  select(receiver_player_id, posteam, season, numGames) %>%
  unique()

# team stats
team_pass_per_game <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG", play_type == "pass") %>%
  # team runs per game
  group_by(game_id, posteam) %>% summarize(numPass = sum(pass_attempt, na.rm = TRUE), .groups = 'drop') 

# player stats
player_tgt_per_game <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG", play_type == "pass") %>%
  # team runs per game
  group_by(game_id, posteam, receiver_player_id) %>% 
  summarize(numTgt = n(), numRec = sum(complete_pass,na.rm=TRUE), numYards = sum(yards_gained, na.rm = TRUE), numTD = sum(touchdown, na.rm=TRUE), .groups = 'drop')

# tgt share and ranks
wr_tgt_share <- active_games %>% left_join(., team_pass_per_game) %>%
  left_join(., player_tgt_per_game) %>% 
  group_by(season, receiver_player_id, posteam) %>%
  mutate(numTgt = replace_na(numTgt, 0)) %>% mutate(numRec = replace_na(numRec, 0)) %>% mutate(numYards = replace_na(numYards, 0)) %>% mutate(numPass = replace_na(numPass, 0)) %>% mutate(numTD = replace_na(numTD, 0)) %>%
  summarize(numGames = first(numGames), tgt_share = sum(numTgt,na.rm=TRUE)/sum(numPass,na.rm=TRUE), numYards = sum(numYards,na.rm=TRUE), numTD = sum(numTD,na.rm=TRUE), numRec = sum(numRec,na.rm=TRUE), .groups = 'drop') %>%
  unique() %>% filter(numGames > 3) %>%
  # ranks
  group_by(posteam, season) %>% arrange(desc(numYards/numGames)) %>% mutate(yards_rank = row_number()) %>%
  arrange(desc(tgt_share)) %>% mutate(tgt_rank = row_number()) %>%
  arrange(desc(numTD)) %>% mutate(td_rank = row_number()) %>%
  mutate(avg = (yards_rank+tgt_rank)/2) %>% arrange(tgt_rank) %>% arrange(avg) %>% 
  mutate(wr_rank = row_number()) %>% 
  select(receiver_player_id, posteam, season, numGames, tgt_share, numYards, numTD, numRec, wr_rank)

print("✅ Calculated WR target share")

#### RB rush share & status ####

# Calculate active games from play-by-play data for rushing
active_games_rush <- pbp %>%
  filter(season_type == "REG", !is.na(rusher_player_id)) %>%
  group_by(rusher_player_id, season, week, posteam) %>%
  summarise(plays = n(), .groups = 'drop') %>%
  group_by(rusher_player_id, season, posteam) %>%
  mutate(numGames = n_distinct(week)) %>%
  select(rusher_player_id, posteam, season, numGames) %>%
  unique()

# team stats
team_rush_per_game <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG", play_type == "run") %>%
  # team runs per game
  group_by(game_id, posteam) %>% summarize(numRuns = sum(rush_attempt, na.rm = TRUE), .groups = 'drop') 

# player stats
player_rush_per_game <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG", play_type == "run") %>%
  # team runs per game
  group_by(game_id, posteam, rusher_player_id) %>% summarize(numRushes = sum(rush_attempt, na.rm = TRUE), numYards = sum(yards_gained, na.rm = TRUE), numTD = sum(touchdown, na.rm = TRUE), .groups = 'drop')

# run share and ranks
rb_rush_share <- active_games_rush %>% left_join(., team_rush_per_game) %>%
  left_join(., player_rush_per_game) %>% 
  group_by(season, rusher_player_id, posteam) %>%
  mutate(numRushes = replace_na(numRushes, 0)) %>% mutate(numYards = replace_na(numYards, 0)) %>% mutate(numTD = replace_na(numTD, 0)) %>%
  summarize(numGames = first(numGames), run_share = sum(numRushes)/sum(numRuns), YPG = sum(numYards)/numGames, numTD = sum(numTD), .groups = 'drop') %>%
  unique() %>% na.omit() %>% filter(numGames > 3) %>%
  # ranks
  group_by(posteam, season) %>% arrange(desc(YPG)) %>% mutate(YPG_rank = row_number()) %>%
  arrange(desc(run_share)) %>% mutate(run_rank = row_number()) %>%
  mutate(avg = (YPG_rank+run_rank)/2) %>% arrange((run_rank)) %>% arrange((avg)) %>% 
  mutate(rb_rank = row_number()) %>% select(rusher_player_id, posteam, season, numGames, numTD, run_share, YPG, rb_rank)

print("✅ Calculated RB rush share")

#### RB Ranks ####
RB_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(totalEPA = sum(epa,na.rm=TRUE), totalTD = sum(touchdown, na.rm=TRUE), .groups = 'drop')

rz_rate <- pbp %>%
  filter(season_type == "REG", play_type == "run", yardline_100 <= 20) %>% 
  group_by(fantasy_player_id, season) %>%
  mutate(num_rz_opps = n(), conversion = round(sum(touchdown)/num_rz_opps, 3)) %>%
  summarise(fantasy_player_id, fantasy_player_name, season, posteam, num_rz_opps, conversion, .groups = 'drop') %>% 
  unique() 

explosive_rate <- pbp %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(fantasy_player_id, season) %>%
  mutate(numRush = n()) %>% filter(yards_gained >= 15) %>%
  mutate(explosive_rate = n()/numRush) %>% 
  summarise(fantasy_player_id, fantasy_player_name, season, posteam, explosive_rate, .groups = 'drop') %>% 
  unique() 

third_down_rate <- pbp_data %>%
  filter(season_type == "REG", play_type == "run", down == 3) %>%
  group_by(fantasy_player_id, season) %>%
  summarize(
    third_down_att = n(),
    third_down_conversions = sum(first_down_rush, na.rm = TRUE),
    third_down_rate = third_down_conversions / third_down_att,
    .groups = 'drop'
  )

# Calculate efficiency and RYOE from available data
RB_ngs <- pbp %>%
  filter(season_type == "REG", play_type == "run", !is.na(fantasy_player_id)) %>%
  group_by(fantasy_player_id, season) %>%
  summarise(
    avg_eff = mean(epa, na.rm = TRUE),
    avg_RYOE_perAtt = mean(yards_gained, na.rm = TRUE),
    player_position = "RB",
    .groups = 'drop'
  )

print("✅ Calculated advanced RB stats")

# Join all data
RB_ranks <- left_join(RB_ranks, rb_rush_share, by = c("posteam", "season", "fantasy_player_id" = "rusher_player_id")) %>% 
  left_join(.,wr_tgt_share[,c(1,2,3,5)], by = c("posteam", "season", "fantasy_player_id" = "receiver_player_id")) %>% 
  left_join(.,rz_rate, by = c("fantasy_player_id", "season")) %>% 
  left_join(.,explosive_rate, by = c("fantasy_player_id", "season")) %>% 
  left_join(.,RB_ngs, by = c("fantasy_player_id", "season")) %>% 
  left_join(.,third_down_rate, by = c("fantasy_player_id", "season")) %>%
  filter(player_position == "RB") %>%
  group_by(season) %>% 
  mutate(
    EPA_rank = percent_rank(totalEPA), 
    td_rank = percent_rank(totalTD/numGames), 
    run_rank = percent_rank(run_share), 
    tgt_rank = percent_rank(tgt_share), 
    YPG_rank = percent_rank(YPG), 
    third_rank = percent_rank(third_down_rate), 
    conversion_rank = percent_rank(conversion), 
    explosive_rank = percent_rank(explosive_rate), 
    RYOE_rank = percent_rank(avg_RYOE_perAtt), 
    eff_rank = percent_rank(-avg_eff)
  ) %>%
  unique() %>% 
  group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% 
  arrange(desc(EPA_rank)) %>%
  # consensus rank calc
  mutate(myRank = 
           0.15*EPA_rank +
           0.15*run_rank +
           0.15*YPG_rank +
           0.15*td_rank +
           0.1*explosive_rank +
           0.1*RYOE_rank +
           0.1*third_rank +
           0.05*eff_rank +
           0.05*tgt_rank) %>% 
  unique() %>% arrange(desc(myRank)) %>% 
  group_by(season) %>% mutate(myRankNum = row_number()) %>%
  mutate(rbTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  ))

print("✅ Calculated final RB rankings")

# Debug: Check what columns are available
print("Available columns in RB_ranks:")
print(names(RB_ranks))

#### offense ranks ####
# run offense rank 
runOffenseRank <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016)  %>% 
  group_by(posteam, season) %>% filter(season_type == "REG", play_type == "run") %>%
  mutate(success = case_when(
    (down == 1) & (yards_gained >= ydstogo*.6) ~ 1,
    (down == 2) & (yards_gained >= ydstogo*.4) ~ 1,
    (down == 3) & (yards_gained >= ydstogo) ~ 1,
    (down == 4) & (yards_gained >= ydstogo) ~ 1,
    TRUE ~ 0
  )) %>%
  summarise(totalEP = sum(ep,na.rm=TRUE), totalYds = sum(yards_gained, na.rm=TRUE), totalTD = sum(touchdown,na.rm=TRUE), successRate = mean(success), .groups = 'drop') %>% 
  group_by(season) %>%
  mutate(EP_rank = percent_rank(totalEP), yds_rank = percent_rank(totalYds), TD_rank = percent_rank(totalTD), success_rank = percent_rank(successRate)) %>%
  na.omit() %>% mutate(myRank = yds_rank+TD_rank+success_rank) %>% arrange(desc(myRank)) %>% mutate(myRankNum = row_number()) %>%
  mutate(runOffenseTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    myRankNum <= 32 ~ 8
  ))

# pass off rank
passOffenseRank <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016)  %>% 
  group_by(posteam, season) %>% filter(season_type == "REG", play_type == "pass") %>%
  mutate(success = case_when(
    (down == 1) & (yards_gained >= ydstogo*.6) ~ 1,
    (down == 2) & (yards_gained >= ydstogo*.4) ~ 1,
    (down == 3) & (yards_gained >= ydstogo) ~ 1,
    (down == 4) & (yards_gained >= ydstogo) ~ 1,
    TRUE ~ 0
  )) %>%
  summarise(totalEP = sum(ep,na.rm=TRUE), totalYds = sum(yards_gained, na.rm=TRUE), totalTD = sum(touchdown,na.rm=TRUE), successRate = mean(success), .groups = 'drop') %>% 
  group_by(season) %>%
  mutate(EP_rank = percent_rank(totalEP), yds_rank = percent_rank(totalYds), TD_rank = percent_rank(totalTD), success_rank = percent_rank(successRate)) %>%
  na.omit() %>% mutate(myRank = yds_rank+TD_rank+success_rank) %>% arrange(desc(myRank)) %>% mutate(myRankNum = row_number()) %>%
  mutate(passOffenseTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    myRankNum <= 32 ~ 8
  ))

print("✅ Calculated offense rankings")

# Join offense rankings
RB_ranks <- RB_ranks %>%
  left_join(runOffenseRank %>% select(posteam, season, runOffenseTier), by = c("posteam", "season")) %>%
  left_join(passOffenseRank %>% select(posteam, season, passOffenseTier), by = c("posteam", "season"))

# Clean and prepare final data with all columns
rb_rankings_final <- RB_ranks %>%
  mutate(
    # Handle missing values
    tgt_share = ifelse(is.na(tgt_share), 0, tgt_share),
    conversion = ifelse(is.na(conversion), 0, conversion),
    explosive_rate = ifelse(is.na(explosive_rate), 0, explosive_rate),
    third_down_rate = ifelse(is.na(third_down_rate), 0, third_down_rate),
    avg_eff = ifelse(is.na(avg_eff), 0, avg_eff),
    avg_RYOE_perAtt = ifelse(is.na(avg_RYOE_perAtt), 0, avg_RYOE_perAtt),
    runOffenseTier = ifelse(is.na(runOffenseTier), 8, runOffenseTier),
    passOffenseTier = ifelse(is.na(passOffenseTier), 8, passOffenseTier)
  ) %>%
  select(
    player_id = fantasy_player_id,
    player_name = fantasy_player_name.x,
    team = posteam.x,
    season,
    position = player_position,
    # Core rankings
    my_rank = myRankNum,
    my_rank_score = myRank,
    tier = rbTier,
    # Raw stats
    total_epa = totalEPA,
    total_tds = totalTD,
    total_yards = YPG,
    rush_share = run_share,
    target_share = tgt_share,
    explosive_rate,
    conversion_rate = conversion,
    third_down_rate,
    efficiency = avg_eff,
    ryoe_per_att = avg_RYOE_perAtt,
    games = numGames,
    # Percentile ranks (for density visualization)
    epa_rank = EPA_rank,
    td_rank,
    rush_share_rank = run_rank,
    target_share_rank = tgt_rank,
    yards_rank = YPG_rank,
    explosive_rank,
    conversion_rank,
    third_down_rank = third_rank,
    efficiency_rank = eff_rank,
    ryoe_rank = RYOE_rank,
    # Team context
    run_offense_tier = runOffenseTier,
    pass_offense_tier = passOffenseTier
  ) %>%
  arrange(season, my_rank) %>%
  ungroup()

# Export to JSON
write_json(rb_rankings_final, "rb_rankings_comprehensive.json")

print("✅ Exported comprehensive RB rankings to JSON")
print(paste("Total RB records:", nrow(rb_rankings_final)))

# Show sample of 2024 rankings
print("Top 10 RB rankings for 2024:")
print(rb_rankings_final %>% filter(season == 2024) %>% head(10) %>% 
      select(my_rank, player_name, team, total_yards, total_tds, rush_share, my_rank_score))

print("✅ RB rankings script completed successfully") 