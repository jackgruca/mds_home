
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

#### QB ranks ####

# QB passing stats 
QB_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(passer_player_id, posteam, season) %>% 
  filter(season_type == "REG", pass_attempt == 1, sum(pass_attempt) > 60) %>%
  summarise(passer_player_name = min(passer_player_name), numGames= n_distinct(game_id), numPass = sum(pass_attempt), totalEPA = sum(epa,na.rm=TRUE), totalEP = sum(ep,na.rm=TRUE), avgCPOE = mean(cpoe,na.rm=TRUE), YPG = sum(yards_gained)/n_distinct(game_id), TDperGame = sum(touchdown)/n_distinct(game_id), intPerGame = sum(interception)/n_distinct(game_id), thirdConvert = sum(third_down_converted)/(sum(third_down_converted)+sum(third_down_failed)), actualization = (sum(yards_gained,na.rm=TRUE)/n())/mean(air_yards,na.rm=TRUE) ) %>% 
  arrange(desc(thirdConvert)) %>% unique()
#ungroup() %>% mutate(EPA_rank = percent_rank(totalEPA), EP_rank = percent_rank(totalEP), CPOE_rank = percent_rank(avgCPOE), YPG_rank = percent_rank(YPG), TD_rank = percent_rank(TDperGame), third_rank = percent_rank(thirdConvert)) %>%
#unique() %>% group_by(passer_player_id, passer_player_name) %>% summarise(myRank = CPOE_rank+YPG_rank+TD_rank+third_rank) %>% unique() %>% arrange(desc(myRank)) %>% head(18)

QB_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(rtotalEPA = sum(epa,na.rm=TRUE), rtotalEP = sum(ep,na.rm=TRUE), rYPG = sum(yards_gained)/n_distinct(game_id), rTDperGame = sum(touchdown)/n_distinct(game_id), rthirdConvert = sum(third_down_converted)/(sum(third_down_converted)+sum(third_down_failed))) %>%# arrange(desc(avgCPOE)) %>% unique()
  # now combine the 2
  rename(passer_player_id = rusher_player_id, passer_player_name = rusher_player_name) %>%
  left_join(QB_ranks,.) %>% group_by(passer_player_id, passer_player_name, posteam, season) %>% 
  # combined ranks
  summarise(numGames = first(numGames), ctotalEPA = totalEPA+rtotalEPA, ctotalEP = totalEP+rtotalEP, cCPOE = unique(avgCPOE), cactualization = unique(actualization), cYPG = rYPG+YPG, cTDperGame = TDperGame+rTDperGame, intPerGame = unique(intPerGame), cthirdConvert = mean(c(thirdConvert, rthirdConvert))) %>% 
  # get percentiles and numbered ranks
  group_by(season) %>% 
  mutate(
    EPA_rank = percent_rank(ctotalEPA), 
    EP_rank = percent_rank(ctotalEP), 
    CPOE_rank = percent_rank(cCPOE), 
    YPG_rank = percent_rank(cYPG), 
    TD_rank = percent_rank(cTDperGame), 
    actualization_rank = percent_rank(cactualization), 
    int_rank = percent_rank(intPerGame), 
    third_rank = percent_rank(cthirdConvert)
  ) %>%
  arrange(desc(ctotalEPA)) %>% mutate(EPA_rank_num = row_number()) %>%
  arrange(desc(ctotalEP)) %>% mutate(EP_rank_num = row_number()) %>%
  arrange(desc(cCPOE)) %>% mutate(CPOE_rank_num = row_number()) %>%
  arrange(desc(cYPG)) %>% mutate(YPG_rank_num = row_number()) %>%
  arrange(desc(cTDperGame)) %>% mutate(TD_rank_num = row_number()) %>%
  arrange(desc(cactualization)) %>% mutate(actualization_rank_num = row_number()) %>%
  arrange(intPerGame) %>% mutate(int_rank_num = row_number()) %>%
  arrange(desc(cthirdConvert)) %>% mutate(third_rank_num = row_number()) %>%
  unique() %>% group_by(passer_player_id, passer_player_name, posteam, season) %>% arrange(desc(cactualization)) %>% #head(20)
  # consensus rank calc
  mutate(numGames = first(numGames), 
         myRank = (
           .25*EPA_rank+
           .2*TD_rank+
           .15*YPG_rank+
           .1*third_rank+
           .1*actualization_rank+
           .1*CPOE_rank+
           .1*(1-int_rank))) %>% 
  unique() %>% arrange(desc(myRank)) %>% 
  group_by(season) %>% mutate(myRankNum = row_number()) %>%
  mutate(qbTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  )) %>% group_by(posteam, season) %>% mutate(teamQBTier = round(sum(numGames*qbTier)/sum(numGames),0))

