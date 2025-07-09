library(tidyverse)
library(modelr)
library(readxl)
library(broom)
library(ranger)
library(caret) # machine learning
library(kernlab) # support vector machine algorithm
library(readr)
library(rvest)


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

#pbp_2024_sample <- pbp_2024 %>% head(1) 
#write.csv(pbp_2024_sample,"pbp_2024_sample.csv")

#### tgt share & status ####
wr_tgt_share <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG") %>%
  group_by(game_id, posteam) %>% mutate(numPasses = sum(pass_attempt, na.rm = TRUE)) %>% 
  group_by(receiver_player_id, game_id) %>% mutate(numTgt = sum(pass_attempt, na.rm = TRUE)) %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>% 
  summarise(numGames = n_distinct(game_id), tgtShare = sum(numTgt)/sum(numPasses), seasonYards = sum(yards_gained)) %>% 
  unique() %>% na.omit() %>% arrange(desc(seasonYards)) %>% arrange(posteam) %>% arrange(season) %>% 
  group_by(posteam, season) %>% mutate(wr_rank = row_number()) #%>% 

# new with yards/tgtShare combo for wr rank (FANTASY PLAYER)
wr_tgt_share <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG") %>%
  # passes by game
  group_by(game_id, posteam) %>% mutate(numPasses = sum(pass_attempt, na.rm = TRUE)) %>% 
  # tgts per game
  group_by(fantasy_player_id, game_id) %>% mutate(numTgt = sum(pass_attempt, na.rm = TRUE)) %>%
  # pass play stats
  group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% 
  summarise(numGames = n_distinct(game_id), tgtShare = sum(numTgt)/sum(numPasses), seasonYards = sum(passing_yards,na.rm=TRUE)) %>% 
  # main players only
  unique() %>% na.omit() %>% filter(numGames > 5) %>%
  group_by(posteam, season) %>% arrange(desc(seasonYards/numGames)) %>% mutate(yards_rank = row_number()) %>%
  arrange(desc(tgtShare)) %>% mutate(tgt_rank = row_number()) %>%
  mutate(avg = (yards_rank+tgt_rank)/2) %>% arrange(yards_rank) %>% arrange(avg) %>% 
  mutate(wr_rank = row_number()) %>% rename(receiver_player_id = fantasy_player_id, receiver_player_name = fantasy_player_name) %>%
  select(receiver_player_id, receiver_player_name, posteam, season, numGames, tgtShare, seasonYards, wr_rank)

# library(ggplot2)
# library(scales)
# 
# # Define Miami Dolphins colors
# dolphins_aqua <- "#008E97"
# dolphins_orange <- "#FC4C02"
# dolphins_white <- "#FFFFFF"
# dolphins_blue <- "#005778"
# 
# # Create the plot
# ggplot(wr_tgt_share, aes(x = season, y = tgtShare)) +
#   geom_line(color = dolphins_aqua, size = 1.5) +
#   geom_point(color = dolphins_orange, size = 3) +
#   labs(
#     title = "Target Share Over Time",
#     subtitle = "Jaylen Waddle",
#     x = "Season",
#     y = "Target Share (%)"
#   ) +
#   scale_y_continuous(
#     limits = c(0.16, 0.26),
#     breaks = seq(0.16, 0.26, by = 0.02),
#     labels = percent_format(accuracy = 1)
#   ) +
#   theme_minimal(base_size = 14) +
#   theme(
#     plot.title = element_text(color = dolphins_blue, face = "bold", size = 16),
#     plot.subtitle = element_text(color = dolphins_blue, size = 12),
#     axis.title = element_text(color = dolphins_blue),
#     axis.text = element_text(color = dolphins_blue),
#     panel.grid.major = element_line(color = dolphins_white),
#     panel.grid.minor = element_blank(),
#     plot.background = element_rect(fill = dolphins_white, color = NA),
#     panel.background = element_rect(fill = dolphins_white, color = NA)
#   )

