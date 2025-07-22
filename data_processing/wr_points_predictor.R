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


#### player years ####

# receivers
playerYear <- rbind(pbp_2016[c(174,175,286)], pbp_2017[c(174,175,286)], pbp_2018[c(174,175,286)], pbp_2019[c(174,175,286)], pbp_2020[c(174,175,286)], pbp_2021[c(174,175,286)], pbp_2022[c(174,175,286)], pbp_2023[c(174,175,286)], pbp_2024[c(174,175,286)]) %>%
  group_by(receiver_player_id) %>% 
  summarise(season)  %>% unique() %>% mutate(playerYear = row_number()) %>%
  mutate(playerYearTier = case_when(
    playerYear == 1 ~ "rookie",
    playerYear == 2 ~ "2nd year",
    playerYear == 3 ~ "3rd year",
    playerYear == 4 ~ "4th year",
    (playerYear >= 5 & playerYear < 8) ~ "contract #2",
    playerYear >= 8 ~ "contract #3"
  )) #%>% slice_tail()

# rbs
playerYear_rb <- rbind(pbp_2016[c(177,178,286)], pbp_2017[c(177,178,286)], pbp_2018[c(177,178,286)], pbp_2019[c(177,178,286)], pbp_2020[c(177,178,286)], pbp_2021[c(177,178,286)], pbp_2022[c(177,178,286)], pbp_2023[c(177,178,286)], pbp_2024[c(177,178,286)]) %>%
  group_by(rusher_player_id) %>% 
  summarise(season)  %>% unique() %>% mutate(playerYear = row_number()) %>%
  mutate(playerYearTier = case_when(
    playerYear == 1 ~ "rookie",
    playerYear == 2 ~ "2nd year",
    playerYear == 3 ~ "3rd year",
    playerYear == 4 ~ "4th year",
    (playerYear >= 5 & playerYear < 8) ~ "contract #2",
    playerYear >= 8 ~ "contract #3"
  )) 


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

third_down_rate <- pbp_data %>%
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
  group_by(season) %>% mutate(EPA_rank = percent_rank(totalEPA), tgt_rank = percent_rank(tgt_share), YPG_rank = percent_rank(numYards/numGames), td_rank = percent_rank(totalTD/numGames), conversion_rank = percent_rank(conversion), explosive_rank = percent_rank(explosive_rate), sep_rank = percent_rank(avg_separation), intended_air_rank = percent_rank(avg_intended_air_yards), catch_rank = percent_rank(catch_percentage), third_down_rank = percent_rank(third_down_rate), yacOE_rank = percent_rank(yac_above_expected)) %>%
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
  mutate(qbTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  )) 

#### TE rankings ####
TE_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
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

TE_ngs <- load_nextgen_stats(stat_type = "receiving") %>% 
  rename(receiver_player_id = player_gsis_id) %>% 
  select(receiver_player_id, player_position, season, week, avg_separation, avg_intended_air_yards, catch_percentage, avg_yac_above_expectation) %>%
  group_by(season, player_position, receiver_player_id) %>%
  summarise(avg_separation = mean(avg_separation, na.rm=TRUE), avg_intended_air_yards = mean(avg_intended_air_yards,na.rm=TRUE), catch_percentage = mean(catch_percentage, na.rm=TRUE), yac_above_expected = mean(avg_yac_above_expectation, na.rm=TRUE))


TE_ranks <- left_join(TE_ranks, wr_tgt_share) %>% left_join(.,rz_rate) %>% left_join(.,explosive_rate) %>% left_join(.,TE_ngs) %>% left_join(.,third_down_rate) %>%
  filter(player_position == "TE") %>%
  group_by(season) %>% mutate(EPA_rank = percent_rank(totalEPA), td_rank = percent_rank(totalTD/numGames), tgt_rank = percent_rank(tgt_share), YPG_rank = percent_rank(numYards/numGames), conversion_rank = percent_rank(conversion), explosive_rank = percent_rank(explosive_rate), sep_rank = percent_rank(avg_separation), intended_air_rank = percent_rank(avg_intended_air_yards), catch_rank = percent_rank(catch_percentage), third_down_rank = percent_rank(third_down_rate), yacOE_rank = percent_rank(yac_above_expected)) %>%
  unique() %>% group_by(receiver_player_id, receiver_player_name, posteam, season) %>% arrange(desc(EPA_rank)) %>% #head(20)
  # consensus rank calc
  mutate(myRank = 
           0.25*tgt_rank +
           0.25*YPG_rank +
           0.15*EPA_rank +
           0.1*yacOE_rank +
           0.1*third_down_rate +
           0.05*td_rank +
           0.05*explosive_rank +
           0.05*sep_rank) %>% 
  unique() %>% arrange(desc(myRank)) %>% 
  group_by(season) %>% mutate(myRankNum = row_number()) %>%
  mutate(TE_tier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  )) 

#### RB Ranks ####
RB_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(totalEPA = sum(epa,na.rm=TRUE), totalTD = sum(touchdown, na.rm=TRUE))

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

third_down_rate <- pbp_data %>%
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


