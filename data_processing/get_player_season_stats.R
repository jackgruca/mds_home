# data_processing/get_player_season_stats.R

# 1. SETUP & DEFENSIVE UTILITIES
# ----------------------------------------------------------------------
# Install packages if you don't have them
# install.packages(c("nflreadr", "tidyverse", "jsonlite"))

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)

cat("Loaded libraries: nflreadr, tidyverse, jsonlite\n\n")

# --- Defensive Coding Utilities from Guide ---

# Utility to safely join dataframes, checking for keys first
safe_join <- function(df1, df2, join_keys, join_type = "left") {
  # Check if join keys exist in both datasets
  missing_keys_df1 <- setdiff(join_keys, names(df1))
  missing_keys_df2 <- setdiff(join_keys, names(df2))
  
  if (length(missing_keys_df1) > 0) {
    cat(sprintf("⚠️ WARNING: Join keys missing from first dataset: %s. Skipping join.\n", paste(missing_keys_df1, collapse = ", ")))
    return(df1)
  }
  if (length(missing_keys_df2) > 0) {
    cat(sprintf("⚠️ WARNING: Join keys missing from second dataset: %s. Skipping join.\n", paste(missing_keys_df2, collapse = ", ")))
    return(df1)
  }
  
  # Perform join
  cat(sprintf("-> Joining with keys: [ %s ]\n", paste(join_keys, collapse = ", ")))
  result <- switch(join_type,
    "left" = left_join(df1, df2, by = join_keys),
    "inner" = inner_join(df1, df2, by = join_keys),
    "full" = full_join(df1, df2, by = join_keys)
  )
  
  cat(sprintf("   Join completed: %d rows in result\n", nrow(result)))
  return(result)
}

# Utility to validate a loaded dataset
validate_dataset <- function(df, dataset_name) {
  cat(sprintf("\n🔍 Validating %s...\n", dataset_name))
  if (is.null(df) || nrow(df) == 0) {
    cat("   - ⚠️ WARNING: Dataset is empty or NULL.\n")
    return(FALSE)
  }
  cat(sprintf("   - Rows: %d, Columns: %d\n", nrow(df), ncol(df)))
  
  key_cols <- c("player_id", "player_name", "player_display_name", "gsis_id", "pfr_id", "season")
  available_keys <- intersect(key_cols, names(df))
  cat(sprintf("   - Available join keys: [ %s ]\n", paste(available_keys, collapse = ", ")))
  return(TRUE)
}

# Utility to safely export data to JSON
export_to_json_safe <- function(data, filename = "player_stats.json") {
  tryCatch({
    cat(sprintf("\n-> Cleaning and exporting data to %s...\n", filename))
    data_clean <- data %>%
      mutate(across(where(is.factor), as.character)) %>%
      mutate(across(where(~ any(is.infinite(.))), ~ ifelse(is.infinite(.), NA, .))) %>%
      mutate_if(is.numeric, ~replace(., is.nan(.), NA))

    jsonlite::write_json(data_clean, filename, pretty = TRUE, na = "null", auto_unbox = TRUE)
    cat(sprintf("✅ Successfully exported %d rows and %d columns to %s\n", nrow(data_clean), ncol(data_clean), filename))
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("❌ JSON export failed: %s\n", e$message))
    return(FALSE)
  })
}

# 2. CONFIGURATION & DATA LOADING
# ----------------------------------------------------------------------
seasons_to_load <- 2021:nflreadr::most_recent_season()
cat(paste("-> Preparing to load data for seasons:", paste(seasons_to_load, collapse=", "), "\n"))

# Using a function to safely load data
safe_load <- function(loader, ...) {
  dataset_name <- deparse(substitute(loader))
  tryCatch({
    cat(paste("\n-- Loading:", dataset_name, "..."))
    df <- loader(...)
    cat(paste(" done.\n"))
    return(df)
  }, error = function(e) {
    cat(paste("\n----> ❌ ERROR: Failed to load", dataset_name, ". Skipping. Error:", e$message, "\n"))
    return(NULL)
  })
}

