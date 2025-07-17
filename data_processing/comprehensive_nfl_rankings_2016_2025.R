library(nflfastR)
library(dplyr)
library(tidyr)
library(jsonlite)

# Load play-by-play data for all seasons
pbp_2016 <- load_pbp(2016)
pbp_2017 <- load_pbp(2017)
pbp_2018 <- load_pbp(2018)
pbp_2019 <- load_pbp(2019)
pbp_2020 <- load_pbp(2020)
pbp_2021 <- load_pbp(2021)
pbp_2022 <- load_pbp(2022)
pbp_2023 <- load_pbp(2023)
pbp_2024 <- load_pbp(2024)

# Create combined pbp for all operations
pbp <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016)

print("✅ Loaded play-by-play data for 2016-2024")

# Calculate team passing attempts for target share
team_pass_attempts <- pbp %>%
  filter(season_type == "REG", play_type == "pass") %>%
  group_by(posteam, season) %>%
  summarise(team_pass_attempts = n(), .groups = 'drop')

# Calculate team rushing attempts for rush share
team_rush_attempts <- pbp %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(posteam, season) %>%
  summarise(team_rush_attempts = n(), .groups = 'drop')

# Calculate target share for WRs/TEs
wr_tgt_share <- pbp %>%
  filter(season_type == "REG", play_type == "pass", !is.na(receiver_player_id)) %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>%
  summarise(
    player_targets = n(),
    numRec = sum(complete_pass, na.rm = TRUE),
    numYards = sum(yards_gained, na.rm = TRUE),
    numTD = sum(touchdown, na.rm = TRUE),
    numGames = n_distinct(game_id),
    .groups = 'drop'
  ) %>%
  left_join(team_pass_attempts, by = c("posteam", "season")) %>%
  mutate(tgt_share = player_targets / team_pass_attempts) %>%
  filter(numGames > 3)

print("✅ Calculated target share")

# Calculate rush share for RBs
rb_rush_share <- pbp %>%
  filter(season_type == "REG", play_type == "run", !is.na(rusher_player_id)) %>%
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>%
  summarise(
    player_rush_attempts = n(),
    numYards = sum(yards_gained, na.rm = TRUE),
    numTD = sum(touchdown, na.rm = TRUE),
    numGames = n_distinct(game_id),
    .groups = 'drop'
  ) %>%
  left_join(team_rush_attempts, by = c("posteam", "season")) %>%
  mutate(
    run_share = player_rush_attempts / team_rush_attempts,
    YPG = numYards / numGames
  ) %>%
  filter(numGames > 3)

print("✅ Calculated rush share")

#### QB ranks ####

# QB passing stats 
QB_ranks <- pbp %>%
  group_by(passer_player_id, posteam, season) %>% 
  filter(season_type == "REG", pass_attempt == 1, sum(pass_attempt) > 100) %>%
  summarise(
    passer_player_name = min(passer_player_name), 
    numGames = n_distinct(game_id), 
    numPass = sum(pass_attempt), 
    totalEPA = sum(epa, na.rm = TRUE), 
    totalEP = sum(ep, na.rm = TRUE), 
    avgCPOE = mean(cpoe, na.rm = TRUE), 
    YPG = sum(yards_gained) / n_distinct(game_id), 
    TDperGame = sum(touchdown) / n_distinct(game_id), 
    intPerGame = sum(interception) / n_distinct(game_id), 
    thirdConvert = sum(third_down_converted) / (sum(third_down_converted) + sum(third_down_failed)), 
    actualization = (sum(yards_gained, na.rm = TRUE) / n()) / mean(air_yards, na.rm = TRUE),
    .groups = 'drop'
  ) %>% 
  arrange(desc(thirdConvert)) %>% 
  unique()

# include rushing stats too
QB_rush_stats <- pbp %>% 
  group_by(rusher_player_id, rusher_player_name, posteam, season) %>% 
  filter(season_type == "REG") %>%
  summarise(
    rtotalEPA = sum(epa, na.rm = TRUE), 
    rtotalEP = sum(ep, na.rm = TRUE), 
    rYPG = sum(yards_gained) / n_distinct(game_id), 
    rTDperGame = sum(touchdown) / n_distinct(game_id), 
    rthirdConvert = sum(third_down_converted) / (sum(third_down_converted) + sum(third_down_failed)),
    .groups = 'drop'
  ) %>%
  rename(passer_player_id = rusher_player_id, passer_player_name = rusher_player_name)