RB_ranks <- left_join(RB_ranks, rb_rush_share, by = join_by(posteam, season, fantasy_player_id == receiver_player_id)) %>% left_join(.,wr_tgt_share[,c(1,3,4,6)], by = join_by(posteam, season, fantasy_player_id == receiver_player_id)) %>% left_join(.,rz_rate) %>% left_join(.,explosive_rate) %>% left_join(.,RB_ngs) %>% left_join(.,third_down_rate) %>%
  filter(player_position == "RB") %>%
  group_by(season) %>% mutate(EPA_rank = percent_rank(totalEPA), td_rank = percent_rank(totalTD/numGames), run_rank = percent_rank(run_share), tgt_rank = percent_rank(tgt_share), YPG_rank = percent_rank(YPG), third_rank = percent_rank(third_down_rate), conversion_rank = percent_rank(conversion), explosive_rank = percent_rank(explosive_rate), RYOE_rank = percent_rank(avg_RYOE_perAtt), eff_rank = percent_rank(-avg_eff)) %>%
  unique() %>% group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% arrange(desc(EPA_rank)) %>% #head(20)
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
  mutate(qbTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  )) #%>% filter(season == 2024) %>% arrange(desc(third_rank))




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
  summarise(totalEP = sum(ep,na.rm=TRUE), totalYds = sum(yards_gained, na.rm=TRUE), totalTD = sum(touchdown,na.rm=TRUE), successRate = mean(success)) %>% 
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
  summarise(totalEP = sum(ep,na.rm=TRUE), totalYds = sum(yards_gained, na.rm=TRUE), totalTD = sum(touchdown,na.rm=TRUE), successRate = mean(success)) %>% 
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


#### oline ranks ####
oline_2024 <- read_csv("Downloads/PFF Team Grades - 2024.csv") %>% mutate(season = 2024)
oline_2023 <- read_csv("Downloads/PFF Team Grades - 2023.csv") %>% mutate(season = 2023)
oline_2022 <- read_csv("Downloads/PFF Team Grades - 2022.csv") %>% mutate(season = 2022)
oline_2021 <- read_csv("Downloads/PFF Team Grades - 2021.csv") %>% mutate(season = 2021)
oline_2020 <- read_csv("Downloads/PFF Team Grades - 2020.csv") %>% mutate(season = 2020)
oline_2019 <- read_csv("Downloads/PFF Team Grades - 2019.csv") %>% mutate(season = 2019)
oline_2018 <- read_csv("Downloads/PFF Team Grades - 2018.csv") %>% mutate(season = 2018)
oline_2017 <- read_csv("Downloads/PFF Team Grades - 2017.csv") %>% mutate(season = 2017)
oline_2016 <- read_csv("Downloads/PFF Team Grades - 2016.csv") %>% mutate(season = 2016)
oline_2015 <- read_csv("Downloads/PFF Team Grades - 2015.csv") %>% mutate(season = 2015)
oline_2014 <- read_csv("Downloads/PFF Team Grades - 2014.csv") %>% mutate(season = 2014)
oline_2013 <- read_csv("Downloads/PFF Team Grades - 2013.csv") %>% mutate(season = 2013)
oline_2012 <- read_csv("Downloads/PFF Team Grades - 2012.csv") %>% mutate(season = 2012)
oline_2011 <- read_csv("Downloads/PFF Team Grades - 2011.csv") %>% mutate(season = 2011)
oline_2010 <- read_csv("Downloads/PFF Team Grades - 2010.csv") %>% mutate(season = 2010)
oline_2009 <- read_csv("Downloads/PFF Team Grades - 2009.csv") %>% mutate(season = 2009)
oline_2008 <- read_csv("Downloads/PFF Team Grades - 2008.csv") %>% mutate(season = 2008)
oline_2007 <- read_csv("Downloads/PFF Team Grades - 2007.csv") %>% mutate(season = 2007)
oline_2006 <- read_csv("Downloads/PFF Team Grades - 2006.csv") %>% mutate(season = 2006)

oline_ranks_pff <- rbind(oline_2006, oline_2007, oline_2008, oline_2009, oline_2010, oline_2011, oline_2012, oline_2013, oline_2014, oline_2015, oline_2016, oline_2017, oline_2018, oline_2019, oline_2020, oline_2021, oline_2022, oline_2023, oline_2024) %>%
  group_by(season) %>% arrange(desc(PBLK)) %>% mutate(passBlock_rank = row_number()) %>%
  arrange(desc(RBLK)) %>% mutate(runBlock_rank = row_number()) %>% 
  mutate(runBlock_tier = case_when(
    runBlock_rank <= 4 ~ 1,
    runBlock_rank <= 8 ~ 2,
    runBlock_rank <= 12 ~ 3,
    runBlock_rank <= 16 ~ 4,
    runBlock_rank <= 20 ~ 5,
    runBlock_rank <= 24 ~ 6,
    runBlock_rank <= 28 ~ 7,
    TRUE ~ 8
  )) %>%
  mutate(passBlock_tier = case_when(
    passBlock_rank <= 4 ~ 1,
    passBlock_rank <= 8 ~ 2,
    passBlock_rank <= 12 ~ 3,
    passBlock_rank <= 16 ~ 4,
    passBlock_rank <= 20 ~ 5,
    passBlock_rank <= 24 ~ 6,
    passBlock_rank <= 28 ~ 7,
    TRUE ~ 8
  )) %>%
  mutate(posteam = case_when(
    team == "Arizona Cardinals"   ~ "ARI",
    team == "Atlanta Falcons"     ~ "ATL",
    team == "Baltimore Ravens"    ~ "BAL",
    team == "Buffalo Bills"       ~ "BUF",
    team == "Carolina Panthers"   ~ "CAR",
    team == "Chicago Bears"       ~ "CHI",
    team == "Cincinnati Bengals"  ~ "CIN",
    team == "Cleveland Browns"    ~ "CLE",
    team == "Dallas Cowboys"      ~ "DAL",
    team == "Denver Broncos"      ~ "DEN",
    team == "Detroit Lions"       ~ "DET",
    team == "Green Bay Packers"   ~ "GB",
    team == "Houston Texans"      ~ "HOU",
    team == "Indianapolis Colts"  ~ "IND",
    team == "Jacksonville Jaguars"~ "JAX",
    team == "Kansas City Chiefs"  ~ "KC",
    team == "Las Vegas Raiders"   ~ "LV",
    team == "Los Angeles Chargers"~ "LAC",
    team == "Los Angeles Rams"    ~ "LAR",
    team == "Miami Dolphins"      ~ "MIA",
    team == "Minnesota Vikings"   ~ "MIN",
    team == "New England Patriots"~ "NE",
    team == "New Orleans Saints"  ~ "NO",
    team == "New York Giants"     ~ "NYG",
    team == "New York Jets"       ~ "NYJ",
    team == "Philadelphia Eagles" ~ "PHI",
    team == "Pittsburgh Steelers" ~ "PIT",
    team == "San Francisco 49ers" ~ "SF",
    team == "Seattle Seahawks"    ~ "SEA",
    team == "Tampa Bay Buccaneers"~ "TB",
    team == "Tennessee Titans"    ~ "TEN",
    team == "Washington Commanders" ~ "WAS",
    team == "Washington Football Team" ~ "WAS",
    team == "Washington Redskins" ~ "WAS",
    team == "San Diego Chargers" ~ "LAC",
    team == "Oakland Raiders" ~ "LV",
    team == "St. Louis Rams" ~ "LA",
    TRUE ~ NA_character_  # fallback if unmatched
  ))
  


