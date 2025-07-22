#### load packages ####
library(tidyverse)
library(modelr)
library(readxl)
library(broom)
library(ranger)
library(caret) # machine learning
library(kernlab) # support vector machine algorithm
library(readr)
library(rvest)
library(caretEnsemble)
library(xgboost)
library(rstanarm)
library(nflreadr)
library(nflverse)
library(jsonlite)

#### loading in pbp data ####
pbp_2024 <- nflfastR::load_pbp(season = 2024)
pbp_2023 <- nflfastR::load_pbp(season = 2023)
pbp_2022 <- nflfastR::load_pbp(season = 2022)
pbp_2021 <- nflfastR::load_pbp(season = 2021)
pbp_2020 <- nflfastR::load_pbp(season = 2020)
pbp_2019 <- nflfastR::load_pbp(season = 2019)
pbp_2018 <- nflfastR::load_pbp(season = 2018)
pbp_2017 <- nflfastR::load_pbp(season = 2017)
pbp_2016 <- nflfastR::load_pbp(season = 2016)
pbp_2015 <- nflfastR::load_pbp(season = 2015)
pbp_2014 <- nflfastR::load_pbp(season = 2014)
pbp_2013 <- nflfastR::load_pbp(season = 2013)
pbp_2012 <- nflfastR::load_pbp(season = 2012)
pbp_2011 <- nflfastR::load_pbp(season = 2011)
pbp_2010 <- nflfastR::load_pbp(season = 2010)

pbp <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016)



#### WR tgt share & status ####

# activity stats
snap_counts <- load_snap_counts(seasons = 2016:2024) %>% rename(pfr_id = pfr_player_id) %>% filter(game_type == "REG")
rosters <- load_rosters(seasons = 2016:2024) %>% select(-c(game_type,week))
active_games <- left_join(snap_counts, rosters) %>% select(game_id, gsis_id, player, position, team, season, week, offense_snaps) %>% 
  rename(receiver_player_id = gsis_id, posteam = team) %>% 
  mutate(active = case_when(
    offense_snaps > 0 ~ 1,
    TRUE ~ 0
  )) %>% 
  mutate(receiver_player_id = case_when(
    player == "Jalen Coker" ~ "00-0039491",
    TRUE ~ receiver_player_id
  )) %>% group_by(receiver_player_id, season) %>% mutate(numGames = sum(active))

# team stats
team_pass_per_game <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG", play_type == "pass") %>%
  # team runs per game
  group_by(game_id, posteam) %>% summarize(numPass = sum(pass_attempt, na.rm = TRUE)) 

# player stats
player_tgt_per_game <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG", play_type == "pass") %>%
  # team runs per game
  group_by(game_id, posteam, receiver_player_id) %>% 
  summarize(numTgt = n(), numRec = sum(complete_pass,na.rm=TRUE), numYards = sum(yards_gained, na.rm = TRUE), numTD = sum(touchdown, na.rm=TRUE))

# tgt share and ranks
wr_tgt_share <- active_games %>% left_join(., team_pass_per_game) %>%
  left_join(., player_tgt_per_game) %>% 
  filter(position %in% c("RB", "TE", "WR")) %>%
  group_by(season, receiver_player_id, posteam) %>%
  mutate(numTgt = replace_na(numTgt, 0)) %>% mutate(numRec = replace_na(numRec, 0)) %>% mutate(numYards = replace_na(numYards, 0)) %>% mutate(numPass = replace_na(numPass, 0)) %>% mutate(numTD = replace_na(numTD, 0)) %>%
  summarize(player = first(player), numGames = first(numGames), tgt_share = sum(numTgt,na.rm=TRUE)/sum(numPass,na.rm=TRUE), numYards = sum(numYards,na.rm=TRUE), numTD = sum(numTD,na.rm=TRUE), numRec = sum(numRec,na.rm=TRUE)) %>%
  unique() %>% filter(numGames > 3) %>%
  # ranks
  group_by(posteam, season) %>% arrange(desc(numYards/numGames)) %>% mutate(yards_rank = row_number()) %>%
  arrange(desc(tgt_share)) %>% mutate(tgt_rank = row_number()) %>%
  arrange(desc(numTD)) %>% mutate(td_rank = row_number()) %>%
  mutate(avg = (yards_rank+tgt_rank)/2) %>% arrange(tgt_rank) %>% arrange(avg) %>% 
  mutate(wr_rank = row_number()) %>% 
  select(receiver_player_id, player, posteam, season, numGames, tgt_share, numYards, numTD, numRec, wr_rank)

#### RB rush share & status ####