# Load all required data sources safely
player_stats_raw <- safe_load(load_player_stats, seasons = seasons_to_load)
rosters          <- safe_load(load_rosters, seasons = seasons_to_load)
snap_counts      <- safe_load(load_snap_counts, seasons = seasons_to_load)
combine          <- safe_load(load_combine, seasons = 2000:nflreadr::most_recent_season())

# Validate loaded data
validate_dataset(player_stats_raw, "Player Stats (Raw)")
validate_dataset(rosters, "Rosters")
validate_dataset(snap_counts, "Snap Counts")
validate_dataset(combine, "Combine Data")

# Halt if core data is missing
if (is.null(player_stats_raw)) {
  stop("❌ FATAL: Core data 'player_stats_raw' could not be loaded. Halting script.")
}

# 3. DATA AGGREGATION & PREPARATION
# ----------------------------------------------------------------------
cat("\n-> Aggregating and preparing data...\n")

# First, let's inspect what join keys are actually available
cat("\n🔍 Inspecting available join keys in each dataset:\n")
if (!is.null(player_stats_raw)) {
  cat("Player Stats keys:", paste(intersect(c("player_id", "player_display_name", "gsis_id"), names(player_stats_raw)), collapse = ", "), "\n")
}
if (!is.null(rosters)) {
  cat("Rosters keys:", paste(intersect(c("player_id", "player_display_name", "gsis_id", "pfr_id"), names(rosters)), collapse = ", "), "\n")
}
if (!is.null(snap_counts)) {
  cat("Snap Counts keys:", paste(intersect(c("player_id", "player_display_name", "pfr_id", "player"), names(snap_counts)), collapse = ", "), "\n")
}
if (!is.null(combine)) {
  cat("Combine keys:", paste(intersect(c("player_name", "player_display_name"), names(combine)), collapse = ", "), "\n")
}

# Aggregate Player Stats (using correct player_id)
stats_agg <- player_stats_raw %>%
  group_by(player_id, player_display_name, season) %>%
  summarise(
    games = n_distinct(week),
    completions = sum(completions, na.rm = TRUE),
    attempts = sum(attempts, na.rm = TRUE),
    passing_yards = sum(passing_yards, na.rm = TRUE),
    passing_tds = sum(passing_tds, na.rm = TRUE),
    interceptions = sum(interceptions, na.rm = TRUE),
    rushing_attempts = sum(carries, na.rm = TRUE),
    rushing_yards = sum(rushing_yards, na.rm = TRUE),
    rushing_tds = sum(rushing_tds, na.rm = TRUE),
    receptions = sum(receptions, na.rm = TRUE),
    targets = sum(targets, na.rm = TRUE),
    receiving_yards = sum(receiving_yards, na.rm = TRUE),
    receiving_tds = sum(receiving_tds, na.rm = TRUE),
    fantasy_points = sum(fantasy_points, na.rm = TRUE),
    fantasy_points_ppr = sum(fantasy_points_ppr, na.rm = TRUE),
    .groups = 'drop'
  )

cat("   - Player stats aggregated.\n")

# 4. MASTER JOIN STRATEGY (FIXED)
# ----------------------------------------------------------------------
cat("\n-> Performing master join with corrected strategy...\n")

# Start with aggregated stats as the base
master_data <- stats_agg

