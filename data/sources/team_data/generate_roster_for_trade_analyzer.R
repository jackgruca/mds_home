# data_processing/generate_roster_for_trade_analyzer.R
# Generate optimized NFL roster data specifically for the trade analyzer

# 1. SETUP
# ------------------------------------------------
# Install packages if you don't have them
# install.packages("nflreadr")
# install.packages("tidyverse")
# install.packages("jsonlite")

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)
library(dplyr)

cat("🏈 NFL Trade Analyzer - Roster Data Generator\n")
cat("Loaded libraries: nflreadr, tidyverse, jsonlite\n")

# Focus on current season for trade analyzer
current_year <- 2024
seasons_to_load <- c(current_year)

cat("Fetching roster data for season:", current_year, "\n")

# 2. DATA FETCHING AND CLEANING
# ------------------------------------------------
# Load current season rosters
roster_data <- load_rosters(seasons = seasons_to_load)

cat("Raw roster data loaded. Shape:", nrow(roster_data), "rows,", ncol(roster_data), "columns\n")

# Check what columns are available
cat("Available columns:\n")
print(names(roster_data))

# Clean and process the data specifically for trade analyzer
roster_data_cleaned <- roster_data %>%
  # Remove rows with missing essential data
  filter(!is.na(full_name), !is.na(team), !is.na(season)) %>%
  # Only include active players (not practice squad or IR)
  filter(status == "ACT" | is.na(status)) %>%
  
  # Clean up text fields
  mutate(
    full_name = str_trim(full_name),
    first_name = if("first_name" %in% names(.)) str_trim(first_name) else "",
    last_name = if("last_name" %in% names(.)) str_trim(last_name) else "",
    # Use depth_chart_position for accurate position (EDGE, OLB, etc.)
    position = if("depth_chart_position" %in% names(.)) str_trim(depth_chart_position) else str_trim(position),
    position_group = str_trim(position), # Keep the original position as position_group
    team = str_trim(team),
    college = if("college" %in% names(.)) str_trim(college) else "",
    status = if("status" %in% names(.)) str_trim(status) else "ACT"
  ) %>%
  
  # Convert fields to appropriate types
  mutate(
    season = as.integer(season),
    jersey_number = if("jersey_number" %in% names(.)) as.integer(jersey_number) else NA_integer_,
    height = if("height" %in% names(.)) as.character(height) else "",
    weight = if("weight" %in% names(.)) as.integer(weight) else NA_integer_,
    years_exp = if("years_exp" %in% names(.)) as.integer(years_exp) else NA_integer_,
    entry_year = if("entry_year" %in% names(.)) as.integer(entry_year) else NA_integer_,
    rookie_year = if("rookie_year" %in% names(.)) as.integer(rookie_year) else NA_integer_,
    birth_date = if("birth_date" %in% names(.)) as.character(birth_date) else ""
  ) %>%
  
  # Add computed fields for trade analyzer
  mutate(
    # Keep actual depth_chart_position but create standardized groups for value calculations
    # Note: position now contains depth_chart_position (like EDGE, OLB, etc.)
    position_standardized = case_when(
      position %in% c("QB") ~ "QB",
      position %in% c("RB", "FB", "HB") ~ "RB",
      position %in% c("WR") ~ "WR", 
      position %in% c("TE") ~ "TE",
      position %in% c("T", "OT", "LT", "RT") ~ "OT",
      position %in% c("G", "OG", "LG", "RG") ~ "OG",
      position %in% c("C", "OL") ~ "C",
      position %in% c("DE", "DL") ~ "DE",
      position %in% c("DT", "NT", "IDL") ~ "DT",
      position %in% c("OLB", "EDGE", "LOLB", "ROLB") ~ "EDGE",  # EDGE players properly categorized
      position %in% c("ILB", "LB", "MLB", "LILB", "RILB") ~ "LB",
      position %in% c("CB", "DB") ~ "CB",
      position %in% c("S", "FS", "SS", "SAF") ~ "S",
      position %in% c("K", "PK") ~ "K",
      position %in% c("P") ~ "P",
      position %in% c("LS") ~ "LS",
      TRUE ~ position # Keep original if not matched
    ),
    
    # Keep the actual position for display (e.g., EDGE, OLB, DE, etc.)
    position_display = position,
    
    # Calculate age at season
    age_at_season = if("birth_date" %in% names(.) && !all(is.na(birth_date))) {
      ifelse(!is.na(birth_date) & birth_date != "", 
             season - as.numeric(format(as.Date(birth_date), "%Y")), 
             ifelse(!is.na(years_exp), 22 + years_exp, 25)) # Estimate if no birth date
    } else {
      ifelse(!is.na(years_exp), 22 + years_exp, 25) # Default estimation
    },
    
    # Create market value estimation based on position, age, and experience
    base_market_value = case_when(
      position_standardized == "QB" ~ 35.0,
      position_standardized == "RB" ~ 15.0,
      position_standardized == "WR" ~ 20.0,
      position_standardized == "TE" ~ 12.0,
      position_standardized == "OT" ~ 18.0,
      position_standardized == "OG" ~ 10.0,
      position_standardized == "C" ~ 12.0,
      position_standardized == "DE" ~ 16.0,
      position_standardized == "DT" ~ 14.0,
      position_standardized == "EDGE" ~ 20.0,
      position_standardized == "LB" ~ 12.0,
      position_standardized == "CB" ~ 18.0,
      position_standardized == "S" ~ 14.0,
      position_standardized == "K" ~ 4.0,
      position_standardized == "P" ~ 3.0,
      TRUE ~ 10.0 # Default
    ),
    
    # Apply experience multiplier
    experience_multiplier = pmax(0.5, pmin(1.5, 0.7 + (ifelse(!is.na(years_exp), years_exp, 0) * 0.05))),
    
    # Apply age penalty
    age_penalty = case_when(
      age_at_season <= 27 ~ 1.0,
      age_at_season <= 30 ~ 0.9,
      age_at_season <= 33 ~ 0.7,
      TRUE ~ 0.5
    ),
    
    # Calculate final estimated market value
    estimated_market_value = round(base_market_value * experience_multiplier * age_penalty, 1),
    
    # Calculate estimated overall rating (60-99 scale)
    base_rating = 70 + pmin(20, ifelse(!is.na(years_exp), years_exp * 2, 0)),
    age_rating_bonus = case_when(
      age_at_season <= 23 ~ 5,
      age_at_season <= 28 ~ 10,
      age_at_season <= 32 ~ 5,
      TRUE ~ -5
    ),
    premium_position_bonus = ifelse(position_standardized %in% c("QB", "EDGE", "OT", "CB"), 3, 0),
    estimated_overall_rating = pmax(60, pmin(99, base_rating + age_rating_bonus + premium_position_bonus)),
    
    # Calculate estimated annual salary (percentage of market value)
    salary_percentage = case_when(
      !is.na(years_exp) & years_exp <= 3 ~ 0.08, # Rookie contracts
      !is.na(years_exp) & years_exp <= 6 ~ 0.12, # Second contracts  
      TRUE ~ 0.15 # Veteran contracts
    ),
    estimated_annual_salary = round(estimated_market_value * salary_percentage, 1),
    
    # Contract years remaining estimation
    estimated_contract_years = case_when(
      !is.na(years_exp) & years_exp <= 1 ~ 3L, # Rookie contract
      !is.na(years_exp) & years_exp <= 4 ~ 2L, # Near end of rookie deal
      TRUE ~ as.integer(2 + (ifelse(!is.na(years_exp), years_exp, 3) %% 3)) # Veteran contracts vary
    ),
    
    # Contract status
    contract_status = case_when(
      !is.na(years_exp) & years_exp <= 3 ~ "rookie",
      !is.na(years_exp) & years_exp <= 6 ~ "extension", 
      TRUE ~ "veteran"
    ),
    
    # Position importance factor
    position_importance = case_when(
      position_standardized == "QB" ~ 1.0,
      position_standardized == "EDGE" ~ 0.9,
      position_standardized == "OT" ~ 0.85,
      position_standardized == "CB" ~ 0.8,
      position_standardized == "WR" ~ 0.75,
      position_standardized == "DT" ~ 0.7,
      position_standardized == "S" ~ 0.65,
      position_standardized == "LB" ~ 0.6,
      position_standardized == "TE" ~ 0.55,
      position_standardized == "RB" ~ 0.5,
      position_standardized == "OG" ~ 0.45,
      position_standardized == "C" ~ 0.5,
      position_standardized == "DE" ~ 0.75,
      position_standardized == "K" ~ 0.2,
      position_standardized == "P" ~ 0.15,
      TRUE ~ 0.4
    ),
    
    # Age tier for trade logic
    age_tier = case_when(
      age_at_season <= 25 ~ "young",
      age_at_season <= 28 ~ "prime",
      age_at_season <= 31 ~ "veteran",
      TRUE ~ "aging"
    ),
    
    # Create unique player ID for trade analyzer
    player_trade_id = paste(
      str_replace_all(full_name, " ", "_"),
      team,
      season,
      sep = "_"
    ),
    
    # Flags for trade analyzer
    is_rookie = ifelse(!is.na(years_exp) & years_exp == 0, TRUE, FALSE),
    is_veteran = ifelse(!is.na(years_exp) & years_exp >= 3, TRUE, FALSE),
    is_active = TRUE, # Only active players in this dataset
    has_injury_concerns = FALSE, # Default to false, could be enhanced
    durability_score = 85.0 # Default good durability
  )

