# data_processing/get_roster_data.R

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

cat("Loaded libraries: nflreadr, tidyverse, jsonlite\n")

# Define seasons to load. Let's grab the last 10 years of data.
current_year <- as.numeric(format(Sys.Date(), "%Y"))
seasons_to_load <- (current_year - 10):(current_year - 1)

cat("Fetching roster data for seasons:", paste(seasons_to_load, collapse=", "), "\n")

# 2. DATA FETCHING AND CLEANING
# ------------------------------------------------
# Load rosters data for all seasons
roster_data <- load_rosters(seasons = seasons_to_load)

cat("Raw roster data loaded. Shape:", nrow(roster_data), "rows,", ncol(roster_data), "columns\n")

# Check what columns are available
cat("Available columns:\n")
print(names(roster_data))

# Clean and process the data
roster_data_cleaned <- roster_data %>%
  # Remove rows with missing essential data
  filter(!is.na(full_name), !is.na(team), !is.na(season)) %>%
  
  # Clean up text fields - only clean columns that exist
  mutate(
    full_name = str_trim(full_name),
    first_name = if("first_name" %in% names(.)) str_trim(first_name) else "",
    last_name = if("last_name" %in% names(.)) str_trim(last_name) else "",
    position = str_trim(position),
    team = str_trim(team),
    college = if("college" %in% names(.)) str_trim(college) else "",
    status = if("status" %in% names(.)) str_trim(status) else ""
  ) %>%
  
  # Convert certain fields to appropriate types
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
  
  # Add computed fields
  mutate(
    # Create position group based on position
    position_group = case_when(
      position %in% c("QB") ~ "QB",
      position %in% c("RB", "FB") ~ "RB",
      position %in% c("WR") ~ "WR", 
      position %in% c("TE") ~ "TE",
      position %in% c("T", "G", "C", "OT", "OG") ~ "OL",
      position %in% c("DE", "DT", "NT") ~ "DL",
      position %in% c("OLB", "ILB", "LB", "MLB") ~ "LB",
      position %in% c("CB", "S", "FS", "SS", "DB") ~ "DB",
      position %in% c("K") ~ "K",
      position %in% c("P") ~ "P",
      position %in% c("LS") ~ "LS",
      TRUE ~ "Other"
    ),
    
    # Calculate age at season if birth_date exists
    age_at_season = if("birth_date" %in% names(.) && !all(is.na(birth_date))) {
      ifelse(!is.na(birth_date) & birth_date != "", 
             season - as.numeric(format(as.Date(birth_date), "%Y")), 
             NA_integer_)
    } else {
      NA_integer_
    },
    
    # Create a unique player identifier
    player_id = paste(
      ifelse(first_name != "", first_name, "Unknown"),
      ifelse(last_name != "", last_name, "Player"),
      ifelse(birth_date != "", birth_date, season),
      sep = "_"
    ),
    
    # Convert logical/boolean columns to 1/0 for Firebase compatibility
    is_rookie = ifelse(!is.na(years_exp) & years_exp == 0, 1, 0),
    is_veteran = ifelse(!is.na(years_exp) & years_exp >= 3, 1, 0),
    
    # Status flags - only if status column exists
    is_active = if("status" %in% names(.)) {
      ifelse(status == "ACT", 1, 0)
    } else {
      1 # Assume active if no status info
    },
    is_practice_squad = if("status" %in% names(.)) {
      ifelse(status %in% c("RES/PS", "PS"), 1, 0)
    } else {
      0
    },
    is_injured_reserve = if("status" %in% names(.)) {
      ifelse(status %in% c("IR", "RES/IR"), 1, 0)
    } else {
      0
    }
  )

# Now select columns based on what's available
columns_to_select <- c("full_name", "player_id", "position", "position_group", "team", "season",
                      "is_rookie", "is_veteran", "is_active", "is_practice_squad", "is_injured_reserve")