# JOIN 1: Add roster information
if (!is.null(rosters)) {
  cat("\n-> Step 1: Joining with rosters...\n")
  
  tryCatch({
    # First, let's see what columns are actually available in rosters
    cat("🔍 Available roster columns:", paste(names(rosters), collapse = ", "), "\n")
    
    # Create a clean rosters dataset with unique player-season combinations
    # Only select columns that actually exist
    available_roster_cols <- names(rosters)
    desired_cols <- c("gsis_id", "season", "pfr_id", "full_name", "position", "team", "height", "weight", "birth_date", "entry_year", "draft_number")
    cols_to_select <- intersect(desired_cols, available_roster_cols)
    
    cat("🔍 Desired columns:", paste(desired_cols, collapse = ", "), "\n")
    cat("🔍 Columns to select from rosters:", paste(cols_to_select, collapse = ", "), "\n")
    
    if (length(cols_to_select) == 0) {
      cat("❌ ERROR: No desired columns found in rosters dataset!\n")
      return(master_data)
    }
    
    # Step 1: Select available columns
    cat("-> Selecting columns...\n")
    rosters_selected <- rosters %>% select(all_of(cols_to_select))
    cat(sprintf("✅ Selected %d columns, %d rows\n", ncol(rosters_selected), nrow(rosters_selected)))
    cat("✅ Selected columns:", paste(names(rosters_selected), collapse = ", "), "\n")
    
    # Step 2: Rename gsis_id to player_id
    if ("gsis_id" %in% names(rosters_selected)) {
      cat("-> Renaming gsis_id to player_id...\n")
      rosters_renamed <- rosters_selected %>% rename(player_id = gsis_id)
      cat("✅ Renamed successfully. New columns:", paste(names(rosters_renamed), collapse = ", "), "\n")
    } else {
      cat("❌ ERROR: gsis_id not found in selected columns!\n")
      return(master_data)
    }
    
    # Step 3: Remove duplicates
    if ("player_id" %in% names(rosters_renamed) && "season" %in% names(rosters_renamed)) {
      cat("-> Removing duplicates by player_id and season...\n")
      rosters_clean <- rosters_renamed %>% distinct(player_id, season, .keep_all = TRUE)
      cat(sprintf("✅ Removed duplicates: %d rows remaining\n", nrow(rosters_clean)))
    } else {
      cat("❌ ERROR: Required columns for deduplication not found!\n")
      cat("Available columns after rename:", paste(names(rosters_renamed), collapse = ", "), "\n")
      return(master_data)
    }
    
    # Step 4: Perform the join
    cat("-> Attempting join...\n")
    cat("Master data columns before join:", paste(names(master_data), collapse = ", "), "\n")
    cat("Rosters clean columns before join:", paste(names(rosters_clean), collapse = ", "), "\n")
    
    master_data <- safe_join(master_data, rosters_clean, c("player_id", "season"))
    cat(sprintf("✅ After roster join: %d rows\n", nrow(master_data)))
    
  }, error = function(e) {
    cat("❌ ERROR in roster join:", e$message, "\n")
    cat("📊 Debug info:\n")
    cat("- Original roster columns:", paste(names(rosters), collapse = ", "), "\n")
    cat("- Desired columns:", paste(desired_cols, collapse = ", "), "\n")
    if (exists("cols_to_select")) {
      cat("- Columns to select:", paste(cols_to_select, collapse = ", "), "\n")
    }
    if (exists("rosters_selected")) {
      cat("- After selection:", paste(names(rosters_selected), collapse = ", "), "\n")
    }
    if (exists("rosters_renamed")) {
      cat("- After rename:", paste(names(rosters_renamed), collapse = ", "), "\n")
    }
    cat("Full error:\n")
    print(e)
  })
}

