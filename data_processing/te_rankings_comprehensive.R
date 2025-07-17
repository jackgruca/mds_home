library(nflfastR)
library(dplyr)
library(jsonlite)

# Ensure packages are loaded
if (!require(nflfastR)) {
  install.packages("nflfastR")
  library(nflfastR)
}

# Load play-by-play data for all years
message("Loading play-by-play data...")
pbp_data <- load_pbp(seasons = 2016:2024)

# Create separate year datasets for binding
pbp_2016 <- pbp_data %>% filter(season == 2016)
pbp_2017 <- pbp_data %>% filter(season == 2017)
pbp_2018 <- pbp_data %>% filter(season == 2018)
pbp_2019 <- pbp_data %>% filter(season == 2019)
pbp_2020 <- pbp_data %>% filter(season == 2020)
pbp_2021 <- pbp_data %>% filter(season == 2021)
pbp_2022 <- pbp_data %>% filter(season == 2022)
pbp_2023 <- pbp_data %>% filter(season == 2023)
pbp_2024 <- pbp_data %>% filter(season == 2024)

message("Processing WR target share & status...")

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

message("Processing RB rush share & status...")

#### RB rush share & status ####

# usage
snap_counts_rush <- load_snap_counts(seasons = 2016:2024) %>% rename(pfr_id = pfr_player_id) %>% filter(game_type == "REG")
rosters_rush <- load_rosters(seasons = 2016:2024) %>% select(-c(game_type,week))
active_games_rush <- left_join(snap_counts_rush, rosters_rush) %>% select(game_id, gsis_id, player, position, team, season, week, offense_snaps) %>% 
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
rb_rush_share <- active_games_rush %>% left_join(., team_rush_per_game) %>%
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

message("Processing TE rankings...")

#### TE rankings ####
TE_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>% filter(season_type == "REG") %>%
  summarise(totalEPA = sum(epa,na.rm=TRUE), totalTD = sum(touchdown, na.rm=TRUE))

message("Processing red zone data...")
rz_rate <- pbp_data %>%
  filter(season_type == "REG", play_type == "pass", yardline_100 <= 20) %>% 
  group_by(receiver_player_id, season) %>%
  mutate(num_rz_opps = n(), conversion = round(sum(touchdown)/num_rz_opps, 3)) %>%
  summarise(receiver_player_id, receiver_player_name, season, posteam, num_rz_opps, conversion) %>% 
  unique() 

