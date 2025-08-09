# data_processing/generate_cap_space_csv.R
# Generate team cap space data for trade analyzer

# Load libraries
library(rvest)
library(tidyverse)

cat("💰 NFL Team Cap Space Generator\n")
cat("Scraping team cap space data from overthecap.com...\n")

# Scrape cap space data from overthecap.com
url <- paste0("https://overthecap.com/salary-cap-space#google_vignette")
player_stat <- read_html(url)

# Extract team names and remaining cap space
Team <- player_stat %>%
  html_nodes(".salary-cap-space-table .sortable .sortable:nth-child(1)") %>%
  html_text() %>% 
  head(32)

Remaining_cap <- player_stat %>%
  html_nodes(".salary-cap-space-table .sortable .sortable:nth-child(2)") %>%
  html_text() %>% 
  head(32)

# Create initial dataframe
initial_data <- tibble(
  team = Team,
  remaining_cap = Remaining_cap
)

cat("Initial data loaded:", nrow(initial_data), "teams\n")
cat("Checking for any data issues...\n")

# Debug: Check for problematic entries
problematic_entries <- initial_data %>%
  mutate(
    team_clean = str_trim(team),
    cap_clean = str_remove_all(remaining_cap, "\\$|,"),
    cap_numeric = as.numeric(cap_clean)
  ) %>%
  filter(is.na(cap_numeric) | team_clean == "" | is.na(team_clean))

if (nrow(problematic_entries) > 0) {
  cat("Found problematic entries:\n")
  print(problematic_entries)
}

# Create cap space dataframe with better error handling
cap_space_data <- tibble(
  team = Team,
  remaining_cap = Remaining_cap
) %>%
  # Clean and format the data
  mutate(
    # Clean team names (remove extra whitespace)
    team = str_trim(team),
    # Clean cap space values (remove $ and convert to numeric)
    remaining_cap_clean = str_remove_all(remaining_cap, "\\$|,"),
    # More robust numeric conversion - handle negative values and special cases
    remaining_cap_clean = str_remove_all(remaining_cap_clean, "[^0-9.-]"),
    remaining_cap_numeric = as.numeric(remaining_cap_clean),
    # Keep original string format for display
    remaining_cap_display = remaining_cap
  ) %>%
  # Only filter out completely empty rows, but keep teams with cap space issues
  filter(!is.na(team), team != "") %>%
  # Handle missing cap space data
  mutate(
    remaining_cap_numeric = ifelse(is.na(remaining_cap_numeric), 0, remaining_cap_numeric),
    remaining_cap_display = ifelse(is.na(remaining_cap_display) | remaining_cap_display == "", "$0", remaining_cap_display)
  ) %>%
  # Add current season
  mutate(season = 2025) %>%
  # Select final columns
  select(team, remaining_cap_display, remaining_cap_numeric, season) %>%
  rename(
    remaining_cap = remaining_cap_display,
    cap_space_amount = remaining_cap_numeric
  ) %>%
  # Arrange by cap space (highest first)
  arrange(desc(cap_space_amount))

cat("Cap space data processed. Final shape:", nrow(cap_space_data), "rows,", ncol(cap_space_data), "columns\n")

# Data validation and summary
cat("\n=== TEAM CAP SPACE SUMMARY ===\n")
cat("Total teams:", nrow(cap_space_data), "\n")
cat("Season:", unique(cap_space_data$season), "\n")

# Top teams by cap space
cat("\nTop 10 teams by available cap space:\n")
top_cap_space <- cap_space_data %>%
  head(10) %>%
  select(team, remaining_cap, cap_space_amount)
print(top_cap_space)

# Bottom teams by cap space
cat("\nBottom 5 teams by available cap space:\n")
bottom_cap_space <- cap_space_data %>%
  tail(5) %>%
  select(team, remaining_cap, cap_space_amount)
print(bottom_cap_space)

# Create output directory if it doesn't exist
output_dir <- "../assets/cap_space"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Created directory:", output_dir, "\n")
}

# Export to CSV
output_file_csv <- "../assets/cap_space/team_cap_space.csv"

cat("\nExporting team cap space data to", output_file_csv, "...\n")

# Export to CSV without quotes
write.csv(cap_space_data, output_file_csv, row.names = FALSE, quote = FALSE)
cat("✅ CSV export complete! File saved as:", output_file_csv, "\n")

# Sample data preview
cat("\n=== SAMPLE CAP SPACE DATA ===\n")
cat("First few records:\n")
sample_data <- cap_space_data %>%
  head(5) %>%
  select(team, remaining_cap, cap_space_amount, season)
print(sample_data)

cat("\n🎉 Team cap space generation complete!\n")
cat("📊 Total teams exported:", nrow(cap_space_data), "\n")
cat("📁 File location:", output_file_csv, "\n")
cat("🔧 Next step: Integrate cap space data into trade analyzer\n")