library(nflreadr)
library(dplyr)
library(jsonlite)
library(here)

# --- CONFIGURATION ---
YEAR_TO_FETCH <- 2023 # The most recent full season with available data
OUTPUT_DIR <- here::here("data_processing")
OUTPUT_FILE <- file.path(OUTPUT_DIR, "player_game_logs.json")

# --- DATA FETCHING ---
message(paste("Fetching weekly data for the", YEAR_TO_FETCH, "season..."))

# Load weekly offensive stats using nflreadr
weekly_data <- tryCatch({
    nflreadr::load_player_stats(seasons = YEAR_TO_FETCH, stat_type = "offense")
}, error = function(e) {
    message("Error fetching weekly data: ", e$message)
    return(NULL)
})

if (is.null(weekly_data) || nrow(weekly_data) == 0) {
    stop("Failed to fetch or process weekly data. Aborting.")
}

message("Successfully fetched ", nrow(weekly_data), " records.")

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
message(paste("Writing processed data to", OUTPUT_FILE))

if (!dir.exists(OUTPUT_DIR)) {
    dir.create(OUTPUT_DIR, recursive = TRUE)
}

json_data <- toJSON(processed_data, pretty = TRUE, auto_unbox = TRUE)
write(json_data, OUTPUT_FILE)

message("✅ Successfully created player_game_logs.json")
message(paste("Total players processed:", length(unique(processed_data$player_id))))
message(paste("Total game logs:", nrow(processed_data)))

# --- SCRIPT END --- 