#### get LY TDs (useless now) ####
wr_TDs <- rbind(pbp_2016[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2017[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2018[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2019[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2020[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2021[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2022[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2023[,c(2,8,174,175,286,155,6,29,156,165)], pbp_2024[,c(2,8,174,175,286,155,6,29,156,165)]) %>%
  filter(season_type == "REG", play_type == "pass") %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>%
  summarise(numTD = sum(pass_touchdown), numRec = sum(complete_pass), numGames = n_distinct(game_id)) %>% arrange(desc(numTD)) 

rb_TDs <- rbind(pbp_2016[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>%
  summarise(numRushTD = sum(rush_touchdown), numGames = n_distinct(game_id)) %>% arrange(desc(numRushTD)) 



#### experimental predictors ####
which(names(pbp_2016) == "yards_gained")
# explosive play
explosive_rate <- rbind(pbp_2016[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(rusher_player_id, season) %>%
  mutate(numRush = n()) %>% filter(yards_gained >= 15) %>%
  mutate(explosive_rate = n()/numRush) %>% 
  summarise(rusher_player_id, rusher_player_name, season, posteam, numRush, explosive_rate) %>% 
  unique() %>% rename(receiver_player_id = rusher_player_id, receiver_player_name = rusher_player_name)

# try for WR
explosive_rate <- rbind(pbp_2016[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", play_type == "pass") %>%
  group_by(receiver_player_id, season) %>%
  mutate(numRec = n()) %>% filter(yards_gained >= 15, posteam != "NYJ") %>%
  mutate(explosive_rate = n()/numRec) %>% 
  summarise(receiver_player_id, receiver_player_name, season, posteam, numRec, explosive_rate) %>% 
  unique() 

# RZ conversion
rz_rate <- rbind(pbp_2016[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", goal_to_go == 1, play_type == "run") %>% 
  group_by(rusher_player_id, season) %>%
  mutate(num_gtg = n(), conversion = round(sum(touchdown)/num_gtg, 3)) %>%
  summarise(rusher_player_id, rusher_player_name, season, posteam, num_gtg, conversion) %>% 
  unique() %>% rename(receiver_player_id = rusher_player_id, receiver_player_name = rusher_player_name)

# WR RZ conversion
rz_rate <- rbind(pbp_2016[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", goal_to_go == 1, play_type == "pass") %>% 
  group_by(receiver_player_id, season) %>%
  mutate(num_gtg = n(), conversion = round(sum(touchdown)/num_gtg, 3)) %>%
  summarise(receiver_player_id, receiver_player_name, season, posteam, num_gtg, conversion) %>% 
  unique() #%>% filter(num_gtg > 7, season == 2024, !is.na(receiver_player_name)) %>% ungroup() %>% summarize(avg = mean(conversion))

# 4th down att
fourth_downer <- rbind(pbp_2016[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)],pbp_2017[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)],pbp_2018[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)],pbp_2019[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)],pbp_2020[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)],pbp_2021[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)],pbp_2022[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)],pbp_2023[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)], pbp_2024[,c(2,8,22,23,30,174,175,177,178,286,155,6,29,157,165,341)]) %>%
  filter(season_type == "REG", down == 4, play_type == "run", !is.na(rusher_player_name)) %>% 
  group_by(rusher_player_id, season) %>%
  mutate(num_att = n(), conversion = round(sum(success)/num_att, 3)) %>%
  summarise(rusher_player_id, rusher_player_name, season, posteam, num_att, conversion) %>% 
  unique() #%>% filter(num_gtg > 7, season == 2024, !is.na(receiver_player_name)) %>% ungroup() %>% summarize(avg = mean(conversion))

which(names(pbp_2016) == "success")

# last year team rushes
run_volume <- rbind(pbp_2016[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(posteam, season) %>%
  summarise(numRush = n())

# end zone targets 
rz_tgts <- pbp %>% filter(season_type == "REG", (air_yards >= yardline_100 | yardline_100 <= 20)) %>% 
  group_by(receiver_player_id, receiver_player_name, season) %>%
  mutate(num_opps = n(), conversion = round(sum(touchdown)/num_opps, 3)) %>%
  summarise(receiver_player_id, receiver_player_name, season, posteam, num_opps, conversion) %>% 
  unique() %>% na.omit() # %>% #%>% filter(num_gtg > 7, season == 2024, !is.na(receiver_player_name)) %>% ungroup() %>% summarize(avg = mean(conversion))
  #ungroup() %>% filter(num_opps >= 10) %>% summarise(rate = mean(conversion))

# rz_tgts <- pbp %>% filter(season_type == "REG", (air_yards >= yardline_100 | yardline_100 <= 20), play_type == "pass") %>% 
#   group_by(season, posteam) %>%
#   mutate(num_team_opps = n(), team_conversion = round(sum(touchdown,na.rm=TRUE)/num_team_opps, 3)) %>%
#   group_by(receiver_player_id, receiver_player_name, season) %>%
#   mutate(numGames = n_distinct(game_id), num_opps = n(), opps_pct = num_opps/num_team_opps, conversion = round(sum(touchdown)/num_opps, 3)) %>%
#   summarise(receiver_player_id, receiver_player_name, season, posteam, numGames, num_team_opps, team_conversion, num_opps, opps_pct, conversion) %>% 
#   unique() %>% na.omit() # %>% #%>% filter(num_gtg > 7, season == 2024, !is.na(receiver_player_name)) %>% ungroup() %>% summarize(avg = mean(conversion))
# #ungroup() %>% filter(num_opps >= 10) %>% summarise(rate = mean(conversion))
# 
# player_rz_tgts <- pbp %>% group_by(receiver_player_name, posteam, season) %>%
#   mutate(numGames = n_distinct(game_id)) %>%
#   filter(season_type == "REG", (air_yards >= yardline_100 | yardline_100 <= 20), play_type == "pass") %>%
#   # team / game stats
#   group_by(posteam, season, game_id) %>%
#   mutate(team_rz_opps = n()) %>%
#   # player / game stats
#   group_by(posteam, season, game_id, receiver_player_name) %>%
#   mutate(rz_opps = n()) %>%
#   group_by(posteam, season, receiver_player_name) %>%
#   summarize(player_rz_opps = sum(rz_opps), team_rz_opps = sum(team_rz_opps)) %>% 
#   mutate(opp_pct = player_rz_opps/team_rz_opps)
  




#### get points ####
pointsByYear <- load_player_stats(seasons = 2016:2024) 
pointsByYear <- pointsByYear %>% select(player_id, player_name, position, recent_team, season, week, fantasy_points_ppr) %>%
  rename(posteam = recent_team) %>% group_by(player_id, player_name, position, season) %>%
  summarise(posteam = last(posteam), points = sum(fantasy_points_ppr))



#### combine the data ####
wr_pointsByYear <- pointsByYear %>% rename(receiver_player_id = player_id)

wr_model_db <- left_join(wr_tgt_share, playerYear[,c(1,2,3)]) %>% 
  left_join(., passOffenseRank[,c(1,2,13)]) %>% 
  left_join(., QB_ranks[,c(3,4,7)]) %>% 
  left_join(., playerYear_rb[,c(1,2,3)]) %>% 
  left_join(., runOffenseRank[,c(1,2,13)]) %>%
  left_join(., wr_pointsByYear) #%>% left_join(., oline_ranks_pff[,c(19,23,24)])

# save WR model data
#write.csv(tryThis3, "wr_model_db.csv")


#### get nextYear data ####
wr_db <- data.frame()
receiver_db <- wr_model_db %>% #filter(wr_rank <= 6) %>% 
  group_by(receiver_player_id) %>% summarise()  #player db
j <- 1
while (j <= nrow(receiver_db)) {                               # for each player
  thisReceiver <- receiver_db$receiver_player_id[j]
  thisReceiver1 <- wr_model_db %>% filter(receiver_player_id == thisReceiver) %>% arrange((season))                                             #isolate one player
  
  # for each season
  player_yards_db <- data.frame()
  i <- 1
  while (i <= nrow(thisReceiver1)) {                                 # for each season
    thisSeason <- thisReceiver1$season[i]
    nextSeason <- thisReceiver1$season[i] + 1
    nextYearYards <- thisReceiver1 %>% group_by(season,receiver_player_id, posteam) %>% filter(season == nextSeason)
    receiver_result <- thisReceiver1 %>% group_by(season,receiver_player_id, posteam) %>% filter(season == thisSeason) %>% 
      mutate(NY_posteam = max(nextYearYards$posteam), NY_numGames = max(nextYearYards$numGames), NY_tgtShare = max(nextYearYards$tgt_share), NY_seasonYards = max(nextYearYards$numYards), NY_wr_rank = max(nextYearYards$wr_rank), NY_playerYear = max(nextYearYards$playerYear), NY_passOffenseTier = max(nextYearYards$passOffenseTier), NY_qbTier = max(nextYearYards$qbTier), NY_points = max(nextYearYards$points)) # %>% #, NY_passBlock_tier = max(nextYearYards$passBlock_tier)) # NY_runShare = max(nextYearYards$runShare), NY_seasonRushYards = max(nextYearYards$seasonRushYards), NY_runOffenseTier = max(nextYearYards$runOffenseTier))
    
    player_yards_db<- rbind(player_yards_db, receiver_result)
    i <- i + 1
  }
  
  wr_db <- rbind(wr_db, player_yards_db)
  j <- j+1
}
#write.csv(wr_db, "wr_db.csv")





#### add new test attributes (volume and efficiency) ####
playerEffTier <- pbp %>% group_by(season, receiver_player_id, receiver_player_name, posteam) %>%
  filter(season_type == "REG", n() > 35) %>% 
  summarise(avgEPA = mean(epa,na.rm=TRUE)) %>% group_by(season) %>%
  arrange(desc(avgEPA)) %>% na.omit() %>%
  mutate(epaRank = row_number()) %>%
  mutate(epaTier = case_when(
    epaRank <= 16 ~ 1,
    epaRank <= 32 ~ 2,
    epaRank <= 48 ~ 3,
    epaRank <= 64 ~ 4,
    epaRank <= 80 ~ 5,
    epaRank <= 96 ~ 6,
    epaRank <= 112 ~ 7,
    TRUE ~ 8
  ))

teamPassFreq <- pbp %>% group_by(posteam, season) %>%
  filter(season_type == "REG") %>%
  summarise(numPasses = sum(pass_attempt,na.rm=TRUE)) %>%
  arrange(desc(numPasses)) %>% group_by(season) %>% 
  mutate(passFreqRank = row_number()) %>%
  mutate(NY_passFreqTier = case_when(
    passFreqRank <= 4 ~ 1,
    passFreqRank <= 8 ~ 2,
    passFreqRank <= 12 ~ 3,
    passFreqRank <= 16 ~ 4,
    passFreqRank <= 20 ~ 5,
    passFreqRank <= 24 ~ 6,
    passFreqRank <= 28 ~ 7,
    TRUE ~ 8
  )) %>% mutate(season = season - 1)

wr_db <- wr_db %>% left_join(., playerEffTier[,c(1,2,3,4,7)]) %>% left_join(.,teamPassFreq[,c(1,2,5)]) %>% left_join(., rz_tgts[,c(1,2,4,5)])
wr_db <- wr_db %>% unique()




#### WR PRED ####

#### 2024 export ####
wr_db_2024 <- unique(wr_db) %>% filter(season == 2024, wr_rank <= 7) %>% arrange(wr_rank) %>% arrange(posteam)
write.csv(wr_db_2024, "wr_db_2024.csv")



#### trim out 2024 (cant train on this) ####
wr_db_test <- unique(wr_db) %>% filter(NY_numGames > -100, position %in% c("TE", "WR"))

wr_db1 <- wr_db_test[,c(5:14,17,19,20,22,23,24,25,26,28,29,30)] %>% na.omit() %>% unique()
# wr_db1 <- wr_db_test[,c(5:14,17,18,20,21,23:28,30,31)] %>% na.omit() %>% unique()

set.seed(2) # for reproducibility

# Create the train/test split (from your original script)
trainIndex <- createDataPartition(wr_db1$NY_points,
                                  p = 0.8,
                                  list = FALSE,
                                  times = 1)

points_train <- wr_db1[trainIndex, ] # data frame for training
points_test <- wr_db1[-trainIndex, ] # data frame for testing

# --- New Sophisticated Modeling Section ---

# --- Part A: Build the Ensemble (Consensus) Model for Point Predictions ---

# Define the control object, which is crucial for stacking models
my_control <- trainControl(
  method = "cv",
  number = 10,
  savePredictions = "final" # This tells caret to save predictions from each model
)

# Define the list of models we want to train
model_list <- caretList(
  NY_points ~ ., data = points_train,
  trControl = my_control,
  methodList = c("ranger", "xgbTree", "glmnet") # Ranger, XGBoost, and a linear model
)

# Create the ensemble "meta-model" that learns how to best combine the base models
ensemble_model <- caretStack(
  model_list,
  method = "glm", # Use a simple linear model to combine the predictions
  trControl = trainControl(method = "cv", number = 5)
)

# Generate point-predictions on the test set using the powerful ensemble
ensemble_preds <- predict(ensemble_model, points_test)
points_test$pred_points_ensemble <- ensemble_preds


# --- Part B: Build the Bayesian Model for Prediction Range ---

# Train a Bayesian model on the same training data
bayesian_model <- stan_glm(
  NY_points ~ .,
  data = points_train,
  family = gaussian(),
  chains = 2, iter = 1000, cores = 2 # Settings for the simulation
)

# Predict the full distribution of outcomes for the test set
posterior_predictions <- posterior_predict(bayesian_model, newdata = points_test)

# Calculate the prediction range (floor and ceiling) from the distribution
points_test$pred_floor <- apply(posterior_predictions, 2, quantile, probs = c(0.15))
points_test$pred_ceiling <- apply(posterior_predictions, 2, quantile, probs = c(0.85))


# --- Part C: Evaluate the New, Combined Results ---

# Join the predictions back to the original full data to get player names and other info
model_eval <- left_join(points_test, wr_db) %>% 
  mutate(diff_pct = round( ((pred_points_ensemble - NY_points) / NY_points), 3) ) %>%
  # Select the new prediction columns for the final output
  select(receiver_player_id, receiver_player_name, season, 
         pred_points_ensemble, pred_floor, pred_ceiling, 
         NY_points, points, diff_pct, everything()) %>% ungroup() %>% unique()

# Final evaluation using the more accurate ensemble predictions
model_eval %>% 
  filter(NY_seasonYards >= 600) %>% 
  summarise(avgMiss_pct = mean(abs(diff_pct$pred), na.rm = TRUE))

cor_matrix <- cor(wr_db1, use = "complete.obs")
cor_matrix["NY_points", ]
library(corrplot)
corrplot(cor(wr_db_test, use = "complete.obs"), method = "color")

#### create the model (OLD VERSION) ####
#wr_db1 <- wr_db[,c(5:11,14,15,17,18,20,21,22,23,24)]
wr_db1 <- wr_db[,c(5:16,18,20,21,23,24,25,26,27,28,29)]
wr_db1 <- wr_db1 %>% mutate_all(~ replace(., is.na(.), 0)) 
wr_db1 <- wr_db1 %>% na.omit() %>% filter(numRushTD <= 3, runShare < .2, points > 0, NY_points > 0)
wr_db1 <- wr_db1[-10]
colnames(wr_db1)

set.seed(1) # reproduce results 

trainIndex <- createDataPartition(wr_db1$NY_points, # price of house in 10,000
                                  p = 0.8, # percentage that goes to training
                                  list = FALSE, # results will not be in a list
                                  times = 1) # number of partitions to create

points_train <- wr_db1[trainIndex, ] # data frame for training
points_test <- wr_db1[-trainIndex, ] # data frame for testing


points_model <- train(NY_points ~ ., points_train, # use training set
                      method = "ranger", # random forest
                      #tuneLength = 10, # takes longer but the model might be more accurate
                      # it basically tells the algorithm to try different default values for the main hyperparameter
                      trControl = trainControl(method = "cv", # out of sample training procedure 
                                               number = 10)) # 10 folds

# now predict outcomes in testing set
p1 <- predict(points_model, points_test, type = 'raw')

# add predictions to initial dataset 
points_test$pred_points <- p1

model_eval <- left_join(points_test, wr_db) %>% mutate(diff_pct = round( ((pred_points-NY_points)/NY_points), 3) ) %>%
  select(receiver_player_id, receiver_player_name, season, pred_points, NY_points, points, NY_seasonYards, diff_pct, seasonYards, numGames, NY_numGames, tgtShare, NY_tgtShare, everything())

model_eval %>% mutate(diff_pct = round( ((pred_points-NY_points)/NY_points), 3) ) %>%
  #select(receiver_player_id, receiver_player_name, season, pred_points, NY_seasonYards, seasonYards, numGames, NY_numGames, tgtShare, NY_tgtShare, everything()) %>%
  filter(NY_seasonYards >= 600) %>% 
  summarise(avgMiss_pct = mean(abs(diff_pct)))



#### predict on a given year ####

# trim out 2024 & 2023 (cant train on this)
wr_db_test <- unique(wr_db) %>% filter(NY_numGames > -100, season < 2023, position %in% c("TE", "WR"))
wr_db1 <- wr_db_test[,c(5:14,17,19,20,22,23,24,25,26,28,29,30)] %>% na.omit() %>% unique()

set.seed(5) # reproduce results 
trainIndex <- createDataPartition(wr_db1$NY_points, # price of house in 10,000
                                  p = 0.8, # percentage that goes to training
                                  list = FALSE, # results will not be in a list
                                  times = 1) # number of partitions to create

points_train <- wr_db1[trainIndex, ] # data frame for training
points_test <- wr_db1[-trainIndex, ] # data frame for testing

# new try 
my_control <- trainControl(
  method = "cv",
  number = 10,
  savePredictions = "final" # This tells caret to save predictions from each model
)

# Define the list of models we want to train
model_list <- caretList(
  NY_points ~ ., data = points_train,
  trControl = my_control,
  methodList = c("ranger", "xgbTree", "glmnet") # Ranger, XGBoost, and a linear model
)

# Create the ensemble "meta-model" that learns how to best combine the base models
ensemble_model <- caretStack(
  model_list,
  method = "glm", # Use a simple linear model to combine the predictions
  trControl = trainControl(method = "cv", number = 5)
)

# Generate point-predictions on the test set using the powerful ensemble
year_test <- wr_db %>% filter(season == 2023, NY_numGames > 0, position %in% c("TE", "WR")) 
year_test <- year_test[,c(5:14,17,19,20,22,23,24,25,26,28,29,30)] %>% na.omit() %>% unique()

ensemble_preds <- predict(ensemble_model, year_test)
year_test$pred_points_ensemble <- ensemble_preds


# --- Part B: Build the Bayesian Model for Prediction Range ---

# Train a Bayesian model on the same training data
bayesian_model <- stan_glm(
  NY_points ~ .,
  data = points_train,
  family = gaussian(),
  chains = 2, iter = 1000, cores = 2 # Settings for the simulation
)

# Predict the full distribution of outcomes for the test set
posterior_predictions <- posterior_predict(bayesian_model, newdata = year_test)

# Calculate the prediction range (floor and ceiling) from the distribution
year_test$pred_floor <- apply(posterior_predictions, 2, quantile, probs = c(0.15))
year_test$pred_ceiling <- apply(posterior_predictions, 2, quantile, probs = c(0.85))


# --- Part C: Evaluate the New, Combined Results ---

# Join the predictions back to the original full data to get player names and other info
model_eval <- left_join(year_test, wr_db) %>% 
  mutate(diff_pct = round( ((pred_points_ensemble - NY_points) / NY_points), 3) ) %>%
  arrange(desc(pred_points_ensemble$pred)) %>% mutate(myRank = row_number()) %>%
  arrange(desc(NY_points)) %>% mutate(actualRank = row_number(), diffRank = actualRank - myRank) %>%
  # Select the new prediction columns for the final output
  select(receiver_player_id, receiver_player_name, season, 
         pred_points_ensemble, pred_floor, pred_ceiling, 
         NY_points, points, diff_pct, diffRank, myRank, actualRank, everything()) %>% 
  group_by(receiver_player_id) %>% slice_head() %>% arrange(desc(NY_points))

# Final evaluation using the more accurate ensemble predictions
model_eval %>% ungroup() %>%
  filter(NY_seasonYards >= 600) %>% 
  summarise(avgMiss_pct = mean(abs(diff_pct$pred), na.rm = TRUE))



#### OLD METHOD ####
points_model <- train(NY_points ~ ., points_train, # use training set
                      method = "ranger", # random forest
                      #tuneLength = 10, # takes longer but the model might be more accurate
                      # it basically tells the algorithm to try different default values for the main hyperparameter
                      trControl = trainControl(method = "cv", # out of sample training procedure 
                                               number = 10)) # 10 folds


year_test <- wr_db %>% filter(season == 2023, numRushTD <= 3, NY_numGames > 0, epaTier > 0) 

# now predict outcomes in testing set
p1 <- predict(points_model, year_test, type = 'raw')

# add predictions to initial dataset 
year_test$pred_points <- p1

year_test <- left_join(year_test, wr_db) %>% mutate(diff_pct = round( ((pred_points-NY_points)/NY_points), 3) ) %>%
  select(receiver_player_id, receiver_player_name, season, pred_points, NY_points, points, NY_seasonYards, diff_pct, seasonYards, numGames, NY_numGames, tgtShare, NY_tgtShare, everything()) %>%
  ungroup() %>%
  arrange(desc(pred_points)) %>% mutate(myRank = row_number()) %>% arrange(desc(NY_points)) %>% mutate(actualRank = row_number()) %>%
  mutate(diffRank = myRank - actualRank) %>% 
  select(NY_posteam, receiver_player_name, season, pred_points, NY_points, points, myRank, actualRank, diffRank, everything())

year_test <- year_test %>% mutate(diff_pct = round( ((pred_points-NY_points)/NY_points), 3) ) %>%
  select(receiver_player_id, receiver_player_name, season, pred_points, NY_seasonYards, diff_pct, seasonYards, numGames, NY_numGames, tgtShare, NY_tgtShare, everything()) %>%
  filter(NY_seasonYards >= 600, NY_points >0) %>% ungroup() %>%
  #summarise(avgMiss_pct = mean(abs(diff_pct))) 




  
#### doctor up 2024 data ####
tryThis3 %>% filter(season == 2024) %>% write.csv(.,"wr_db_2024.csv")
#wr_preds_2024 <- read_csv("Downloads/2025 FF preds - FF 2025 (19).csv")
wr_preds_2024 <- read_csv("Downloads/2025 FF preds - FF WR 2025 (4).csv")

wr_db_test <- unique(wr_db) %>% filter(season == 2024) #%>% write.csv(.,"wr_db_2024.csv")
#wr_db1 <- wr_db_test[,c(5:14,17,19,20,22,23,24,25,26,28,29)] %>% na.omit() %>% unique()
wr_preds_2024 <- read_csv("Downloads/2025 FF preds - FF WR 2025 v2 (3).csv")


#### find player comp for rookies (baseline stats) ####
wr_preds_2024 <- wr_preds_2024 %>% group_by(wr_rank, passOffenseTier) %>% 
  mutate(tgt_share = case_when(
    tgt_share > .01 ~ tgt_share,
    TRUE ~ mean(tgt_share, na.rm=TRUE)
  )) %>%
  mutate(numYards = case_when(
    numYards > .01 ~ numYards,
    TRUE ~ mean(numYards, na.rm=TRUE)
  )) %>%
  mutate(numTD = case_when(
    numTD > .01 ~ numTD,
    TRUE ~ mean(numTD, na.rm=TRUE)
  )) %>%
  mutate(numRec = case_when(
    numRec > .01 ~ numRec,
    TRUE ~ mean(numRec, na.rm=TRUE)
  )) %>%
  mutate(points = case_when(
    points > .01 ~ points,
    TRUE ~ mean(points, na.rm=TRUE)
  ))

#### test tgtShare pred on a year ####
wr_db_2024 <- wr_db %>% filter(season == 2024) %>% ungroup() %>%
  select(receiver_player_id, receiver_player_name, posteam, wr_rank) %>% 
  rename(NY_posteam = posteam, NY_wr_rank = wr_rank)

wr_tgt_share_year <- wr_db %>% filter(season == 2023) %>% ungroup() #%>% select(receiver_player_id, tgtShare)

tgt_share_test <- left_join(wr_db_2024,wr_tgt_share_year) %>% 
  mutate(posteam = case_when(
    !is.na(posteam) ~ posteam,
    TRUE ~ NY_posteam
  )) %>%
  mutate(wr_rank = case_when(
    !is.na(wr_rank) ~ wr_rank,
    TRUE ~ NY_wr_rank +1
  )) %>%
  group_by(posteam) %>%
  mutate(passOffenseTier = case_when(
    !is.na(passOffenseTier) ~ passOffenseTier,
    TRUE ~ median(passOffenseTier,na.rm=TRUE)
  )) %>%
  mutate(qbTier = case_when(
    qbTier > 0 ~ qbTier,
    TRUE ~ median(qbTier,na.rm=TRUE)
  ))

tgt_share_test <- tgt_share_test %>% group_by(wr_rank, passOffenseTier) %>% 
  mutate(tgtShare = case_when(
    tgtShare > .01 ~ tgtShare,
    TRUE ~ mean(tgtShare, na.rm=TRUE)
  )) %>%
  mutate(seasonYards = case_when(
    seasonYards > .01 ~ seasonYards,
    TRUE ~ mean(seasonYards, na.rm=TRUE)
  )) %>%
  mutate(numTD = case_when(
    numTD > .01 ~ numTD,
    TRUE ~ mean(numTD, na.rm=TRUE)
  )) %>%
  mutate(numRec = case_when(
    numRec > .01 ~ numRec,
    TRUE ~ mean(numRec, na.rm=TRUE)
  )) %>%
  mutate(points = case_when(
    points > .01 ~ points,
    TRUE ~ mean(points, na.rm=TRUE)
  )) %>%
  mutate(numGames = case_when(
    numGames > .01 ~ numGames,
    TRUE ~ mean(numGames, na.rm=TRUE)
  ))

newNYpred1 <- tgt_share_test %>% 
  # avg tgtShares & team shares
  group_by(posteam) %>% mutate(LY_totalShare = sum(tgtShare,na.rm=TRUE)) %>%
  group_by(NY_wr_rank) %>% mutate(avgTgtShare = mean(tgtShare,na.rm=TRUE)) %>% 
  # forecast only on top 6 WRs
  group_by(NY_posteam) %>% arrange(desc(tgtShare)) %>% slice_head(n = 6) %>%
  # total shares NY
  mutate(original_total = sum(tgtShare,na.rm=TRUE)) %>%
  # adjust player tgtShares
  group_by(receiver_player_id) %>% 
  mutate(NY_tgtShare = case_when( 
    abs(tgtShare - avgTgtShare)/avgTgtShare > .18 & wr_rank != 1 ~  ((tgtShare+avgTgtShare)/2) * (1 + (.95 - original_total)),
    TRUE  ~ tgtShare * (1 + (.95 - original_total))
  )) %>%
  # normalize to LY
  group_by(NY_posteam) %>%
  # mutate(NY_total_tgtShare = sum(NY_tgtShare,na.rm=TRUE), multiplier = (1 + (median(LY_totalShare) - NY_total_tgtShare)), NY_tgtShare = multiplier*NY_tgtShare, final_total = sum(NY_tgtShare)) %>%
  select(NY_posteam, NY_wr_rank, receiver_player_name, tgtShare, NY_tgtShare, everything())



#### presume QB tier ####
# last year + trend at end + improvement in weapons + oline change


#### presume offense tier ####
# last year + trend at end + improvement in weapons + oline change


#### presume tgt share ####
# simple method
newNYpred <- wr_preds_2024 %>% filter(NY_wr_rank < 7) %>%
  group_by(NY_wr_rank) %>% mutate(avgTgtShare = mean(tgt_share)) %>% 
  group_by(NY_posteam) %>% mutate(totalTgtShare = sum(tgt_share)) %>%
  group_by(receiver_player_id) %>% 
  mutate(NY_tgtShare = tgt_share * (1 + (1 - totalTgtShare))) %>%
  select(NY_posteam, NY_wr_rank, receiver_player_name, tgt_share, NY_tgtShare, everything())

# find a way to add excess to the right ranked wr (ideally 2) - GOOD PLACE (handles edge cases)
newNYpred1 <- wr_preds_2024 %>% 
  # avg tgtShares & team shares
  group_by(posteam) %>% mutate(LY_totalShare = case_when( 
    !is.na(posteam) ~ sum(tgt_share,na.rm=TRUE),
    TRUE ~ 1)) %>%
  group_by(NY_wr_rank) %>% mutate(avgTgtShare = mean(tgt_share,na.rm=TRUE)) %>% 
  # forecast only on top 6 WRs
  group_by(NY_posteam) %>% arrange(wr_rank) %>% slice_head(n = 7) %>%
  # total shares NY
  mutate(original_total = sum(tgt_share,na.rm=TRUE)) %>%
  # adjust player tgtShares
  group_by(receiver_player_id) %>% 
  mutate(NY_tgtShare = case_when( 
    abs(tgt_share - avgTgtShare)/avgTgtShare > .08 & wr_rank != 1 & NY_wr_rank != 1 & NY_wr_rank != 6 ~  ((tgt_share+avgTgtShare)/2) * (1 + (1 - original_total)),
    abs(tgt_share - avgTgtShare)/avgTgtShare > .08 & (wr_rank == 1 | NY_wr_rank == 1) ~  ((1.2*tgt_share+0.8*avgTgtShare)/2) * (1 + (1 - original_total)),
    TRUE  ~ tgt_share * (1 + (1 - original_total))
  )) %>%
  # normalize to LY
  group_by(NY_posteam) %>%
  # mutate(NY_total_tgtShare = sum(NY_tgtShare,na.rm=TRUE), multiplier = (1 + (median(LY_totalShare) - NY_total_tgtShare)), NY_tgtShare = multiplier*NY_tgtShare, final_total = sum(NY_tgtShare)) %>%
  select(NY_posteam, NY_wr_rank, receiver_player_name, tgt_share, NY_tgtShare, everything())


#### predicting 2025 #####
newNYpred2 <- newNYpred1 %>% filter(!is.na(NY_posteam))
newNYpred2$NY_wr_rank <- as.numeric(newNYpred2$NY_wr_rank)
newNYpred2$NY_passOffenseTier <- as.numeric(newNYpred2$NY_passOffenseTier)
newNYpred2$NY_qbTier <- as.numeric(newNYpred2$NY_qbTier)

p <- predict(points_model, newNYpred2, type = 'raw')
newNYpred2$pred_points <- p

newNYpred2 <- newNYpred2 %>% 
  select(receiver_player_id, receiver_player_name, pred_points, points, NY_tgtShare, tgtShare, numGames, everything()) %>%
  arrange(desc(pred_points))

# new att #
# Generate point-predictions on the test set using the powerful ensemble
year_test <- newNYpred2 %>% filter(position %in% c("TE", "WR")) 
year_test <- year_test %>% select(numGames, tgt_share, numYards, numTD, numRec, wr_rank, playerYear, passOffenseTier, qbTier, runOffenseTier, points, NY_numGames, NY_tgtShare, NY_wr_rank, NY_playerYear, NY_passOffenseTier, NY_qbTier, NY_points, epaTier, NY_passFreqTier)
year_test <- year_test[-1] %>% mutate(epaTier = case_when(
  epaTier > 0 ~ epaTier,
  TRUE ~ 7
)) %>% filter(tgt_share > 0)

ensemble_preds <- predict(ensemble_model, year_test)
year_test$pred_points_ensemble <- ensemble_preds


# --- Part B: Build the Bayesian Model for Prediction Range ---

# Train a Bayesian model on the same training data
bayesian_model <- stan_glm(
  NY_points ~ .,
  data = points_train,
  family = gaussian(),
  chains = 2, iter = 1000, cores = 2 # Settings for the simulation
)

# Predict the full distribution of outcomes for the test set
posterior_predictions <- posterior_predict(bayesian_model, newdata = year_test)

# Calculate the prediction range (floor and ceiling) from the distribution
year_test$pred_floor <- apply(posterior_predictions, 2, quantile, probs = c(0.15))
year_test$pred_ceiling <- apply(posterior_predictions, 2, quantile, probs = c(0.85))


# --- Part C: Evaluate the New, Combined Results ---

# Join the predictions back to the original full data to get player names and other info
model_eval <- left_join(year_test, newNYpred2) %>% 
  mutate(diff_pct = round( ((pred_points_ensemble - NY_points) / NY_points), 3) ) %>%
  # Select the new prediction columns for the final output
  select(receiver_player_id, receiver_player_name, season, 
         pred_points_ensemble, #pred_floor, pred_ceiling, 
         NY_points, points, diff_pct, everything()) #%>% group_by(receiver_player_id) %>% slice_head()

# Final evaluation using the more accurate ensemble predictions
model_eval %>% ungroup() %>%
  filter(NY_seasonYards >= 600) %>% 
  summarise(avgMiss_pct = mean(abs(diff_pct$pred), na.rm = TRUE))