# Add optional columns if they exist
if("first_name" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "first_name")
}
if("last_name" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "last_name")
}
if("jersey_number" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "jersey_number")
}
if("height" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "height")
}
if("weight" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "weight")
}
if("age_at_season" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "age_at_season")
}
if("birth_date" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "birth_date")
}
if("years_exp" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "years_exp")
}
if("status" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "status")
}
if("college" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "college")
}
if("entry_year" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "entry_year")
}
if("rookie_year" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "rookie_year")
}
if("depth_chart_position" %in% names(roster_data_cleaned)) {
  columns_to_select <- c(columns_to_select, "depth_chart_position")
}

# Select only the columns that exist
roster_data_cleaned <- roster_data_cleaned %>%
  select(all_of(columns_to_select))

cat("Data cleaned. Final shape:", nrow(roster_data_cleaned), "rows,", ncol(roster_data_cleaned), "columns\n")

# 3. DATA VALIDATION AND SUMMARY
# ------------------------------------------------
cat("\n=== DATA SUMMARY ===\n")
cat("Total records:", nrow(roster_data_cleaned), "\n")
cat("Seasons covered:", min(roster_data_cleaned$season), "to", max(roster_data_cleaned$season), "\n")
cat("Teams:", length(unique(roster_data_cleaned$team)), "\n")
cat("Unique players:", length(unique(roster_data_cleaned$player_id)), "\n")

# Position breakdown
cat("\nPosition breakdown:\n")
position_summary <- roster_data_cleaned %>%
  count(position, sort = TRUE)
print(position_summary)

# Season breakdown
cat("\nRecords by season:\n")
season_summary <- roster_data_cleaned %>%
  count(season, sort = TRUE)
print(season_summary)

# Check for any missing critical data
missing_summary <- roster_data_cleaned %>%
  summarise(
    missing_names = sum(is.na(full_name)),
    missing_positions = sum(is.na(position)),
    missing_teams = sum(is.na(team)),
    missing_seasons = sum(is.na(season))
  )

cat("\nMissing data check:\n")
print(missing_summary)

# 4. EXPORT TO JSON AND CSV
# ------------------------------------------------
output_file_json <- "roster_data.json"
output_file_csv <- "player_roster_info.csv"

cat("\nExporting data to", output_file_json, "and", output_file_csv, "...\n")

# Prepare data for export
export_data <- roster_data_cleaned %>%
  # Remove any remaining NA values by converting to empty strings for character columns
  mutate(across(where(is.character), ~ifelse(is.na(.), "", .))) %>%
  # Convert NA numeric values to 0
  mutate(across(where(is.numeric), ~ifelse(is.na(.), 0, .)))

# Export to CSV
write.csv(export_data, output_file_csv, row.names = FALSE)
cat("✅ CSV export complete! File saved as:", output_file_csv, "\n")

# Convert to list format for JSON export
roster_list <- export_data %>%
  # Convert to list
  pmap(list) %>%
  # Name each record with a unique identifier
  set_names(paste0("roster_", seq_along(.)))

# Export to JSON
write_json(roster_list, output_file_json, pretty = TRUE, auto_unbox = TRUE)

cat("✅ JSON export complete! File saved as:", output_file_json, "\n")
cat("📊 Total records exported:", nrow(export_data), "rows to CSV,", length(roster_list), "records to JSON\n")

# 5. QUICK DATA PREVIEW
# ------------------------------------------------
cat("\n=== SAMPLE DATA PREVIEW ===\n")
cat("First few records:\n")
print(head(roster_data_cleaned, 3))

cat("\nUnique positions available:\n")
print(sort(unique(roster_data_cleaned$position)))

cat("\nFinal column names:\n")
print(names(roster_data_cleaned))

cat("\nScript completed successfully! 🎉\n")
cat("Next step: Run upload_roster_data.js to upload this data to Firestore.\n") 