# Select columns optimized for trade analyzer
trade_analyzer_columns <- c(
  "player_trade_id", "full_name", "position_display", "position_standardized", "team", "season",
  "age_at_season", "years_exp", "jersey_number", "height", "weight", 
  "college", "status", "contract_status", "estimated_contract_years",
  "estimated_market_value", "estimated_overall_rating", "estimated_annual_salary",
  "position_importance", "age_tier", "is_rookie", "is_veteran", "is_active",
  "has_injury_concerns", "durability_score", "entry_year", "rookie_year"
)

# Filter to only include columns that exist
existing_columns <- intersect(trade_analyzer_columns, names(roster_data_cleaned))
roster_final <- roster_data_cleaned %>%
  select(all_of(existing_columns)) %>%
  # Rename for consistency with trade analyzer
  rename(
    playerId = player_trade_id,
    name = full_name,
    position = position_display,  # Use actual position (EDGE, OLB, etc.)
    position_group = position_standardized,  # Position group for calculations
    age = age_at_season,
    experience = years_exp,
    marketValue = estimated_market_value,
    overallRating = estimated_overall_rating,
    annualSalary = estimated_annual_salary,
    contractYearsRemaining = estimated_contract_years,
    positionImportance = position_importance,
    ageTier = age_tier,
    isRookie = is_rookie,
    isVeteran = is_veteran,
    isActive = is_active,
    hasInjuryConcerns = has_injury_concerns,
    durabilityScore = durability_score
  )

