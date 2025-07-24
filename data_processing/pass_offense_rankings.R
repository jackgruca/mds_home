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

#### pass offense rank ####
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

# Prepare data for Firebase with proper field mappings
passOffenseRank_final <- passOffenseRank %>%
  mutate(
    # Map field names to match UI expectations
    team = coalesce(posteam, "Unknown"),
    # Add tier field mapping
    tier = passOffenseTier,
    # Ensure all numeric fields are properly formatted
    myRank = round(myRank, 4),
    myRankNum = round(myRankNum, 0),
    passOffenseTier = round(passOffenseTier, 0),
    # Format all the stats
    totalEP = round(coalesce(totalEP, 0), 2),
    totalYds = round(coalesce(totalYds, 0), 0),
    totalTD = round(coalesce(totalTD, 0), 0),
    successRate = round(coalesce(successRate, 0), 3),
    # Format all rank fields
    EP_rank = round(coalesce(EP_rank, 0), 4),
    yds_rank = round(coalesce(yds_rank, 0), 4),
    TD_rank = round(coalesce(TD_rank, 0), 4),
    success_rank = round(coalesce(success_rank, 0), 4)
  ) %>%
  # Select and order columns for consistency
  select(
    posteam,
    team,
    season,
    myRankNum,
    myRank,
    passOffenseTier,
    tier,
    # Stats
    totalEP,
    totalYds,
    totalTD,
    successRate,
    # Rank fields (percentiles)
    EP_rank,
    yds_rank,
    TD_rank,
    success_rank
  ) %>%
  arrange(myRankNum)

# Save to JSON
pass_offense_rankings_json <- toJSON(passOffenseRank_final, pretty = TRUE, auto_unbox = TRUE)
write(pass_offense_rankings_json, file = "/Users/jackgruca/Documents/GitHub/mds_home/data_processing/pass_offense_rankings.json")

print(paste("Processed", nrow(passOffenseRank_final), "pass offense rankings and saved to pass_offense_rankings.json"))