# JOIN 2: Add snap count information
if (!is.null(snap_counts) && "pfr_id" %in% names(master_data)) {
  cat("\n-> Step 2: Joining with snap counts...\n")
  
  # Check what join key is available in snap_counts
  # From your output, it looks like snap_counts has "player" as the key
  if ("player" %in% names(snap_counts)) {
    # Aggregate snap counts by player and season
    snaps_agg <- snap_counts %>%
      group_by(player, season) %>%
      summarise(
        total_offense_snaps = sum(offense_snaps, na.rm = TRUE),
        avg_offense_pct = mean(offense_pct, na.rm = TRUE),
        total_defense_snaps = sum(defense_snaps, na.rm = TRUE),
        avg_defense_pct = mean(defense_pct, na.rm = TRUE),
        total_st_snaps = sum(st_snaps, na.rm = TRUE),
        avg_st_pct = mean(st_pct, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      # Only keep records with actual snap data
      filter(!is.na(player) & (total_offense_snaps > 0 | total_defense_snaps > 0 | total_st_snaps > 0))
    
    if (nrow(snaps_agg) > 0) {
      # Try to join using player_display_name (most likely match)
      if ("player_display_name" %in% names(master_data)) {
        snaps_agg <- snaps_agg %>% rename(player_display_name = player)
        master_data <- safe_join(master_data, snaps_agg, c("player_display_name", "season"))
        cat(sprintf("   After snap counts join: %d rows\n", nrow(master_data)))
      } else {
        cat("   - ⚠️ Cannot join snap counts - no matching player identifier\n")
      }
    } else {
      cat("   - ⚠️ No valid snap count data to join\n")
    }
  } else {
    cat("   - ⚠️ Snap counts missing expected 'player' column\n")
  }
} else {
  cat("\n-> Step 2: Skipping snap counts join (requirements not met)\n")
}

# JOIN 3: Add combine information
if (!is.null(combine) && "full_name" %in% names(master_data)) {
  cat("\n-> Step 3: Joining with combine data...\n")
  
  # Prepare combine data - use player_name as join key
  combine_clean <- combine %>%
    # Select relevant combine metrics
    select(player_name, pos, forty, vertical, broad_jump, cone, shuttle) %>%
    # Remove duplicates (some players may have multiple combine records)
    group_by(player_name) %>%
    summarise(
      combine_position = first(pos),
      forty_time = first(forty[!is.na(forty)]),
      vertical_jump = first(vertical[!is.na(vertical)]),
      broad_jump_inches = first(broad_jump[!is.na(broad_jump)]),
      cone_drill = first(cone[!is.na(cone)]),
      shuttle_time = first(shuttle[!is.na(shuttle)]),
      .groups = 'drop'
    ) %>%
    # Rename player_name to match full_name from rosters
    rename(full_name = player_name)
  
  if (nrow(combine_clean) > 0) {
    master_data <- safe_join(master_data, combine_clean, "full_name")
    cat(sprintf("   After combine join: %d rows\n", nrow(master_data)))
  } else {
    cat("   - ⚠️ No valid combine data to join\n")
  }
} else {
  cat("\n-> Step 3: Skipping combine join (full_name not available or combine data missing)\n")
}

# 5. FINAL DATA CLEANUP
# ----------------------------------------------------------------------
cat("\n-> Final data cleanup...\n")

# Rename columns for consistency
final_data <- master_data %>%
  # Standardize column names
  rename_with(~"player_name", .cols = any_of(c("full_name"))) %>%
  rename_with(~"recent_team", .cols = any_of(c("team"))) %>%
  # Keep only players with meaningful activity
  filter(
    !is.na(games) & games > 0 |  # Has game appearances, OR
    (!is.na(total_offense_snaps) & total_offense_snaps > 0) |  # Has offensive snaps, OR
    (!is.na(total_defense_snaps) & total_defense_snaps > 0) |  # Has defensive snaps, OR
    (!is.na(fantasy_points) & fantasy_points > 0)  # Has fantasy points
  ) %>%
  # Sort by season and fantasy points for consistency
  arrange(desc(season), desc(fantasy_points_ppr))

cat(sprintf("   Final dataset: %d rows, %d columns\n", nrow(final_data), ncol(final_data)))

# Print column summary for debugging
cat("\n📋 Final dataset columns:\n")
cat(paste(names(final_data), collapse = ", "), "\n")

# 6. FINAL EXPORT
# ----------------------------------------------------------------------
export_to_json_safe(final_data, "player_stats.json")

cat("\n\n✅ R script finished successfully.\n")
cat("You can now use the 'upload_player_stats.js' script to upload 'player_stats.json' to Firestore.\n")