message("Processing explosive rate...")
explosive_rate <- rbind(pbp_2016[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2017[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2018[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2019[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2020[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2021[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2022[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)],pbp_2023[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)], pbp_2024[,c(2,8,23,30,174,175,177,178,286,155,6,29,157,165)]) %>%
  filter(season_type == "REG", play_type == "pass") %>%
  group_by(receiver_player_id, season) %>%
  mutate(numRec = n()) %>% filter(yards_gained >= 15) %>%
  mutate(explosive_rate = n()/numRec) %>% 
  summarise(receiver_player_id, receiver_player_name, season, posteam, explosive_rate) %>% 
  unique() 

message("Processing third down data...")
third_down_rate <- pbp_data %>%
  filter(season_type == "REG", play_type == "pass", down == 3) %>%
  group_by(receiver_player_id, season) %>%
  summarize(
    third_down_targets = n(),
    third_down_conversions = sum(first_down_pass, na.rm = TRUE),
    third_down_rate = third_down_conversions / third_down_targets
  )

message("Loading Next Gen Stats...")
TE_ngs <- load_nextgen_stats(stat_type = "receiving") %>% 
  rename(receiver_player_id = player_gsis_id) %>% 
  select(receiver_player_id, player_position, season, week, avg_separation, avg_intended_air_yards, catch_percentage, avg_yac_above_expectation) %>%
  group_by(season, player_position, receiver_player_id) %>%
  summarise(avg_separation = mean(avg_separation, na.rm=TRUE), avg_intended_air_yards = mean(avg_intended_air_yards,na.rm=TRUE), catch_percentage = mean(catch_percentage, na.rm=TRUE), yac_above_expected = mean(avg_yac_above_expectation, na.rm=TRUE))

message("Combining all TE data and calculating rankings...")

TE_ranks <- left_join(TE_ranks, wr_tgt_share) %>% 
  left_join(.,rz_rate) %>% 
  left_join(.,explosive_rate) %>% 
  left_join(.,TE_ngs) %>% 
  left_join(.,third_down_rate) %>%
  filter(player_position == "TE") %>%
  group_by(season) %>% 
  mutate(
    EPA_rank = percent_rank(totalEPA), 
    td_rank = percent_rank(totalTD/numGames), 
    tgt_rank = percent_rank(tgt_share), 
    YPG_rank = percent_rank(numYards/numGames), 
    conversion_rank = percent_rank(conversion), 
    explosive_rank = percent_rank(explosive_rate), 
    sep_rank = percent_rank(avg_separation), 
    intended_air_rank = percent_rank(avg_intended_air_yards), 
    catch_rank = percent_rank(catch_percentage), 
    third_down_rank = percent_rank(third_down_rate), 
    yacOE_rank = percent_rank(yac_above_expected)
  ) %>%
  unique() %>% 
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>% 
  arrange(desc(EPA_rank)) %>%
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
  unique() %>% 
  arrange(desc(myRank)) %>% 
  group_by(season) %>% 
  mutate(myRankNum = row_number()) %>%
  mutate(teTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  )) %>%
  ungroup()

# Clean and prepare final dataset
te_rankings_final <- TE_ranks %>%
  select(
    receiver_player_id,
    receiver_player_name,
    posteam,
    season,
    numGames,
    totalEPA,
    totalTD,
    tgt_share,
    numYards,
    numRec,
    conversion,
    explosive_rate,
    third_down_rate,
    avg_separation,
    avg_intended_air_yards,
    catch_percentage,
    yac_above_expected,
    myRank,
    myRankNum,
    teTier,
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
    yacOE_rank
  ) %>%
  # Remove any rows with missing essential data
  filter(!is.na(receiver_player_id), !is.na(receiver_player_name), !is.na(season)) %>%
  # Convert NAs to appropriate defaults
  mutate(
    totalEPA = ifelse(is.na(totalEPA), 0, totalEPA),
    totalTD = ifelse(is.na(totalTD), 0, totalTD),
    tgt_share = ifelse(is.na(tgt_share), 0, tgt_share),
    numYards = ifelse(is.na(numYards), 0, numYards),
    numRec = ifelse(is.na(numRec), 0, numRec),
    conversion = ifelse(is.na(conversion), 0, conversion),
    explosive_rate = ifelse(is.na(explosive_rate), 0, explosive_rate),
    third_down_rate = ifelse(is.na(third_down_rate), 0, third_down_rate),
    avg_separation = ifelse(is.na(avg_separation), 0, avg_separation),
    avg_intended_air_yards = ifelse(is.na(avg_intended_air_yards), 0, avg_intended_air_yards),
    catch_percentage = ifelse(is.na(catch_percentage), 0, catch_percentage),
    yac_above_expected = ifelse(is.na(yac_above_expected), 0, yac_above_expected),
    myRank = ifelse(is.na(myRank), 0, myRank),
    myRankNum = ifelse(is.na(myRankNum), 999, myRankNum),
    teTier = ifelse(is.na(teTier), 8, teTier)
  )

# Output to JSON
message("Writing TE rankings to JSON...")
write_json(te_rankings_final, "te_rankings_comprehensive.json", pretty = TRUE)

message(paste("Generated", nrow(te_rankings_final), "TE ranking records"))
message("TE rankings data saved to te_rankings_comprehensive.json")

# Print summary
message("Summary by season:")
summary_stats <- te_rankings_final %>%
  group_by(season) %>%
  summarise(
    players = n(),
    avg_myRank = mean(myRank, na.rm = TRUE),
    avg_EPA = mean(totalEPA, na.rm = TRUE),
    avg_yards = mean(numYards, na.rm = TRUE)
  )
print(summary_stats) 