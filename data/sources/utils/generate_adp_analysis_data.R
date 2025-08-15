library(tidyverse)
library(rvest)
library(httr)
library(nflreadr)

#### 1. PLAYER PERFORMANCE DATA (PPR and Standard) ####
cat("Loading player performance data...\n")

# Load player stats for all available seasons
player_performance <- load_player_stats(seasons = 2015:2024, stat_type = "offense") %>% 
  filter(season_type == "REG") %>%
  group_by(player_id, player_display_name, position, season) %>%
  summarise(
    # PPR scoring
    points_ppr = sum(fantasy_points_ppr, na.rm = TRUE),
    ppg_ppr = sum(fantasy_points_ppr, na.rm = TRUE)/n_distinct(week),
    # Standard scoring (fantasy_points field is standard scoring)
    points_std = sum(fantasy_points, na.rm = TRUE),
    ppg_std = sum(fantasy_points, na.rm = TRUE)/n_distinct(week),
    # Games played
    games_played = n_distinct(week),
    .groups = "drop"
  ) %>%
  rename(player = player_display_name) %>%
  # Calculate ranks by position and overall
  group_by(season, position) %>%
  mutate(
    rank_position_ppr_total = rank(-points_ppr, ties.method = "min"),
    rank_position_ppr_ppg = rank(-ppg_ppr, ties.method = "min"),
    rank_position_std_total = rank(-points_std, ties.method = "min"),
    rank_position_std_ppg = rank(-ppg_std, ties.method = "min")
  ) %>%
  ungroup() %>%
  # Overall ranks across all positions
  group_by(season) %>%
  mutate(
    rank_overall_ppr_total = rank(-points_ppr, ties.method = "min"),
    rank_overall_ppr_ppg = rank(-ppg_ppr, ties.method = "min"),
    rank_overall_std_total = rank(-points_std, ties.method = "min"),
    rank_overall_std_ppg = rank(-ppg_std, ties.method = "min")
  ) %>%
  ungroup() %>%
  arrange(season, desc(points_ppr))

cat("Player performance data loaded successfully.\n")

#### 2. HISTORICAL STANDARD ADP RANKS ####
cat("Scraping historical standard ADP data...\n")

historical_adp_standard <- data.frame()

for (season in 2015:2025) {
  cat(paste0("  Fetching standard ADP for ", season, "...\n"))
  
  tryCatch({
    url <- paste0("https://www.fantasypros.com/nfl/adp/overall.php?year=", season)
    player_stat <- url %>% 
      httr::GET(config = httr::config(ssl_verifypeer = FALSE)) %>% 
      read_html() 
    
    player <- player_stat %>% 
      html_nodes(".fp-player-link") %>%
      html_text()
    
    position_rank <- player_stat %>% 
      html_nodes(".player-label-report-page+ td") %>%
      html_text() %>% 
      head(length(player))
    
    cbs_rank <- player_stat %>% 
      html_nodes("td:nth-child(4)") %>%
      html_text() %>% 
      head(length(player))
    
    sleeper_rank <- player_stat %>% 
      html_nodes("td:nth-child(5)") %>%
      html_text() %>% 
      head(length(player))
    
    rts_rank <- player_stat %>% 
      html_nodes("td:nth-child(6)") %>%
      html_text() %>% 
      head(length(player))
    
    avg_rank <- player_stat %>% 
      html_nodes("td:nth-child(7)") %>%
      html_text() %>% 
      head(length(player))
    
    yearly_adp <- tibble(
      player = player,
      position_rank = position_rank,
      season = season,
      cbs_rank = cbs_rank,
      sleeper_rank = sleeper_rank,
      rts_rank = rts_rank,
      avg_rank = avg_rank,
      scoring_format = "standard"
    )
    
    historical_adp_standard <- rbind(historical_adp_standard, yearly_adp)
    
  }, error = function(e) {
    cat(paste0("    Error fetching data for ", season, ": ", e$message, "\n"))
  })
}

# Clean and process standard ADP data
historical_adp_standard <- historical_adp_standard %>%
  mutate(
    position = substr(position_rank, 1, 2),
    position = case_when(
      position == "QB" ~ "QB",
      position == "RB" ~ "RB",
      position == "WR" ~ "WR",
      position == "TE" ~ "TE",
      position == "K " ~ "K",
      position == "DS" ~ "DST",
      TRUE ~ position
    ),
    position_rank_num = as.numeric(gsub("[^0-9]", "", position_rank)),
    avg_rank_num = as.numeric(avg_rank),
    cbs_rank_num = as.numeric(cbs_rank),
    sleeper_rank_num = as.numeric(sleeper_rank),
    rts_rank_num = as.numeric(rts_rank)
  )