# Combine passing and rushing
QB_ranks <- QB_ranks %>%
  left_join(QB_rush_stats, by = c("passer_player_id", "passer_player_name", "posteam", "season")) %>% 
  group_by(passer_player_id, passer_player_name, posteam, season) %>% 
  summarise(
    ctotalEPA = totalEPA + ifelse(is.na(rtotalEPA), 0, rtotalEPA), 
    ctotalEP = totalEP + ifelse(is.na(rtotalEP), 0, rtotalEP), 
    cCPOE = avgCPOE, 
    cactualization = actualization, 
    cYPG = YPG + ifelse(is.na(rYPG), 0, rYPG), 
    cTDperGame = TDperGame + ifelse(is.na(rTDperGame), 0, rTDperGame), 
    intPerGame = intPerGame, 
    cthirdConvert = mean(c(thirdConvert, ifelse(is.na(rthirdConvert), 0, rthirdConvert)), na.rm = TRUE),
    .groups = 'drop'
  ) %>% 
  group_by(season) %>% 
  mutate(
    EPA_rank = percent_rank(ctotalEPA), 
    EP_rank = percent_rank(ctotalEP), 
    CPOE_rank = percent_rank(cCPOE), 
    YPG_rank = percent_rank(cYPG), 
    TD_rank = percent_rank(cTDperGame), 
    int_rank = percent_rank(intPerGame), 
    third_rank = percent_rank(cthirdConvert)
  ) %>%
  unique() %>% 
  group_by(passer_player_id, passer_player_name, posteam, season) %>% 
  arrange(desc(cactualization)) %>%
  summarise(
    myRank = EPA_rank + YPG_rank + TD_rank + third_rank + cactualization,
    .groups = 'drop'
  ) %>% 
  unique() %>% 
  arrange(desc(myRank)) %>% 
  group_by(season) %>% 
  mutate(myRankNum = row_number()) %>%
  mutate(qbTier = case_when(
    myRankNum <= 4 ~ 1,
    myRankNum <= 8 ~ 2,
    myRankNum <= 12 ~ 3,
    myRankNum <= 16 ~ 4,
    myRankNum <= 20 ~ 5,
    myRankNum <= 24 ~ 6,
    myRankNum <= 28 ~ 7,
    TRUE ~ 8
  )) %>% 
  group_by(posteam, season) %>% 
  mutate(teamQBTier = ceiling(mean(qbTier)))

print("✅ Calculated QB rankings")

#### WR rankings ####
WR_ranks <- pbp %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>% 
  filter(season_type == "REG") %>%
  summarise(
    totalEPA = sum(epa, na.rm = TRUE), 
    totalTD = sum(touchdown, na.rm = TRUE),
    .groups = 'drop'
  )

# Red zone conversion rate
rz_rate <- pbp %>%
  filter(season_type == "REG", play_type == "pass", yardline_100 <= 20) %>% 
  group_by(receiver_player_id, season) %>%
  mutate(num_rz_opps = n(), conversion = round(sum(touchdown) / num_rz_opps, 3)) %>%
  summarise(
    receiver_player_id, 
    receiver_player_name, 
    season, 
    posteam, 
    num_rz_opps, 
    conversion,
    .groups = 'drop'
  ) %>% 
  unique() 

# Explosive play rate
explosive_rate <- pbp %>%
  filter(season_type == "REG", play_type == "pass") %>%
  group_by(receiver_player_id, season) %>%
  mutate(numRec = n()) %>% 
  filter(yards_gained >= 15) %>%
  mutate(explosive_rate = n() / numRec) %>% 
  summarise(
    receiver_player_id, 
    receiver_player_name, 
    season, 
    posteam, 
    explosive_rate,
    .groups = 'drop'
  ) %>% 
  unique() 

# Third down conversion rate
third_down_rate <- pbp %>%
  filter(season_type == "REG", play_type == "pass", down == 3) %>%
  group_by(receiver_player_id, season) %>%
  summarize(
    third_down_targets = n(),
    third_down_conversions = sum(first_down_pass, na.rm = TRUE),
    third_down_rate = third_down_conversions / third_down_targets,
    .groups = 'drop'
  )

