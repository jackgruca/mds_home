# data_processing/get_player_headshots.R

# 1. SETUP
# ------------------------------------------------
# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)
library(dplyr)

cat("🏈 NFL Player Headshot Data Processing Script\n")
cat(paste(rep("=", 50), collapse=""), "\n")

# Define seasons to load - focusing on recent years for best headshot coverage
current_year <- as.numeric(format(Sys.Date(), "%Y"))
seasons_to_load <- (current_year - 5):current_year  # Last 5 years plus current

cat("Fetching player headshot data for seasons:", paste(seasons_to_load, collapse=", "), "\n")

# 2. DATA FETCHING AND PROCESSING
# ------------------------------------------------
# Load roster data with headshots
cat("Loading roster data from nflreadr...\n")
roster_data <- load_rosters(seasons = seasons_to_load)

cat("Raw roster data loaded. Shape:", nrow(roster_data), "rows,", ncol(roster_data), "columns\n")

# Check what columns are available
cat("\nAvailable columns:\n")
available_columns <- names(roster_data)
print(available_columns)

# Check if headshot_url exists
if ("headshot_url" %in% available_columns) {
  cat("✅ headshot_url column found!\n")
} else {
  cat("❌ headshot_url column not found. Available columns:\n")
  print(available_columns)
  stop("headshot_url column is required but not found in roster data")
}

# Process and clean the headshot data
cat("\nProcessing headshot data...\n")
headshot_data <- roster_data %>%
  # Filter for records with valid headshot URLs
  filter(
    !is.na(headshot_url), 
    headshot_url != "", 
    !is.na(full_name),
    full_name != "",
    !is.na(gsis_id),
    gsis_id != ""
  ) %>%
  
  # Select relevant columns
  select(
    player_id = gsis_id,
    full_name,
    first_name, 
    last_name,
    position,
    team,
    season,
    headshot_url,
    # Add any other useful columns if they exist
    any_of(c("jersey_number", "height", "weight", "college", "years_exp", "birth_date"))
  ) %>%
  
  # Clean up text fields
  mutate(
    full_name = str_trim(full_name),
    first_name = if_else(is.na(first_name), "", str_trim(first_name)),
    last_name = if_else(is.na(last_name), "", str_trim(last_name)),
    position = str_trim(position),
    team = str_trim(team),
    headshot_url = str_trim(headshot_url)
  ) %>%
  
  # Remove any remaining NA/empty values
  filter(
    !is.na(player_id),
    !is.na(full_name),
    !is.na(headshot_url),
    headshot_url != ""
  ) %>%
  
  # Get most recent headshot for each player (based on season)
  group_by(player_id) %>%
  arrange(desc(season)) %>%
  slice_head(n = 1) %>%
  ungroup() %>%
  
  # Create lookup variations for flexible matching
  mutate(
    # Normalize name for lookup
    lookup_name = str_to_lower(str_trim(full_name)),
    lookup_name_no_punct = str_replace_all(lookup_name, "[^a-z0-9 ]", ""),
    
    # Create position-specific lookup key
    lookup_key = paste(lookup_name, str_to_lower(position), sep = "_"),
    
    # Add metadata
    data_source = "nflreadr",
    last_updated = Sys.time(),
    processing_notes = paste("Processed on", Sys.Date(), "from", min(seasons_to_load), "-", max(seasons_to_load), "seasons")
  ) %>%
  
  # Final selection and ordering
  select(
    # Core identification
    player_id,
    full_name,
    first_name,
    last_name,
    position,
    team,
    season,
    
    # Headshot data
    headshot_url,
    
    # Lookup keys
    lookup_name,
    lookup_name_no_punct,
    lookup_key,
    
    # Additional player info (if available)
    everything(),
    
    # Metadata
    data_source,
    last_updated,
    processing_notes
  ) %>%
  
  # Remove any duplicate columns that might have been created
  select(-any_of(c("NULL"))) %>%
  
  # Sort by player name for easier review
  arrange(full_name)

cat("✅ Headshot data processed successfully!\n")
cat("Final dataset shape:", nrow(headshot_data), "rows,", ncol(headshot_data), "columns\n")

