library(nflreadr)
library(dplyr)
library(jsonlite)
library(here)

# --- CONFIGURATION ---
YEARS_TO_FETCH <- 2020:2024 # Past 5 years of data
OUTPUT_DIR <- here::here("data_processing")
OUTPUT_FILE <- file.path(OUTPUT_DIR, "player_game_logs.json")

# --- DATA FETCHING ---
message(paste("Fetching weekly data for seasons", paste(YEARS_TO_FETCH, collapse = ", "), "..."))

# Load weekly offensive stats using nflreadr for multiple years
weekly_data <- tryCatch({
    nflreadr::load_player_stats(seasons = YEARS_TO_FETCH, stat_type = "offense")
}, error = function(e) {
    message("Error fetching weekly data: ", e$message)
    return(NULL)
})

if (is.null(weekly_data) || nrow(weekly_data) == 0) {
    stop("Failed to fetch or process weekly data. Aborting.")
}

message("Successfully fetched ", nrow(weekly_data), " records across ", length(YEARS_TO_FETCH), " seasons.")

# --- DATA PROCESSING ---
message("Processing and cleaning data...")

processed_data <- weekly_data %>%
    filter(season_type == "REG") %>%
    mutate(
        # Create a unified fumbles_lost column
        fumbles_lost = rushing_fumbles_lost + receiving_fumbles_lost
    ) %>%
    select(
        player_id,
        player_name,
        position,
        team = recent_team,
        season,
        week,
        # Passing stats
        attempts,
        completions,
        passing_yards,
        passing_tds,
        interceptions,
        # Rushing stats
        carries,
        rushing_yards,
        rushing_tds,
        # Receiving stats
        receptions,
        targets,
        receiving_yards,
        receiving_tds,
        # Other fantasy relevant stats
        fumbles_lost, # Use the new combined column
        special_teams_tds,
        fantasy_points_ppr,
        # Usage stats
        pacr = passing_air_yards,
        racr = receiving_air_yards
    ) %>%
    # Replace any remaining NA values with 0
    mutate(across(everything(), ~replace(., is.na(.), 0))) %>%
    # Add a unique game id for easy document creation in Firestore
    mutate(game_id = paste(player_id, season, week, sep = "_"))


# --- DATA EXPORT ---
OUTPUT_FILE_JSON <- file.path(OUTPUT_DIR, "player_game_logs.json")
OUTPUT_FILE_CSV <- file.path(OUTPUT_DIR, "player_game_logs.csv")

message(paste("Writing processed data to", OUTPUT_FILE_JSON, "and", OUTPUT_FILE_CSV))

if (!dir.exists(OUTPUT_DIR)) {
    dir.create(OUTPUT_DIR, recursive = TRUE)
}

# Export to CSV
write.csv(processed_data, OUTPUT_FILE_CSV, row.names = FALSE)
message("✅ CSV export complete! File saved as:", OUTPUT_FILE_CSV)

# Export to JSON
json_data <- toJSON(processed_data, pretty = TRUE, auto_unbox = TRUE)
write(json_data, OUTPUT_FILE_JSON)

message("✅ JSON export complete! File saved as:", OUTPUT_FILE_JSON)
message(paste("Total players processed:", length(unique(processed_data$player_id))))
message(paste("Total game logs:", nrow(processed_data)))
message(paste("Seasons included:", paste(sort(unique(processed_data$season)), collapse = ", ")))

# --- SCRIPT END --- 