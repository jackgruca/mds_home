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
  select(receiver_player_id, player, posteam, season, tgt_share, wr_rank)

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
  mutate(rb_rank = row_number()) %>% select(rusher_player_id, player, posteam, season, run_share, rb_rank)

#### RB Ranks ####
RB_stats <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(numGames = n_distinct(game_id), totalEPA = sum(epa,na.rm=TRUE), totalTD = sum(touchdown, na.rm=TRUE), numRush = n(), numYards = sum(yards_gained,na.rm=TRUE),
            numFD = sum(first_down,na.rm=TRUE), yardsPerRush = numYards/numRush, rushPerGame = numRush/numGames, YPG = numYards/numGames)

rz_rate <- pbp %>%
  filter(season_type == "REG", play_type == "run", yardline_100 <= 20) %>% 
  group_by(fantasy_player_id, season) %>%
  mutate(num_rz_opps = n(), conversion = round(sum(touchdown)/num_rz_opps, 3)) %>%
  summarise(fantasy_player_id, fantasy_player_name, season, posteam, num_rz_opps, conversion) %>% 
  unique() 

explosive_rate <- pbp %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(fantasy_player_id, season) %>%
  mutate(numRush = n()) %>% filter(yards_gained >= 15) %>%
  mutate(explosive_rate = n()/numRush) %>% 
  summarise(fantasy_player_id, fantasy_player_name, season, posteam, explosive_rate) %>% 
  unique() 

third_down_rate <- pbp %>%
  filter(season_type == "REG", play_type == "run", down == 3) %>%
  group_by(fantasy_player_id, season) %>%
  summarize(
    third_down_att = n(),
    third_down_conversions = sum(first_down_rush, na.rm = TRUE),
    third_down_rate = third_down_conversions / third_down_att
  )

RB_ngs <- load_nextgen_stats(stat_type = "rushing") %>% 
  rename(fantasy_player_id = player_gsis_id) %>% 
  select(fantasy_player_id, player_position, season, week, efficiency, rush_yards_over_expected_per_att) %>%
  group_by(season, player_position, fantasy_player_id) %>%
  summarise(avg_eff = mean(efficiency, na.rm=TRUE), avg_RYOE_perAtt = mean(rush_yards_over_expected_per_att,na.rm=TRUE))


RB_ranks <- left_join(RB_stats, rb_rush_share, by = join_by(posteam, season, fantasy_player_id == rusher_player_id)) %>% 
  left_join(.,wr_tgt_share[,c(1,3,4,5,6)], by = join_by(posteam, season, fantasy_player_id == receiver_player_id)) %>% 
  left_join(.,rz_rate) %>% left_join(.,explosive_rate) %>% left_join(.,RB_ngs) %>% left_join(.,third_down_rate) %>%
  filter(player_position == "RB") %>%
  group_by(season) %>% mutate(EPA_rank = percent_rank(totalEPA), td_rank = percent_rank(totalTD/numGames), run_rank = percent_rank(run_share), 
                              tgt_rank = percent_rank(tgt_share), YPG_rank = percent_rank(YPG), third_rank = percent_rank(third_down_rate), 
                              conversion_rank = percent_rank(conversion), explosive_rank = percent_rank(explosive_rate), RYOE_rank = percent_rank(avg_RYOE_perAtt), 
                              eff_rank = percent_rank(-avg_eff)) %>%
  unique() %>% group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% arrange(desc(EPA_rank)) %>%
  # consensus rank calc
  mutate(myRank = 
           0.15*EPA_rank +
           0.15*run_rank +
           0.15*YPG_rank +
           0.15*td_rank +
           0.1*explosive_rank +
           0.1*RYOE_rank +
           0.1*third_down_rate +
           0.05*eff_rank +
           0.05*tgt_rank) %>% 
  unique() %>% arrange(desc(myRank)) %>% 
  group_by(season) %>% mutate(myRankNum = row_number()) %>%
  mutate(RB_tier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  ))

