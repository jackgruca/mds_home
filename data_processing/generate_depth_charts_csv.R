# Generate NFL Depth Charts CSV from nflreadr
# Following the same pattern as other R data export scripts

library(nflreadr)
library(dplyr)
library(readr)

# Load roster data to build depth charts
cat("Loading NFL roster data for depth charts...\n")
roster_data <- nflreadr::load_rosters(seasons = 2020:2024)

# Clean and process depth chart data
depth_charts_cleaned <- roster_data %>%
  filter(
    !is.na(full_name),
    !is.na(team),
    !is.na(position),
    status == "ACT" | status == "RES"  # Active or Reserve status
  ) %>%
  select(
    season,
    team,
    full_name,
    position,
    jersey_number,
    depth_chart_position,
    years_exp,
    height,
    weight,
    status,
    rookie_year,
    college
  ) %>%
  # Add depth chart order where missing and calculate age
  mutate(
    age_at_season = season - rookie_year + ifelse(!is.na(rookie_year), 22, 25),  # Estimate age
    depth_chart_order = 1  # Set default depth chart order
  ) %>%
  group_by(season, team, position) %>%
  arrange(desc(years_exp), desc(age_at_season)) %>%
  mutate(
    depth_chart_order = row_number(),
    # Standardize position groups
    position_group = case_when(
      position %in% c("QB") ~ "Quarterback",
      position %in% c("RB", "FB") ~ "Running Back",
      position %in% c("WR") ~ "Wide Receiver", 
      position %in% c("TE") ~ "Tight End",
      position %in% c("T", "LT", "RT", "G", "LG", "RG", "C") ~ "Offensive Line",
      position %in% c("DE", "DT", "NT") ~ "Defensive Line",
      position %in% c("LB", "OLB", "ILB", "MLB") ~ "Linebacker",
      position %in% c("CB", "S", "FS", "SS", "DB") ~ "Defensive Back",
      position %in% c("K") ~ "Kicker",
      position %in% c("P") ~ "Punter",
      position %in% c("LS") ~ "Long Snapper",
      TRUE ~ "Other"
    ),
    # Create standardized depth chart position (keep existing if available)
    depth_chart_position_clean = case_when(
      position == "QB" ~ "QB",
      position == "RB" & depth_chart_order == 1 ~ "RB",
      position == "RB" & depth_chart_order > 1 ~ paste0("RB", depth_chart_order),
      position == "FB" ~ "FB",
      position == "WR" & depth_chart_order == 1 ~ "WR1",
      position == "WR" & depth_chart_order == 2 ~ "WR2", 
      position == "WR" & depth_chart_order == 3 ~ "WR3",
      position == "WR" & depth_chart_order > 3 ~ paste0("WR", depth_chart_order),
      position == "TE" & depth_chart_order == 1 ~ "TE",
      position == "TE" & depth_chart_order > 1 ~ paste0("TE", depth_chart_order),
      position %in% c("LT", "T") & depth_chart_order == 1 ~ "LT",
      position %in% c("LG", "G") & depth_chart_order == 1 ~ "LG",
      position == "C" & depth_chart_order == 1 ~ "C",
      position %in% c("RG", "G") & depth_chart_order == 2 ~ "RG", 
      position %in% c("RT", "T") & depth_chart_order == 2 ~ "RT",
      position == "DE" & depth_chart_order == 1 ~ "DE1",
      position == "DE" & depth_chart_order == 2 ~ "DE2",
      position == "DT" & depth_chart_order == 1 ~ "DT1",
      position == "DT" & depth_chart_order == 2 ~ "DT2",
      position == "NT" ~ "DT1", # Nose tackle maps to DT1
      position %in% c("OLB", "EDGE") & depth_chart_order == 1 ~ "OLB1",
      position %in% c("OLB", "EDGE") & depth_chart_order == 2 ~ "OLB2", 
      position %in% c("ILB", "MLB", "LB") & depth_chart_order == 1 ~ "ILB",
      position %in% c("ILB", "MLB", "LB") & depth_chart_order > 1 ~ paste0("ILB", depth_chart_order),
      position == "CB" & depth_chart_order == 1 ~ "CB1",
      position == "CB" & depth_chart_order == 2 ~ "CB2",
      position == "CB" & depth_chart_order > 2 ~ paste0("CB", depth_chart_order),
      position == "FS" | (position == "S" & depth_chart_order == 1) ~ "FS",
      position == "SS" | (position == "S" & depth_chart_order == 2) ~ "SS",
      position == "S" & depth_chart_order > 2 ~ paste0("S", depth_chart_order),
      position == "K" ~ "K",
      position == "P" ~ "P", 
      position == "LS" ~ "LS",
      TRUE ~ paste0(position, depth_chart_order)
    )
  ) %>%
  ungroup() %>%
  # Final cleanup and use the cleaned position or original
  mutate(
    depth_chart_position = coalesce(depth_chart_position, depth_chart_position_clean)
  ) %>%
  filter(
    !is.na(depth_chart_position),
    season >= 2020,
    season <= 2024
  ) %>%
  arrange(season, team, position, depth_chart_order)

cat(sprintf("Processed %d depth chart entries\n", nrow(depth_charts_cleaned)))

# Sample the data to show what we have
cat("Sample depth chart data:\n")
sample_data <- depth_charts_cleaned %>%
  filter(season == 2024, team == "BUF") %>%
  select(team, position, depth_chart_position, full_name, depth_chart_order) %>%
  head(10)
print(sample_data)

# Write to CSV
output_file <- "assets/nfl_depth_charts.csv"
write_csv(depth_charts_cleaned, output_file)
cat(sprintf("Depth charts exported to %s\n", output_file))

# Generate summary stats
cat("\nDepth chart summary:\n")
summary_stats <- depth_charts_cleaned %>%
  group_by(season, position) %>%
  summarise(
    teams_with_position = n_distinct(team),
    total_players = n(),
    avg_depth = mean(depth_chart_order, na.rm = TRUE),
    .groups = "drop"
  )

print(summary_stats)

cat("Depth chart CSV generation complete!\n")