# Handle missing values
roster_final <- roster_final %>%
  mutate(across(where(is.character), ~ifelse(is.na(.), "", .))) %>%
  mutate(across(where(is.numeric), ~ifelse(is.na(.), 0, .))) %>%
  mutate(across(where(is.logical), ~ifelse(is.na(.), FALSE, .)))

cat("Data processed. Final shape:", nrow(roster_final), "rows,", ncol(roster_final), "columns\n")

# 3. DATA VALIDATION AND SUMMARY
# ------------------------------------------------
cat("\n=== TRADE ANALYZER DATA SUMMARY ===\n")
cat("Total active players:", nrow(roster_final), "\n")
cat("Season:", unique(roster_final$season), "\n")
cat("Teams:", length(unique(roster_final$team)), "\n")
cat("Unique players:", length(unique(roster_final$playerId)), "\n")

# Position breakdown
cat("\nPosition breakdown:\n")
position_summary <- roster_final %>%
  count(position, sort = TRUE)
print(position_summary)

# Team breakdown (should be roughly equal)
cat("\nPlayers by team:\n")
team_summary <- roster_final %>%
  count(team, sort = TRUE)
print(team_summary)

# Value distribution
cat("\nMarket value distribution:\n")
value_summary <- roster_final %>%
  summarise(
    min_value = min(marketValue),
    q25_value = quantile(marketValue, 0.25),
    median_value = median(marketValue),
    q75_value = quantile(marketValue, 0.75),
    max_value = max(marketValue),
    mean_value = round(mean(marketValue), 1)
  )
print(value_summary)

# 4. EXPORT TO CSV
# ------------------------------------------------
output_file_csv <- "../processed/player_stats/nfl_roster_data.csv"

cat("\nExporting trade analyzer data to", output_file_csv, "...\n")

# Export to CSV
write.csv(roster_final, output_file_csv, row.names = FALSE)
cat("✅ CSV export complete! File saved as:", output_file_csv, "\n")

# 5. DATA VALIDATION
# ------------------------------------------------
cat("\n=== DATA QUALITY CHECKS ===\n")

# Check for missing critical data
missing_check <- roster_final %>%
  summarise(
    missing_names = sum(name == ""),
    missing_positions = sum(position == ""),
    missing_teams = sum(team == ""),
    missing_values = sum(marketValue == 0),
    missing_ratings = sum(overallRating == 0)
  )

cat("Missing data check:\n")
print(missing_check)

# Sample high-value players
cat("\nTop 10 highest value players:\n")
top_players <- roster_final %>%
  arrange(desc(marketValue)) %>%
  head(10) %>%
  select(name, position, team, age, experience, marketValue, overallRating)
print(top_players)

# 6. SAMPLE DATA PREVIEW
# ------------------------------------------------
cat("\n=== SAMPLE DATA PREVIEW ===\n")
cat("First few records:\n")
sample_data <- roster_final %>%
  head(5) %>%
  select(playerId, name, position, team, age, marketValue, overallRating, ageTier)
print(sample_data)

cat("\nUnique positions available:\n")
print(sort(unique(roster_final$position)))

cat("\nColumn names for trade analyzer:\n")
print(names(roster_final))

cat("\n🎉 Trade Analyzer roster data generation complete!\n")
cat("📊 Total records exported:", nrow(roster_final), "active NFL players\n")
cat("📁 File location: assets/nfl_roster_data.csv\n")
cat("🔧 Next step: Update NFLRosterService to use CSV data\n")