rb_rush_share <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG") %>%
  group_by(game_id, posteam) %>% mutate(numRuns = sum(rush_attempt, na.rm = TRUE)) %>% 
  group_by(rusher_player_id, game_id) %>% mutate(numRushes = sum(rush_attempt, na.rm = TRUE)) %>%
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>% 
  summarise(numGames = n_distinct(game_id), runShare = sum(numRushes)/sum(numRuns), seasonRushYards = sum(yards_gained), numRushes = sum(rush_attempt, na.rm = TRUE)) %>% 
  unique() %>% na.omit() %>% arrange(desc(seasonRushYards)) %>% arrange(posteam) %>% arrange(season)%>% filter(numGames > 5) %>%
  group_by(posteam, season) %>% mutate(rb_rank = row_number())

# retry new rb rank logic
rb_rush_share <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  filter(season_type == "REG") %>%
  group_by(game_id, posteam) %>% mutate(numRuns = sum(rush_attempt, na.rm = TRUE)) %>% 
  group_by(rusher_player_id, game_id) %>% mutate(numRushes = sum(rush_attempt, na.rm = TRUE)) %>%
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>% 
  summarise(numGames = n_distinct(game_id), runShare = sum(numRushes)/sum(numRuns), seasonRushYards = sum(yards_gained), numRushes = sum(rush_attempt, na.rm = TRUE)) %>% 
  unique() %>% na.omit() %>% filter(numGames > 5) %>%
  group_by(posteam, season) %>% arrange(desc(seasonRushYards/numGames)) %>% mutate(yards_rank = row_number()) %>%
  arrange(desc(runShare)) %>% mutate(run_rank = row_number()) %>%
  mutate(avg = (yards_rank+run_rank)/2) %>% arrange(run_rank) %>% arrange(avg) %>% 
  mutate(rb_rank = row_number()) %>% select(rusher_player_id, rusher_player_name, posteam, season, numGames, runShare, seasonRushYards, numRushes, rb_rank)

#### player year ####
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


# now for rbs
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

#### QB ranks (very tough, maybe just go by combined qbr and qb rating? (percentiles?)) ####

# QB passing stats 
QB_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(passer_player_id, posteam, season) %>% 
  filter(season_type == "REG", pass_attempt == 1, sum(pass_attempt) > 100) %>%
  summarise(passer_player_name = min(passer_player_name), numGames= n_distinct(game_id), numPass = sum(pass_attempt), totalEPA = sum(epa,na.rm=TRUE), totalEP = sum(ep,na.rm=TRUE), avgCPOE = mean(cpoe,na.rm=TRUE), YPG = sum(yards_gained)/n_distinct(game_id), TDperGame = sum(touchdown)/n_distinct(game_id), intPerGame = sum(interception)/n_distinct(game_id), thirdConvert = sum(third_down_converted)/(sum(third_down_converted)+sum(third_down_failed)), actualization = (sum(yards_gained,na.rm=TRUE)/n())/mean(air_yards,na.rm=TRUE) ) %>%
  arrange(desc(thirdConvert)) %>% unique()
#ungroup() %>% mutate(EPA_rank = percent_rank(totalEPA), EP_rank = percent_rank(totalEP), CPOE_rank = percent_rank(avgCPOE), YPG_rank = percent_rank(YPG), TD_rank = percent_rank(TDperGame), third_rank = percent_rank(thirdConvert)) %>%
#unique() %>% group_by(passer_player_id, passer_player_name) %>% summarise(myRank = CPOE_rank+YPG_rank+TD_rank+third_rank) %>% unique() %>% arrange(desc(myRank)) %>% head(18)