# 3. DATA VALIDATION AND SUMMARY
# ------------------------------------------------
cat("\n=== DATA VALIDATION SUMMARY ===\n")
cat("Total players with headshots:", nrow(headshot_data), "\n")
cat("Seasons covered:", min(headshot_data$season), "to", max(headshot_data$season), "\n")
cat("Teams represented:", length(unique(headshot_data$team)), "\n")
cat("Unique positions:", length(unique(headshot_data$position)), "\n")

# Position breakdown
cat("\nPosition breakdown:\n")
position_summary <- headshot_data %>%
  count(position, sort = TRUE)
print(position_summary)

# Team breakdown (top 10)
cat("\nTop 10 teams by player count:\n")
team_summary <- headshot_data %>%
  count(team, sort = TRUE) %>%
  slice_head(n = 10)
print(team_summary)

# Check for potential issues
cat("\nData quality checks:\n")
missing_summary <- headshot_data %>%
  summarise(
    missing_names = sum(is.na(full_name) | full_name == ""),
    missing_positions = sum(is.na(position) | position == ""),
    missing_teams = sum(is.na(team) | team == ""),
    missing_headshots = sum(is.na(headshot_url) | headshot_url == ""),
    invalid_urls = sum(!str_detect(headshot_url, "^https?://"))
  )
print(missing_summary)

# Sample headshot URLs for validation
cat("\nSample headshot URLs:\n")
sample_urls <- headshot_data %>%
  slice_sample(n = min(5, nrow(headshot_data))) %>%
  select(full_name, position, team, headshot_url)
print(sample_urls)

# 4. EXPORT TO JSON
# ------------------------------------------------
output_file <- "player_headshots.json"

cat("\n=== EXPORT PROCESS ===\n")
cat("Exporting data to", output_file, "...\n")

# Convert to list format for JSON export
headshot_list <- headshot_data %>%
  # Convert any remaining NA values to appropriate defaults
  mutate(
    across(where(is.character), ~ifelse(is.na(.), "", .)),
    across(where(is.numeric), ~ifelse(is.na(.), 0, .))
  ) %>%
  # Convert datetime to character for JSON compatibility
  mutate(
    last_updated = as.character(last_updated)
  ) %>%
  # Convert to list format
  pmap(list) %>%
  # Name each record with player_id for efficient Firebase lookups
  set_names(paste0("player_", headshot_data$player_id))

# Export to JSON with pretty formatting
write_json(headshot_list, output_file, pretty = TRUE, auto_unbox = TRUE)

cat("✅ Export complete! File saved as:", output_file, "\n")
cat("📊 Total records exported:", length(headshot_list), "\n")

# 5. GENERATE SUMMARY REPORT
# ------------------------------------------------
cat("\n=== PROCESSING SUMMARY REPORT ===\n")
cat("🏈 NFL Player Headshots Data Processing Complete!\n")
cat("📅 Processing Date:", as.character(Sys.time()), "\n")
cat("📊 Total Players Processed:", nrow(headshot_data), "\n")
cat("🔗 Valid Headshot URLs:", sum(!is.na(headshot_data$headshot_url) & headshot_data$headshot_url != ""), "\n")
cat("⚽ Positions Covered:", paste(sort(unique(headshot_data$position)), collapse = ", "), "\n")
cat("🏟️ Teams Covered:", length(unique(headshot_data$team)), "\n")
cat("📁 Output File:", output_file, "\n")

# Generate a small sample for manual verification
verification_sample <- headshot_data %>%
  slice_sample(n = min(3, nrow(headshot_data))) %>%
  select(full_name, position, team, headshot_url)

cat("\n=== VERIFICATION SAMPLE ===\n")
cat("Sample players for manual verification:\n")
print(verification_sample)

cat("\n\n")
cat("🎉 Script completed successfully!\n")
cat("📋 Next Steps:\n")
cat("   1. Review the generated", output_file, "file\n")
cat("   2. Run upload_player_headshots.js to upload to Firestore\n")
cat("   3. Test headshot integration in the Flutter app\n")
cat("\n")
cat(paste(rep("=", 50), collapse=""), "\n")