# Prepare data for CSV with proper field mappings
RB_ranks_final <- RB_ranks %>%
  mutate(
    # Map field names to match UI expectations
    fantasy_player_name = coalesce(fantasy_player_name, player, "Unknown"),
    team = coalesce(posteam, "Unknown"),
    player_position = "RB",
    # Add tier field mapping
    tier = RB_tier,
    # Calculate additional per-game stats for UI display
    rushPerGame = round(numRush / numGames, 1),
    yardsPerGame = round(YPG, 1),
    tdPerGame = round(totalTD / numGames, 2),
    FDperRush = round(numFD / numRush, 3),
    # Receiving stats (from wr_tgt_share)
    recYards = coalesce(numYards.y, 0),  # Receiving yards
    recTD = coalesce(numTD.y, 0),  # Receiving TDs
    numRec = coalesce(numRec, 0),  # Receptions
    numTgt = round(coalesce(tgt_share, 0) * numGames * 35, 0),  # Estimate targets
    recPerGame = round(numRec / numGames, 1),
    tgtPerGame = round(numTgt / numGames, 1),
    recYardsPerGame = round(recYards / numGames, 1),
    avgEPA = round(totalEPA / numRush, 3),
    # Calculate catch percentage for receiving
    catchPct = round(ifelse(numTgt > 0, numRec / numTgt, 0), 3),
    # YAC calculation
    YAC = round(ifelse(numRec > 0, recYards / numRec, 0), 2),
    # Ensure all numeric fields are properly formatted with appropriate decimals
    totalEPA = round(totalEPA, 2),
    totalTD = round(totalTD, 0),
    numRush = round(numRush, 0),
    numYards = round(numYards.x, 0),  # Rushing yards
    numFD = round(numFD, 0),
    yardsPerRush = round(yardsPerRush, 2),
    run_share = round(coalesce(run_share, 0), 4),
    tgt_share = round(coalesce(tgt_share, 0), 4),
    conversion = round(coalesce(conversion, 0), 3),
    explosive_rate = round(coalesce(explosive_rate, 0), 3),
    avg_eff = round(coalesce(avg_eff, 0), 2),
    avg_RYOE_perAtt = round(coalesce(avg_RYOE_perAtt, 0), 2),
    third_down_att = round(coalesce(third_down_att, 0), 0),
    third_down_conversions = round(coalesce(third_down_conversions, 0), 0),
    third_down_rate = round(coalesce(third_down_rate, 0), 3),
    myRank = round(myRank, 4),
    num_rz_opps = round(coalesce(num_rz_opps, 0), 0),
    # Receiving stats properly formatted
    numRec = round(numRec, 0),
    numTgt = round(numTgt, 0),
    recYards = round(recYards, 0),
    recTD = round(recTD, 0),
    recPerGame = round(recPerGame, 1),
    tgtPerGame = round(tgtPerGame, 1),
    recYardsPerGame = round(recYardsPerGame, 1),
    catchPct = round(catchPct, 3),
    YAC = round(YAC, 2)
  ) %>%
  # Select and order columns for consistency
  select(
    fantasy_player_id,
    fantasy_player_name,
    team,
    posteam,
    season,
    player_position,
    numGames,
    myRankNum,
    myRank,
    tier,
    RB_tier,
    rb_rank,
    # Basic rushing stats (for UI display)
    numRush,
    numYards,
    totalTD,
    yardsPerRush,
    rushPerGame,
    yardsPerGame,
    tdPerGame,
    numFD,
    FDperRush,
    # Receiving stats
    numTgt,
    numRec,
    recYards,
    recTD,
    tgtPerGame,
    recPerGame,
    recYardsPerGame,
    catchPct,
    YAC,
    # Advanced stats
    totalEPA,
    avgEPA,
    run_share,
    tgt_share,
    conversion,
    num_rz_opps,
    explosive_rate,
    avg_eff,
    avg_RYOE_perAtt,
    third_down_att,
    third_down_conversions,
    third_down_rate,
    # Rank percentiles
    EPA_rank,
    td_rank,
    run_rank,
    tgt_rank,
    YPG_rank,
    conversion_rank,
    explosive_rank,
    RYOE_rank,
    eff_rank,
    third_rank
  ) %>%
  arrange(myRankNum)

# Save to JSON (keep for backward compatibility)
rb_rankings_json <- toJSON(RB_ranks_final, pretty = TRUE, auto_unbox = TRUE)
write(rb_rankings_json, file = "/Users/jackgruca/Documents/GitHub/mds_home/data_processing/rb_rankings.json")

# Save to CSV for new Flutter CSV service
write_csv(RB_ranks_final, file = "/Users/jackgruca/Documents/GitHub/mds_home/data/processed/player_stats/rb_season_stats.csv")

print(paste("Processed", nrow(RB_ranks_final), "RB rankings and saved to rb_rankings.json and rb_season_stats.csv"))