# include rushing stats too
QB_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>% 
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(rtotalEPA = sum(epa,na.rm=TRUE), rtotalEP = sum(ep,na.rm=TRUE), rYPG = sum(yards_gained)/n_distinct(game_id), rTDperGame = sum(touchdown)/n_distinct(game_id), rthirdConvert = sum(third_down_converted)/(sum(third_down_converted)+sum(third_down_failed))) %>%# arrange(desc(avgCPOE)) %>% unique()
  # now combine the 2
  rename(passer_player_id = rusher_player_id, passer_player_name = rusher_player_name) %>%
  left_join(QB_ranks,.) %>% group_by(passer_player_id, passer_player_name, posteam, season) %>% 
  # combined ranks
  summarise(ctotalEPA = totalEPA+rtotalEPA, ctotalEP = totalEP+rtotalEP, cCPOE = unique(avgCPOE), cactualization = unique(actualization), cYPG = rYPG+YPG, cTDperGame = TDperGame+rTDperGame, intPerGame = unique(intPerGame), cthirdConvert = mean(c(thirdConvert, rthirdConvert))) %>% 
  # get percentiles
  group_by(season) %>% mutate(EPA_rank = percent_rank(ctotalEPA), EP_rank = percent_rank(ctotalEP), CPOE_rank = percent_rank(cCPOE), YPG_rank = percent_rank(cYPG), TD_rank = percent_rank(cTDperGame), int_rank = percent_rank(intPerGame), third_rank = percent_rank(cthirdConvert)) %>%
  unique() %>% group_by(passer_player_id, passer_player_name, posteam, season) %>% arrange(desc(cactualization)) %>% #head(20)
  # consensus rank calc
  summarise(myRank = EPA_rank+YPG_rank+TD_rank+third_rank+cactualization) %>% unique() %>% arrange(desc(myRank)) %>% 
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
  )) %>% group_by(posteam, season) %>% mutate(teamQBTier = ceiling(mean(qbTier)))


#### WR rankings ####
WR_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(totalEPA = sum(epa,na.rm=TRUE), totalTD = sum(touchdown, na.rm=TRUE))
  