# usage
snap_counts <- load_snap_counts(seasons = 2016:2024) %>% rename(pfr_id = pfr_player_id) %>% filter(game_type == "REG")
rosters <- load_rosters(seasons = 2016:2024) %>% select(-c(game_type,week))
active_games <- left_join(snap_counts, rosters) %>% select(game_id, gsis_id, player, position, team, season, week, offense_snaps) %>% 
  rename(rusher_player_id = gsis_id, posteam = team) %>% 
  mutate(active = case_when(
    offense_snaps > 0 ~ 1,
    TRUE ~ 0
  )) %>% group_by(rusher_player_id, season) %>% mutate(numGames = sum(active))

# team stats
team_rush_per_game <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG", play_type == "run") %>%
  # team runs per game
  group_by(game_id, posteam) %>% summarize(numRuns = sum(rush_attempt, na.rm = TRUE)) 

# player stats
player_rush_per_game <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG", play_type == "run") %>%
  # team runs per game
  group_by(game_id, posteam, rusher_player_id) %>% summarize(numRushes = sum(rush_attempt, na.rm = TRUE), numYards = sum(yards_gained, na.rm = TRUE), numTD = sum(touchdown, na.rm = TRUE))

# run share and ranks
rb_rush_share <- active_games %>% left_join(., team_rush_per_game) %>%
  left_join(., player_rush_per_game) %>% 
  filter(position %in% c("RB","QB", "TE", "WR")) %>%
  group_by(season, rusher_player_id, posteam) %>%
  mutate(numRushes = replace_na(numRushes, 0)) %>% mutate(numYards = replace_na(numYards, 0)) %>% mutate(numTD = replace_na(numTD, 0)) %>%
  summarize(player = first(player), numGames = first(numGames), run_share = sum(numRushes)/sum(numRuns), YPG = sum(numYards)/numGames, numTD = sum(numTD)) %>%
  unique() %>% na.omit() %>% filter(numGames > 3) %>%
  # ranks
  group_by(posteam, season) %>% arrange(desc(YPG)) %>% mutate(YPG_rank = row_number()) %>%
  arrange(desc(run_share)) %>% mutate(run_rank = row_number()) %>%
  mutate(avg = (YPG_rank+run_rank)/2) %>% arrange((run_rank)) %>% arrange((avg)) %>% 
  mutate(rb_rank = row_number()) %>% select(rusher_player_id, player, posteam, season, numGames, numTD, run_share, YPG, rb_rank)

#### WR rankings ####
WR_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(totalEPA = sum(epa,na.rm=TRUE), totalTD = sum(touchdown, na.rm=TRUE))

rz_rate <- pbp %>%
  filter(season_type == "REG", play_type == "pass", yardline_100 <= 20) %>% 
  group_by(receiver_player_id, season) %>%
  mutate(num_rz_opps = n(), conversion = round(sum(touchdown)/num_rz_opps, 3)) %>%
  summarise(receiver_player_id, receiver_player_name, season, posteam, num_rz_opps, conversion) %>% 
  unique() 