# Prepare data for Firebase with proper field mappings
QB_ranks_final <- QB_ranks %>%
  mutate(
    # Map field names to match UI expectations
    passer_player_name = coalesce(passer_player_name, "Unknown"),
    team = coalesce(posteam, "Unknown"),
    player_position = "QB",
    # Add tier field mapping
    tier = qbTier,
    # Ensure all numeric fields are properly formatted
    numGames = round(numGames, 0),
    myRank = round(myRank, 4),
    myRankNum = round(myRankNum, 0),
    qbTier = round(qbTier, 0),
    teamQBTier = round(teamQBTier, 0),
    # Format all the combined stats
    ctotalEPA = round(coalesce(ctotalEPA, 0), 2),
    ctotalEP = round(coalesce(ctotalEP, 0), 2),
    cCPOE = round(coalesce(cCPOE, 0), 3),
    cactualization = round(coalesce(cactualization, 0), 3),
    cYPG = round(coalesce(cYPG, 0), 1),
    cTDperGame = round(coalesce(cTDperGame, 0), 2),
    intPerGame = round(coalesce(intPerGame, 0), 2),
    cthirdConvert = round(coalesce(cthirdConvert, 0), 3),
    # Format all rank fields
    EPA_rank = round(coalesce(EPA_rank, 0), 4),
    EP_rank = round(coalesce(EP_rank, 0), 4),
    CPOE_rank = round(coalesce(CPOE_rank, 0), 4),
    YPG_rank = round(coalesce(YPG_rank, 0), 4),
    TD_rank = round(coalesce(TD_rank, 0), 4),
    actualization_rank = round(coalesce(actualization_rank, 0), 4),
    int_rank = round(coalesce(int_rank, 0), 4),
    third_rank = round(coalesce(third_rank, 0), 4)
  ) %>%
  # Select and order columns for consistency
  select(
    passer_player_id,
    passer_player_name,
    team,
    posteam,
    season,
    player_position,
    numGames,
    myRankNum,
    myRank,
    qbTier,
    tier,
    teamQBTier,
    # Combined stats
    ctotalEPA,
    ctotalEP,
    cCPOE,
    cactualization,
    cYPG,
    cTDperGame,
    intPerGame,
    cthirdConvert,
    # Rank fields (percentiles)
    EPA_rank,
    EP_rank,
    CPOE_rank,
    YPG_rank,
    TD_rank,
    actualization_rank,
    int_rank,
    third_rank,
    # Numbered rank fields
    EPA_rank_num,
    EP_rank_num,
    CPOE_rank_num,
    YPG_rank_num,
    TD_rank_num,
    actualization_rank_num,
    int_rank_num,
    third_rank_num
  ) %>%
  arrange(myRankNum)

# Save to JSON
qb_rankings_json <- toJSON(QB_ranks_final, pretty = TRUE, auto_unbox = TRUE)
write(qb_rankings_json, file = "/Users/jackgruca/Documents/GitHub/mds_home/data_processing/qb_rankings.json")

print(paste("Processed", nrow(QB_ranks_final), "QB rankings and saved to qb_rankings.json"))