rz_rate <- rbind(pbp_2016[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", goal_to_go == 1, play_type == "pass") %>% 
  group_by(receiver_player_id, season) %>%
  mutate(num_gtg = n(), conversion = round(sum(touchdown)/num_gtg, 3)) %>%
  summarise(receiver_player_id, receiver_player_name, season, posteam, num_gtg, conversion) %>% 
  unique() 

explosive_rate <- rbind(pbp_2016[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", play_type == "pass") %>%
  group_by(receiver_player_id, season) %>%
  mutate(numRec = n()) %>% filter(yards_gained >= 15, posteam != "NYJ") %>%
  mutate(explosive_rate = n()/numRec) %>% 
  summarise(receiver_player_id, receiver_player_name, season, posteam, numRec, explosive_rate) %>% 
  unique() 

WR_ngs <- load_nextgen_stats(stat_type = "receiving") %>% 
  rename(receiver_player_id = player_gsis_id) %>% 
  select(receiver_player_id, season, week, avg_separation, avg_intended_air_yards, catch_percentage) %>%
  group_by(season, receiver_player_id) %>%
  summarise(avg_separation = mean(avg_separation, na.rm=TRUE), avg_intended_air_yards = mean(avg_intended_air_yards,na.rm=TRUE), catch_percentage = mean(catch_percentage, na.rm=TRUE))
  

WR_ranks <- left_join(WR_ranks, wr_tgt_share) %>% left_join(.,rz_rate) %>% left_join(.,explosive_rate) %>% left_join(.,WR_ngs) %>%
  filter(tgtShare > .08) %>%
  group_by(season) %>% mutate(EPA_rank = percent_rank(totalEPA), tgt_rank = percent_rank(tgtShare), yards_rank = percent_rank(seasonYards), conversion_rank = percent_rank(conversion), explosive_rank = percent_rank(explosive_rate), sep_rank = percent_rank(avg_separation), intended_air_rank = percent_rank(avg_intended_air_yards), catch_rank = percent_rank(catch_percentage)) %>%
  unique() %>% group_by(receiver_player_id, receiver_player_name, posteam, season) %>% arrange(desc(EPA_rank)) %>% #head(20)
  # consensus rank calc
  mutate(myRank = EPA_rank+tgt_rank+yards_rank+conversion_rank+explosive_rank+sep_rank+intended_air_rank+catch_rank) %>% unique() %>% arrange(desc(myRank)) %>% 
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

#### get LY TDs (add to the data gathering spot and do TY?) ####
wr_TDs <- rbind(pbp_2016[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2017[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2018[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2019[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2020[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2021[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2022[,c(2,8,174,175,286,155,6,29,156,165)],pbp_2023[,c(2,8,174,175,286,155,6,29,156,165)], pbp_2024[,c(2,8,174,175,286,155,6,29,156,165)]) %>%
  filter(season_type == "REG", play_type == "pass") %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>%
  summarise(numTD = sum(pass_touchdown), numRec = sum(complete_pass), numGames = n_distinct(game_id)) %>% arrange(desc(numTD)) 

rb_TDs <- rbind(pbp_2016[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>%
  summarise(numRushTD = sum(rush_touchdown), numGames = n_distinct(game_id)) %>% arrange(desc(numRushTD)) 


# experimental predictors
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

library(ggplot2)
ggplot(run_volume, aes(x = season, y = numRush)) +
  geom_line(color = "blue", size = 1.2) + 
  geom_point(color = "red", size = 2) +  # optional: adds points
  labs(title = "Runs over Time", x = "Year", y = "Value") +
  theme_minimal()


#### get points v2 ####
y <- 2010
pointsByYear <- data.frame()

while (y <= 2024) {
  url <- paste0("https://www.pro-football-reference.com/years/", y, "/fantasy.htm")
  player_stat <- read_html(url)
  
  Name <- player_stat %>% 
    html_nodes(".right+ .left a") %>%
    html_text()
  
  Team <- player_stat %>% 
    html_nodes(".left+ td.left") %>%
    html_text()
  
  points <- player_stat %>% 
    html_nodes(".right:nth-child(28)") %>%
    html_text()
  
  numTD <- player_stat %>% 
    html_nodes(".right:nth-child(21)") %>%
    html_text()
  
  numRushTD <- player_stat %>% 
    html_nodes(".right:nth-child(16)") %>%
    html_text()
  
  numRec <- player_stat %>% 
    html_nodes(".right:nth-child(18)") %>%
    html_text()
  
  yearPoints <- tibble(Name = Name,
                       Team = Team,
                       Season = y,
                       numRec = numRec,
                       numTD = numTD,
                       numRushTD = numRushTD,
                       points = points)
  
  pointsByYear <- rbind(pointsByYear, yearPoints)
  y <- y+1
}
pointsByYear$numTD <- as.numeric(pointsByYear$numTD)
pointsByYear$numRushTD <- as.numeric(pointsByYear$numRushTD)
pointsByYear$points <- as.numeric(pointsByYear$points)
pointsByYear$numRec <- as.numeric(pointsByYear$numRec)
pointsByYear <- pointsByYear %>% rename("season" = "Season")
pointsByYear <- pointsByYear %>% rename("posteam" = "Team")
pointsByYear <- pointsByYear %>%   
  mutate(posteam = str_replace_all(posteam, "LAR", "LA")) %>% 
  mutate(posteam = str_replace_all(posteam, "NWE", "NE")) %>%
  mutate(posteam = str_replace_all(posteam, "TAM", "TB")) %>%
  mutate(posteam = str_replace_all(posteam, "SFO", "SF")) %>%
  mutate(posteam = str_replace_all(posteam, "OAK", "LV")) %>%
  mutate(posteam = str_replace_all(posteam, "KAN", "KC")) %>%
  mutate(posteam = str_replace_all(posteam, "LVR", "LV")) %>%
  mutate(posteam = str_replace_all(posteam, "GNB", "GB")) %>%
  mutate(posteam = str_replace_all(posteam, "SDG", "LAC")) %>%
  mutate(posteam = str_replace_all(posteam, "NOR", "NO"))


#### combine data ####
rb_rush_share <- rb_rush_share %>% rename(receiver_player_id = rusher_player_id, receiver_player_name = rusher_player_name)
playerYear_rb <- playerYear_rb %>% rename(receiver_player_id = rusher_player_id)
rb_TDs <- rb_TDs %>% rename(receiver_player_id = rusher_player_id)

tryThis3 <- left_join(wr_tgt_share, playerYear[,c(1,2,3)]) %>% 
  left_join(., passOffenseRank[,c(1,2,13)]) %>% 
  left_join(., QB_ranks[,c(3,4,7)]) %>% 
  left_join(., wr_TDs[,c(1,3,4,5,6)]) %>% 
  left_join(., playerYear_rb[,c(1,2,3)]) %>% 
  left_join(., runOffenseRank[,c(1,2,13)]) %>% 
  left_join(., rb_TDs[,c(1,3,4,5)]) %>%
  left_join(., rb_rush_share[,c(1,3,4,6,7)]) %>% 
  mutate_all(~ replace(., is.na(.), 0))

tryThis3 <- tryThis3 %>%
  left_join(., pointsByYear[,c(2,3,4,5,6,7)]) %>% 
  mutate_all(~ replace(., is.na(.), 0)) %>%
  unique() %>% filter(numGames > 3 & wr_rank <= 7) %>% # | runShare > .2) ) %>%
  group_by(receiver_player_id, season) %>% slice_tail() #%>%
#filter(runShare < .2)

# save WR model data
write.csv(tryThis3, "wr_model_db.csv")

# correlation of tgt share and points
cor(tryThis3$tgtShare, tryThis3$points, use = "complete.obs")


#### get nextYear data ####
wr_db <- data.frame()
receiver_db <- tryThis3 %>% #filter(wr_rank <= 6) %>% 
  group_by(receiver_player_id) %>% summarise()  #player db
j <- 1
while (j <= nrow(receiver_db)) {                               # for each player
  thisReceiver <- receiver_db$receiver_player_id[j]
  thisReceiver1 <- tryThis3 %>% filter(receiver_player_id == thisReceiver) %>% arrange((season))                                             #isolate one player
  
  # for each season
  player_yards_db <- data.frame()
  i <- 1
  while (i <= nrow(thisReceiver1)) {                                 # for each season
    thisSeason <- thisReceiver1$season[i]
    nextSeason <- thisReceiver1$season[i] + 1
    nextYearYards <- thisReceiver1 %>% group_by(season,receiver_player_id, posteam) %>% filter(season == nextSeason)
    receiver_result <- thisReceiver1 %>% group_by(season,receiver_player_id, posteam) %>% filter(season == thisSeason) %>% 
      mutate(NY_posteam = max(nextYearYards$posteam), NY_numGames = max(nextYearYards$numGames), NY_tgtShare = max(nextYearYards$tgtShare), NY_seasonYards = max(nextYearYards$seasonYards), NY_wr_rank = max(nextYearYards$wr_rank), NY_playerYear = max(nextYearYards$playerYear), NY_passOffenseTier = max(nextYearYards$passOffenseTier), NY_qbTier = max(nextYearYards$qbTier), NY_points = max(nextYearYards$points)) # NY_runShare = max(nextYearYards$runShare), NY_seasonRushYards = max(nextYearYards$seasonRushYards), NY_runOffenseTier = max(nextYearYards$runOffenseTier))
    
    player_yards_db<- rbind(player_yards_db, receiver_result)
    i <- i + 1
  }
  
  wr_db <- rbind(wr_db, player_yards_db)
  j <- j+1
}
#write.csv(wr_db, "wr_db.csv")


#### add new test attributes (volume and efficiency) ####
playerEffTier <- pbp %>% group_by(season, receiver_player_name, posteam) %>%
  filter(season_type == "REG", n() > 50) %>% 
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

wr_db <- wr_db %>% left_join(., playerEffTier[,c(1,2,3,6)]) %>% left_join(.,teamPassFreq[,c(1,2,5)])

#### WR PRED ####

#### 2024 export ####
wr_db_2024 <- unique(wr_db) %>% filter(season == 2024, wr_rank <= 7) %>% arrange(wr_rank) %>% arrange(posteam)
write.csv(wr_db_2024, "wr_db_2024.csv")


#### trim out 2024 & 2023 (cant train on this) ####
wr_db_test <- unique(wr_db) %>% filter(NY_numGames > -100 & season < 2023)


#### create the model (anonymize) ####
#wr_db1 <- wr_db[,c(5:11,14,15,17,18,20,21,22,23,24)]
wr_db1 <- wr_db_test[,c(5:16,18,20,21,23,24,25,26,27,28,29)]
wr_db1 <- wr_db1 %>% mutate_all(~ replace(., is.na(.), 0)) 
wr_db1 <- wr_db1 %>% na.omit() %>% filter(numRushTD <= 3, runShare < .2, points > 0, NY_points > 0)
wr_db1 <- wr_db1[-10]

# Define the data for the final predictions
year_test <- wr_db %>% filter(season == 2023, numRushTD <= 3, NY_numGames > 0, epaTier > 0) 

# --- New Sophisticated Modeling Section ---

# 1. Install and load necessary libraries
# You may need to run the following lines once in your console if you don't have these packages:
# install.packages("caretEnsemble")
# install.packages("xgboost")
# install.packages("rstanarm")
library(caretEnsemble)
library(xgboost)
library(rstanarm)

set.seed(1) # for reproducibility

# --- Part A: Build the Ensemble (Consensus) Model for Point Predictions ---

# Define the control object. It's crucial to set savePredictions = "final"
my_control <- trainControl(
  method = "cv",
  number = 10,
  savePredictions = "final" # This is required for stacking
)

# Define a list of models to train as the base of the ensemble
# We are using your original Random Forest (ranger), XGBoost (xgbTree),
# and a regularized linear model (glmnet) which is fast and robust.
model_list <- caretList(
  NY_points ~ ., data = wr_db1,
  trControl = my_control,
  methodList = c("ranger", "xgbTree", "glmnet")
)

# Create the ensemble "meta-model" that learns how to best combine the base models.
# We use a simple General Linear Model (glm) for this.
ensemble_model <- caretStack(
  model_list,
  method = "glm",
  trControl = trainControl(method = "cv", number = 5)
)

# Get the point-prediction from the ensemble model
ensemble_preds <- predict(ensemble_model, year_test)
year_test$pred_points_ensemble <- ensemble_preds


# --- Part B: Build the Bayesian Model for Prediction Range ---

# We use stan_glm, which is a Bayesian alternative to a standard linear model.
# It provides a full probability distribution for the outcomes.
bayesian_model <- stan_glm(
  NY_points ~ .,
  data = wr_db1, # Train on the same data
  family = gaussian(),
  # These are settings for the simulation, you can increase them for more precision
  chains = 2, iter = 1000, cores = 2 
)

# Predict the distribution of outcomes for the test year
posterior_predictions <- posterior_predict(bayesian_model, newdata = year_test)

# From the distribution, calculate the mean, floor, and ceiling for each player
year_test$pred_points_bayesian_mean <- apply(posterior_predictions, 2, mean)
# For the range, we'll use the 15th and 85th percentiles as a reasonable floor/ceiling
year_test$pred_floor <- apply(posterior_predictions, 2, quantile, probs = c(0.15))
year_test$pred_ceiling <- apply(posterior_predictions, 2, quantile, probs = c(0.85))


# --- Part C: Evaluate the New, Combined Results ---

year_test_results <- year_test %>% 
  mutate(diff_pct = round( ((pred_points_ensemble-NY_points)/NY_points), 3) ) %>%
  select(receiver_player_id, receiver_player_name, season, pred_points_ensemble, pred_floor, pred_ceiling, NY_points, points, NY_seasonYards, diff_pct, seasonYards, numGames, NY_numGames, tgtShare, NY_tgtShare, everything()) %>%
  ungroup() %>%
  arrange(desc(pred_points_ensemble)) %>% mutate(myRank = row_number()) %>% 
  arrange(desc(NY_points)) %>% mutate(actualRank = row_number()) %>%
  mutate(diffRank = myRank - actualRank) %>% 
  select(NY_posteam, receiver_player_name, pred_points_ensemble, pred_floor, pred_ceiling, NY_points, myRank, actualRank, diffRank, everything())

# Display the top of the results table
print("Top 20 Predicted Players for 2023:")
print(head(year_test_results, 20))

# Final evaluation metric using the more accurate ensemble predictions
final_summary <- year_test_results %>% 
  filter(NY_seasonYards >= 600, NY_points > 0) %>% 
  ungroup() %>%
  summarise(avgMiss_pct = mean(abs(diff_pct), na.rm = TRUE)) 

print("Final Evaluation (MAPE on players with > 600 yards):")
print(final_summary)

model_eval %>% mutate(diff_pct = round( ((pred_points-NY_points)/NY_points), 3) ) %>%
  select(receiver_player_id, receiver_player_name, season, pred_points, NY_seasonYards, seasonYards, numGames, NY_numGames, tgtShare, NY_tgtShare, everything()) %>%
  filter(NY_seasonYards >= 600) %>% 
  summarise(avgMiss_pct = mean(abs(diff_pct)))