# Next Gen Stats (simplified - we'll use basic stats if NGS not available)
WR_ngs <- pbp %>%
  filter(season_type == "REG", play_type == "pass", !is.na(receiver_player_id)) %>%
  group_by(receiver_player_id, season) %>%
  summarise(
    avg_separation = mean(ifelse(is.na(air_yards), 0, air_yards), na.rm = TRUE),
    avg_intended_air_yards = mean(air_yards, na.rm = TRUE),
    catch_percentage = mean(complete_pass, na.rm = TRUE),
    yac_above_expected = mean(yards_after_catch, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(player_position = "WR") # Simplified assumption

# Combine WR data
WR_ranks <- WR_ranks %>%
  left_join(wr_tgt_share, by = c("receiver_player_id", "receiver_player_name", "posteam", "season")) %>% 
  left_join(rz_rate, by = c("receiver_player_id", "posteam", "season")) %>% 
  left_join(explosive_rate, by = c("receiver_player_id", "posteam", "season")) %>% 
  left_join(WR_ngs, by = c("receiver_player_id", "season")) %>% 
  left_join(third_down_rate, by = c("receiver_player_id", "season")) %>%
  filter(player_position == "WR") %>%
  group_by(season) %>% 
  mutate(
    EPA_rank = percent_rank(totalEPA), 
    tgt_rank = percent_rank(tgt_share), 
    YPG_rank = percent_rank(numYards / numGames), 
    td_rank = percent_rank(totalTD / numGames), 
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
  mutate(myRank = 
           0.2 * tgt_rank +
           0.2 * YPG_rank +
           0.1 * EPA_rank +
           0.15 * td_rank +
           0.1 * explosive_rank +
           0.1 * yacOE_rank +
           0.05 * catch_rank +
           0.05 * sep_rank +
           0.05 * third_down_rank) %>% 
  unique() %>% 
  arrange(desc(myRank)) %>% 
  group_by(season) %>% 
  mutate(myRankNum = row_number()) %>%
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

print("✅ Calculated WR rankings")

#### TE rankings ####
TE_ranks <- pbp %>%
  group_by(receiver_player_id, receiver_player_name, posteam, season) %>% 
  filter(season_type == "REG") %>%
  summarise(
    totalEPA = sum(epa, na.rm = TRUE), 
    totalTD = sum(touchdown, na.rm = TRUE),
    .groups = 'drop'
  )

# TE Next Gen Stats (simplified)
TE_ngs <- pbp %>%
  filter(season_type == "REG", play_type == "pass", !is.na(receiver_player_id)) %>%
  group_by(receiver_player_id, season) %>%
  summarise(
    avg_separation = mean(ifelse(is.na(air_yards), 0, air_yards), na.rm = TRUE),
    avg_intended_air_yards = mean(air_yards, na.rm = TRUE),
    catch_percentage = mean(complete_pass, na.rm = TRUE),
    yac_above_expected = mean(yards_after_catch, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(player_position = "TE") # Simplified assumption

# Combine TE data
TE_ranks <- TE_ranks %>%
  left_join(wr_tgt_share, by = c("receiver_player_id", "receiver_player_name", "posteam", "season")) %>% 
  left_join(rz_rate, by = c("receiver_player_id", "posteam", "season")) %>% 
  left_join(explosive_rate, by = c("receiver_player_id", "posteam", "season")) %>% 
  left_join(TE_ngs, by = c("receiver_player_id", "season")) %>% 
  left_join(third_down_rate, by = c("receiver_player_id", "season")) %>%
  filter(player_position == "TE") %>%
  group_by(season) %>% 
  mutate(
    EPA_rank = percent_rank(totalEPA), 
    td_rank = percent_rank(totalTD / numGames), 
    tgt_rank = percent_rank(tgt_share), 
    YPG_rank = percent_rank(numYards / numGames), 
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
  mutate(myRank = 
           0.25 * tgt_rank +
           0.25 * YPG_rank +
           0.15 * EPA_rank +
           0.1 * yacOE_rank +
           0.1 * third_down_rank +
           0.05 * td_rank +
           0.05 * explosive_rank +
           0.05 * sep_rank) %>% 
  unique() %>% 
  arrange(desc(myRank)) %>% 
  group_by(season) %>% 
  mutate(myRankNum = row_number()) %>%
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

print("✅ Calculated TE rankings")

#### RB rush share & status ####

# Simplified game counting using play-by-play data
active_games <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG", !is.na(rusher_player_id)) %>%
  group_by(rusher_player_id, season, week, posteam) %>%
  summarise(plays = n(), .groups = 'drop') %>%
  group_by(rusher_player_id, season) %>%
  mutate(numGames = n_distinct(week)) %>%
  select(rusher_player_id, posteam, season, numGames) %>%
  unique()

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
  group_by(season, rusher_player_id, posteam) %>%
  mutate(numRushes = replace_na(numRushes, 0)) %>% mutate(numYards = replace_na(numYards, 0)) %>% mutate(numTD = replace_na(numTD, 0)) %>%
  summarize(numGames = first(numGames), run_share = sum(numRushes)/sum(numRuns), YPG = sum(numYards)/numGames, numTD = sum(numTD)) %>%
  unique() %>% na.omit() %>% filter(numGames > 3) %>%
  # ranks
  group_by(posteam, season) %>% arrange(desc(YPG)) %>% mutate(YPG_rank = row_number()) %>%
  arrange(desc(run_share)) %>% mutate(run_rank = row_number()) %>%
  mutate(avg = (YPG_rank+run_rank)/2) %>% arrange((run_rank)) %>% arrange((avg)) %>% 
  mutate(rb_rank = row_number()) %>% select(rusher_player_id, posteam, season, numGames, numTD, run_share, YPG, rb_rank)

#### RB Ranks ####
RB_ranks <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% 
  summarise(totalEPA = sum(epa,na.rm=TRUE), totalTD = sum(touchdown, na.rm=TRUE), total_attempts = sum(rush_attempt, na.rm=TRUE))

rz_rate <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG", play_type == "run", yardline_100 <= 20) %>% 
  group_by(fantasy_player_id, season) %>%
  mutate(num_rz_opps = n(), conversion = round(sum(touchdown)/num_rz_opps, 3)) %>%
  summarise(fantasy_player_id, fantasy_player_name, season, posteam, num_rz_opps, conversion) %>% 
  unique() 

explosive_rate <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG", play_type == "run") %>%
  group_by(fantasy_player_id, season) %>%
  mutate(numRush = n()) %>% filter(yards_gained >= 15) %>%
  mutate(explosive_rate = n()/numRush) %>% 
  summarise(fantasy_player_id, fantasy_player_name, season, posteam, explosive_rate) %>% 
  unique() 

third_down_rate <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG", play_type == "run", down == 3) %>%
  group_by(fantasy_player_id, season) %>%
  summarize(
    third_down_att = n(),
    third_down_conversions = sum(first_down_rush, na.rm = TRUE),
    third_down_rate = third_down_conversions / third_down_att
  )

# Simplified NGS stats using available data
RB_ngs <- rbind(pbp_2024, pbp_2023, pbp_2022, pbp_2021, pbp_2020, pbp_2019, pbp_2018, pbp_2017, pbp_2016) %>%
  filter(season_type == "REG", play_type == "run", !is.na(fantasy_player_id)) %>%
  group_by(fantasy_player_id, season) %>%
  summarise(
    avg_eff = mean(epa, na.rm = TRUE),
    avg_RYOE_perAtt = mean(yards_gained, na.rm = TRUE),
    player_position = "RB",
    .groups = 'drop'
  )

RB_ranks <- left_join(RB_ranks, rb_rush_share, by = c("fantasy_player_id" = "rusher_player_id", "posteam", "season")) %>% 
  left_join(.,wr_tgt_share, by = c("fantasy_player_id" = "receiver_player_id", "posteam", "season")) %>% 
  left_join(.,rz_rate, by = c("fantasy_player_id", "season")) %>% 
  left_join(.,explosive_rate, by = c("fantasy_player_id", "season")) %>% 
  left_join(.,RB_ngs, by = c("fantasy_player_id", "season")) %>% 
  left_join(.,third_down_rate, by = c("fantasy_player_id", "season")) %>%
  filter(player_position == "RB") %>%
  # Handle missing columns by setting defaults
  mutate(
    tgt_share = ifelse(is.na(tgt_share), 0, tgt_share),
    conversion = ifelse(is.na(conversion), 0, conversion),
    explosive_rate = ifelse(is.na(explosive_rate), 0, explosive_rate),
    third_down_rate = ifelse(is.na(third_down_rate), 0, third_down_rate),
    avg_eff = ifelse(is.na(avg_eff), 0, avg_eff),
    avg_RYOE_perAtt = ifelse(is.na(avg_RYOE_perAtt), 0, avg_RYOE_perAtt)
  ) %>%
  group_by(season) %>% mutate(EPA_rank = percent_rank(totalEPA), td_rank = percent_rank(totalTD/numGames), run_rank = percent_rank(run_share), tgt_rank = percent_rank(tgt_share), YPG_rank = percent_rank(YPG), third_rank = percent_rank(third_down_rate), conversion_rank = percent_rank(conversion), explosive_rank = percent_rank(explosive_rate), RYOE_rank = percent_rank(avg_RYOE_perAtt), eff_rank = percent_rank(-avg_eff)) %>%
  unique() %>% group_by(fantasy_player_id, fantasy_player_name, posteam, season) %>% arrange(desc(EPA_rank)) %>%
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

# Clean and prepare RB data for export
rb_rankings <- RB_ranks %>%
  select(
    player_id = fantasy_player_id,
    player_name = fantasy_player_name,
    team = posteam,
    season,
    rank = myRankNum,
    tier = qbTier,
    yards = YPG,
    touchdowns = totalTD,
    attempts = total_attempts,
    rush_share,
    target_share = tgt_share,
    epa = totalEPA,
    explosive_rate,
    conversion_rate = conversion,
    third_down_rate,
    efficiency = avg_eff,
    ryoe_per_att = avg_RYOE_perAtt,
    games = numGames
  ) %>%
  arrange(season, rank) %>%
  ungroup()

# Export to JSON
write_json(rb_rankings, "rb_rankings_comprehensive.json")

# Export data for Firebase import
# QB Rankings
# Check what columns actually exist in QB_ranks
print("QB_ranks columns:")
print(names(QB_ranks))

# Get all QB data with proper column names
qb_final <- QB_ranks %>%
  rename(
    player_id = passer_player_id,
    player_name = passer_player_name,
    team = posteam,
    rank = myRankNum,
    tier = qbTier
  )

# WR Rankings
# Check what columns actually exist in WR_ranks
print("WR_ranks columns:")
print(names(WR_ranks))

# Get all WR data with proper column names
wr_final <- WR_ranks %>%
  rename(
    player_id = receiver_player_id,
    player_name = receiver_player_name,
    team = posteam,
    rank = myRankNum,
    tier = qbTier
  )

# TE Rankings
# Check what columns actually exist in TE_ranks
print("TE_ranks columns:")
print(names(TE_ranks))

# Get all TE data with proper column names
te_final <- TE_ranks %>%
  rename(
    player_id = receiver_player_id,
    player_name = receiver_player_name,
    team = posteam,
    rank = myRankNum,
    tier = qbTier
  )

# RB Rankings
# Check what columns actually exist in RB_ranks
print("RB_ranks columns:")
print(names(RB_ranks))

# Get all RB data with proper column names
rb_final <- RB_ranks %>%
  rename(
    player_id = fantasy_player_id,
    player_name = fantasy_player_name,
    team = posteam,
    rank = myRankNum,
    tier = qbTier
  )

# Write to JSON files
write_json(qb_final, "qb_rankings_comprehensive.json")
write_json(wr_final, "wr_rankings_comprehensive.json")
write_json(te_final, "te_rankings_comprehensive.json")
write_json(rb_final, "rb_rankings_comprehensive.json")

print("Data processing complete!")
print(paste("QB Rankings:", nrow(qb_final), "records"))
print(paste("WR Rankings:", nrow(wr_final), "records"))
print(paste("TE Rankings:", nrow(te_final), "records"))
print(paste("RB Rankings:", nrow(rb_final), "records")) 