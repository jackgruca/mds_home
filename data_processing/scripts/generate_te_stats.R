library(nflfastR)
library(nflreadr)
library(dplyr)
library(tidyr)

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
  select(receiver_player_id, player, posteam, season, tgt_share, wr_rank)#, numGames, numYards, numTD, numRec)

#### TE rankings ####
TE_stats <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(numGames = n_distinct(game_id), totalEPA = sum(epa,na.rm=TRUE), avgEPA = mean(epa,na.rm=TRUE), totalTD = sum(touchdown, na.rm=TRUE), numTgt = n(), numRec = sum(complete_pass,na.rm=TRUE), numYards = sum(yards_gained,na.rm=TRUE),
            numFD = sum(first_down,na.rm=TRUE), FDperTgt = numFD/numTgt, recPerGame = numRec/numGames, tgtPerGame = numTgt/numGames, yardsPerGame = numYards/numGames, catchPct = numRec/numTgt, YAC = sum(yards_after_catch, na.rm=TRUE), YACperRec = YAC/numRec, aDoT = mean(air_yards,na.rm=TRUE))

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

TE_ranks <- left_join(TE_stats, wr_tgt_share) %>% left_join(.,rz_rate) %>% left_join(.,explosive_rate) %>% left_join(.,TE_ngs) %>% left_join(.,third_down_rate) %>%
  filter(player_position == "TE") %>%
  group_by(season) %>% mutate(EPA_rank = percent_rank(totalEPA), td_rank = percent_rank(totalTD/numGames), tgt_rank = percent_rank(tgt_share), 
                              YPG_rank = percent_rank(numYards/numGames), conversion_rank = percent_rank(conversion), explosive_rank = percent_rank(explosive_rate), 
                              sep_rank = percent_rank(avg_separation), intended_air_rank = percent_rank(avg_intended_air_yards), catch_rank = percent_rank(catch_percentage), 
                              third_down_rank = percent_rank(third_down_rate), yacOE_rank = percent_rank(yac_above_expected), yac_rank = percent_rank(YACperRec)) %>%
  unique() %>% group_by(receiver_player_id, receiver_player_name, posteam, season) %>% arrange(desc(EPA_rank)) %>% #head(20)
  # consensus rank calc
  mutate(myRank = 
           0.25*tgt_rank +
           0.25*YPG_rank +
           0.10*EPA_rank +
           0.15*yac_rank +
           0.15*third_down_rate +
           0.05*td_rank +
           0.05*explosive_rank) %>% 
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

# Export to CSV
output_path <- "../../data_processing/assets/data/te_season_stats.csv"
# Create directory if it doesn't exist
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(TE_ranks, output_path, row.names = FALSE)
print(paste("TE stats CSV exported to:", output_path))
print(paste("Total rows:", nrow(TE_ranks)))
print(paste("Seasons included:", paste(unique(TE_ranks$season), collapse = ", ")))