explosive_rate <- rbind(pbp_2016[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", play_type == "pass") %>%
  group_by(receiver_player_id, season) %>%
  mutate(numRec = n()) %>% filter(yards_gained >= 15) %>%
  mutate(explosive_rate = n()/numRec) %>% 
  summarise(receiver_player_id, receiver_player_name, season, posteam, explosive_rate) %>% 
  unique() 

third_down_rate <- pbp %>%
  filter(season_type == "REG", play_type == "pass", down == 3) %>%
  group_by(receiver_player_id, season) %>%
  summarize(
    third_down_targets = n(),
    third_down_conversions = sum(first_down_pass, na.rm = TRUE),
    third_down_rate = third_down_conversions / third_down_targets
  )

WR_ngs <- load_nextgen_stats(stat_type = "receiving") %>% 
  rename(receiver_player_id = player_gsis_id) %>% 
  select(receiver_player_id, player_position, season, week, avg_separation, avg_intended_air_yards, catch_percentage, avg_yac_above_expectation) %>%
  group_by(season, player_position, receiver_player_id) %>%
  summarise(avg_separation = mean(avg_separation, na.rm=TRUE), avg_intended_air_yards = mean(avg_intended_air_yards,na.rm=TRUE), catch_percentage = mean(catch_percentage, na.rm=TRUE), yac_above_expected = mean(avg_yac_above_expectation, na.rm=TRUE))


WR_ranks <- left_join(WR_ranks, wr_tgt_share) %>% left_join(.,rz_rate) %>% left_join(.,explosive_rate) %>% left_join(.,WR_ngs) %>% left_join(.,third_down_rate) %>%
  filter(player_position == "WR") %>%
  group_by(season) %>% 
  mutate(
    EPA_rank = percent_rank(totalEPA), 
    tgt_rank = percent_rank(tgt_share), 
    YPG_rank = percent_rank(numYards/numGames), 
    td_rank = percent_rank(totalTD/numGames), 
    conversion_rank = percent_rank(conversion), 
    explosive_rank = percent_rank(explosive_rate), 
    sep_rank = percent_rank(avg_separation), 
    intended_air_rank = percent_rank(avg_intended_air_yards), 
    catch_rank = percent_rank(catch_percentage), 
    third_down_rank = percent_rank(third_down_rate), 
    yacOE_rank = percent_rank(yac_above_expected)
  ) %>%
  arrange(desc(totalEPA)) %>% mutate(EPA_rank_num = row_number()) %>%
  arrange(desc(tgt_share)) %>% mutate(tgt_rank_num = row_number()) %>%
  arrange(desc(numYards/numGames)) %>% mutate(YPG_rank_num = row_number()) %>%
  arrange(desc(totalTD/numGames)) %>% mutate(td_rank_num = row_number()) %>%
  arrange(desc(conversion)) %>% mutate(conversion_rank_num = row_number()) %>%
  arrange(desc(explosive_rate)) %>% mutate(explosive_rank_num = row_number()) %>%
  arrange(desc(avg_separation)) %>% mutate(sep_rank_num = row_number()) %>%
  arrange(desc(avg_intended_air_yards)) %>% mutate(intended_air_rank_num = row_number()) %>%
  arrange(desc(catch_percentage)) %>% mutate(catch_rank_num = row_number()) %>%
  arrange(desc(third_down_rate)) %>% mutate(third_down_rank_num = row_number()) %>%
  arrange(desc(yac_above_expected)) %>% mutate(yacOE_rank_num = row_number()) %>%
  unique() %>% group_by(receiver_player_id, receiver_player_name, posteam, season) %>% arrange(desc(EPA_rank)) %>% #head(20)
  # consensus rank calc
  mutate(myRank = 
           0.2*tgt_rank +
           0.2*YPG_rank +
           0.1*EPA_rank +
           0.15*td_rank +
           0.1*explosive_rank +
           0.1*yacOE_rank +
           0.05*catch_rank +
           0.05*sep_rank +
           0.05*third_down_rate) %>% 
  unique() %>% arrange(desc(myRank)) %>% 
  group_by(season) %>% mutate(myRankNum = row_number()) %>%
  mutate(wrTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  )) 

# Prepare data for Firebase with proper field mappings
WR_ranks_final <- WR_ranks %>%
  mutate(
    # Map field names to match UI expectations
    receiver_player_name = coalesce(receiver_player_name, "Unknown"),
    team = coalesce(posteam, "Unknown"),
    player_position = "WR",
    # Add tier field mapping
    tier = wrTier,
    # Ensure all numeric fields are properly formatted
    totalEPA = round(totalEPA, 2),
    totalTD = round(totalTD, 0),
    tgt_share = round(tgt_share, 4),
    numYards = round(numYards, 0),
    numRec = round(numRec, 0),
    conversion = round(conversion, 3),
    explosive_rate = round(explosive_rate, 3),
    avg_separation = round(avg_separation, 2),
    avg_intended_air_yards = round(avg_intended_air_yards, 2),
    catch_percentage = round(catch_percentage, 3),
    yac_above_expected = round(yac_above_expected, 2),
    third_down_rate = round(third_down_rate, 3),
    myRank = round(myRank, 4)
  ) %>%
  # Select and order columns for consistency
  select(
    receiver_player_id,
    receiver_player_name,
    team,
    posteam,
    season,
    player_position,
    numGames,
    myRankNum,
    myRank,
    wrTier,
    tier,
    totalEPA,
    totalTD,
    tgt_share,
    numYards,
    numRec,
    conversion,
    explosive_rate,
    avg_separation,
    avg_intended_air_yards,
    catch_percentage,
    yac_above_expected,
    third_down_rate,
    EPA_rank,
    td_rank,
    tgt_rank,
    YPG_rank,
    conversion_rank,
    explosive_rank,
    sep_rank,
    intended_air_rank,
    catch_rank,
    third_down_rank,
    yacOE_rank,
    # Numbered rank fields
    EPA_rank_num,
    td_rank_num,
    tgt_rank_num,
    YPG_rank_num,
    conversion_rank_num,
    explosive_rank_num,
    sep_rank_num,
    intended_air_rank_num,
    catch_rank_num,
    third_down_rank_num,
    yacOE_rank_num
  ) %>%
  arrange(myRankNum)

# Save to JSON
wr_rankings_json <- toJSON(WR_ranks_final, pretty = TRUE, auto_unbox = TRUE)
write(wr_rankings_json, file = "/Users/jackgruca/Documents/GitHub/mds_home/data_processing/wr_rankings.json")

print(paste("Processed", nrow(WR_ranks_final), "WR rankings and saved to wr_rankings.json"))