cat("Standard ADP data scraped successfully.\n")

#### 3. HISTORICAL PPR ADP RANKS ####
cat("Scraping historical PPR ADP data...\n")

historical_adp_ppr <- data.frame()

for (season in 2015:2025) {
  cat(paste0("  Fetching PPR ADP for ", season, "...\n"))
  
  tryCatch({
    url <- paste0("https://www.fantasypros.com/nfl/adp/ppr-overall.php?year=", season)
    player_stat <- url %>% 
      httr::GET(config = httr::config(ssl_verifypeer = FALSE)) %>% 
      read_html() 
    
    player <- player_stat %>% 
      html_nodes(".fp-player-link") %>%
      html_text()
    
    position_rank <- player_stat %>% 
      html_nodes(".player-label-report-page+ td") %>%
      html_text() %>% 
      head(length(player))
    
    espn_rank <- player_stat %>% 
      html_nodes("td:nth-child(4)") %>%
      html_text() %>% 
      head(length(player))
    
    sleeper_rank <- player_stat %>% 
      html_nodes("td:nth-child(5)") %>%
      html_text() %>% 
      head(length(player))
    
    nfl_rank <- player_stat %>% 
      html_nodes("td:nth-child(6)") %>%
      html_text() %>% 
      head(length(player))
    
    rts_rank <- player_stat %>% 
      html_nodes("td:nth-child(7)") %>%
      html_text() %>% 
      head(length(player))
    
    ffc_rank <- player_stat %>% 
      html_nodes("td:nth-child(8)") %>%
      html_text() %>% 
      head(length(player))
    
    avg_rank <- player_stat %>% 
      html_nodes("td:nth-child(9)") %>%
      html_text() %>% 
      head(length(player))
    
    yearly_adp <- tibble(
      player = player,
      position_rank = position_rank,
      season = season,
      espn_rank = espn_rank,
      sleeper_rank = sleeper_rank,
      nfl_rank = nfl_rank,
      rts_rank = rts_rank,
      ffc_rank = ffc_rank,
      avg_rank = avg_rank,
      scoring_format = "ppr"
    )
    
    historical_adp_ppr <- rbind(historical_adp_ppr, yearly_adp)
    
  }, error = function(e) {
    cat(paste0("    Error fetching data for ", season, ": ", e$message, "\n"))
  })
}

# Clean and process PPR ADP data
historical_adp_ppr <- historical_adp_ppr %>%
  mutate(
    position = substr(position_rank, 1, 2),
    position = case_when(
      position == "QB" ~ "QB",
      position == "RB" ~ "RB",
      position == "WR" ~ "WR",
      position == "TE" ~ "TE",
      position == "K " ~ "K",
      position == "DS" ~ "DST",
      TRUE ~ position
    ),
    position_rank_num = as.numeric(gsub("[^0-9]", "", position_rank)),
    avg_rank_num = as.numeric(avg_rank),
    espn_rank_num = as.numeric(espn_rank),
    sleeper_rank_num = as.numeric(sleeper_rank),
    nfl_rank_num = as.numeric(nfl_rank),
    rts_rank_num = as.numeric(rts_rank),
    ffc_rank_num = as.numeric(ffc_rank)
  )

cat("PPR ADP data scraped successfully.\n")

#### 4. JOIN ADP WITH PERFORMANCE DATA ####
cat("Joining ADP with performance data...\n")

# Function to match players between datasets
match_players <- function(adp_data, performance_data, scoring_type = "ppr") {
  
  # Select appropriate rank columns based on scoring type
  if (scoring_type == "ppr") {
    rank_total_col <- "rank_overall_ppr_total"
    rank_ppg_col <- "rank_overall_ppr_ppg"
    rank_pos_total_col <- "rank_position_ppr_total"
    rank_pos_ppg_col <- "rank_position_ppr_ppg"
    points_col <- "points_ppr"
    ppg_col <- "ppg_ppr"
  } else {
    rank_total_col <- "rank_overall_std_total"
    rank_ppg_col <- "rank_overall_std_ppg"
    rank_pos_total_col <- "rank_position_std_total"
    rank_pos_ppg_col <- "rank_position_std_ppg"
    points_col <- "points_std"
    ppg_col <- "ppg_std"
  }
  
  # Join ADP with performance
  joined_data <- adp_data %>%
    left_join(
      performance_data %>%
        select(player_id, player, season, position, games_played,
               all_of(c(points_col, ppg_col, rank_total_col, rank_ppg_col, 
                       rank_pos_total_col, rank_pos_ppg_col))),
      by = c("player", "season", "position"),
      suffix = c("_adp", "_actual")
    ) %>%
    mutate(
      # Calculate differences (positive = outperformed ADP)
      diff_overall_total = avg_rank_num - .data[[rank_total_col]],
      diff_overall_ppg = avg_rank_num - .data[[rank_ppg_col]],
      diff_position_total = position_rank_num - .data[[rank_pos_total_col]],
      diff_position_ppg = position_rank_num - .data[[rank_pos_ppg_col]],
      
      # Calculate percentage differences
      pct_diff_overall_total = round((diff_overall_total / avg_rank_num) * 100, 1),
      pct_diff_overall_ppg = round((diff_overall_ppg / avg_rank_num) * 100, 1),
      
      # Categorize as bust/value/expected
      performance_category_total = case_when(
        diff_overall_total >= 30 ~ "elite_value",
        diff_overall_total >= 15 ~ "good_value",
        diff_overall_total <= -30 ~ "major_bust",
        diff_overall_total <= -15 ~ "mild_bust",
        TRUE ~ "expected"
      ),
      performance_category_ppg = case_when(
        diff_overall_ppg >= 30 ~ "elite_value",
        diff_overall_ppg >= 15 ~ "good_value",
        diff_overall_ppg <= -30 ~ "major_bust",
        diff_overall_ppg <= -15 ~ "mild_bust",
        TRUE ~ "expected"
      )
    )
  
  return(joined_data)
}

# Process PPR data
adp_analysis_ppr <- match_players(historical_adp_ppr, player_performance, "ppr")

# Process Standard data
adp_analysis_standard <- match_players(historical_adp_standard, player_performance, "standard")

cat("Data joining completed successfully.\n")

#### 5. CREATE OUTPUT DIRECTORY AND SAVE DATA ####
cat("Creating output directory and saving data...\n")

# Create directory if it doesn't exist
output_dir <- "assets/data/adp"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat(paste0("Created directory: ", output_dir, "\n"))
}

# Save raw ADP data
write_csv(historical_adp_ppr, file.path(output_dir, "historical_adp_ppr.csv"))
write_csv(historical_adp_standard, file.path(output_dir, "historical_adp_standard.csv"))

# Save player performance data
write_csv(player_performance, file.path(output_dir, "player_performance.csv"))

# Save joined analysis data
write_csv(adp_analysis_ppr, file.path(output_dir, "adp_analysis_ppr.csv"))
write_csv(adp_analysis_standard, file.path(output_dir, "adp_analysis_standard.csv"))

# Create metadata file
metadata <- tibble(
  last_updated = Sys.time(),
  seasons_included = "2015-2025",
  ppr_records = nrow(adp_analysis_ppr),
  standard_records = nrow(adp_analysis_standard),
  performance_records = nrow(player_performance)
)
write_csv(metadata, file.path(output_dir, "metadata.csv"))

cat("\n=== Data Export Complete ===\n")
cat(paste0("Files saved to: ", output_dir, "\n"))
cat("Files created:\n")
cat("  - historical_adp_ppr.csv\n")
cat("  - historical_adp_standard.csv\n")
cat("  - player_performance.csv\n")
cat("  - adp_analysis_ppr.csv (joined data with calculations)\n")
cat("  - adp_analysis_standard.csv (joined data with calculations)\n")
cat("  - metadata.csv\n")

# Display summary statistics
cat("\n=== Summary Statistics ===\n")
cat(paste0("Total PPR ADP records: ", nrow(historical_adp_ppr), "\n"))
cat(paste0("Total Standard ADP records: ", nrow(historical_adp_standard), "\n"))
cat(paste0("Total performance records: ", nrow(player_performance), "\n"))

# Show sample of value/bust analysis for 2024
if (2024 %in% unique(adp_analysis_ppr$season)) {
  cat("\n=== 2024 PPR Top Values (Total Points) ===\n")
  top_values_2024 <- adp_analysis_ppr %>%
    filter(season == 2024, !is.na(diff_overall_total)) %>%
    arrange(desc(diff_overall_total)) %>%
    select(player, position, avg_rank_num, rank_overall_ppr_total, diff_overall_total) %>%
    head(5)
  print(top_values_2024)
  
  cat("\n=== 2024 PPR Top Busts (Total Points) ===\n")
  top_busts_2024 <- adp_analysis_ppr %>%
    filter(season == 2024, !is.na(diff_overall_total)) %>%
    arrange(diff_overall_total) %>%
    select(player, position, avg_rank_num, rank_overall_ppr_total, diff_overall_total) %>%
    head(5)
  print(top_busts_2024)
}