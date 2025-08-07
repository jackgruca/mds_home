# data_processing/generate_contract_data.R
# Generate NFL contract data for trade analyzer

# Load libraries
library(nflreadr)
library(tidyverse)
library(jsonlite)

cat("🏈 NFL Trade Analyzer - Contract Data Generator\n")
cat("Loading contract data from nflreadr...\n")

# Load contract data
contracts_raw <- load_contracts()

cat("Raw contract data loaded. Shape:", nrow(contracts_raw), "rows,", ncol(contracts_raw), "columns\n")

# Check available columns
cat("Available columns:\n")
print(names(contracts_raw))

# Clean and process contract data for trade analyzer
contracts_cleaned <- contracts_raw %>%
  # Remove rows with missing essential data
  filter(!is.na(player), !is.na(team), !is.na(apy)) %>%
  
  # Clean up text fields
  mutate(
    player = str_trim(player),
    team = str_trim(team),
    position = str_trim(position)
  ) %>%
  
  # Convert fields to appropriate types
  mutate(
    value = as.numeric(value),
    guaranteed = as.numeric(guaranteed),
    apy = as.numeric(apy),
    years = as.integer(years),
# years_left column might not exist, will calculate from years + year_signed
    year_signed = as.integer(year_signed),
    apy_cap_pct = as.numeric(apy_cap_pct)
  ) %>%
  
  # Add computed fields for trade analyzer
  mutate(
    # Standardize positions to match our trade analyzer positions
    position_standardized = case_when(
      position %in% c("QB") ~ "QB",
      position %in% c("RB", "FB") ~ "RB",
      position %in% c("WR") ~ "WR", 
      position %in% c("TE") ~ "TE",
      position %in% c("T", "OT") ~ "OT",
      position %in% c("G", "OG") ~ "OG",
      position %in% c("C") ~ "C",
      position %in% c("DE") ~ "DE",
      position %in% c("DT", "NT") ~ "DT",
      position %in% c("OLB", "EDGE") ~ "EDGE",
      position %in% c("ILB", "LB", "MLB") ~ "LB",
      position %in% c("CB") ~ "CB",
      position %in% c("S", "FS", "SS") ~ "S",
      position %in% c("K") ~ "K",
      position %in% c("P") ~ "P",
      position %in% c("LS") ~ "LS",
      TRUE ~ position # Keep original if not matched
    ),
    
    # Calculate years remaining (estimate based on current year 2025)
    years_remaining = pmax(0, (year_signed + years) - 2025),
    
    # Calculate contract tier based on APY for position
    contract_tier = case_when(
      apy >= 40 ~ "elite",
      apy >= 25 ~ "high",
      apy >= 15 ~ "mid", 
      apy >= 8 ~ "low",
      TRUE ~ "rookie"
    ),
    
    # Flag players with expiring contracts (important for trade value)
    expiring_contract = ifelse(years_remaining <= 1, TRUE, FALSE),
    
    # Calculate cap efficiency (AAV as % of cap)
    cap_efficiency = case_when(
      apy_cap_pct <= 5 ~ "excellent",
      apy_cap_pct <= 10 ~ "good",
      apy_cap_pct <= 15 ~ "average",
      apy_cap_pct <= 20 ~ "expensive",
      TRUE ~ "elite_price"
    ),
    
    # Create unique contract ID for joining with roster data
    contract_id = paste(
      str_replace_all(player, " ", "_"),
      team,
      sep = "_"
    )
  )

# Select columns optimized for trade analyzer
contract_columns <- c(
  "contract_id", "player", "team", "position_standardized", 
  "value", "guaranteed", "apy", "years", "years_remaining", "year_signed",
  "apy_cap_pct", "contract_tier", "expiring_contract", "cap_efficiency",
  "player_id", "otc_id"
)

# Filter to only include columns that exist
existing_contract_columns <- intersect(contract_columns, names(contracts_cleaned))
contracts_final <- contracts_cleaned %>%
  select(all_of(existing_contract_columns)) %>%
  # Rename for consistency with trade analyzer
  rename(
    contractId = contract_id,
    name = player,
    position = position_standardized,
    totalValue = value,
    guaranteedMoney = guaranteed,
    averageAnnualValue = apy,
    contractYears = years,
    yearsRemaining = years_remaining,
    yearSigned = year_signed,
    capPercentage = apy_cap_pct,
    tier = contract_tier,
    isExpiring = expiring_contract,
    efficiency = cap_efficiency
  )

# Handle missing values
contracts_final <- contracts_final %>%
  mutate(across(where(is.character), ~ifelse(is.na(.), "", .))) %>%
  mutate(across(where(is.numeric), ~ifelse(is.na(.), 0, .))) %>%
  mutate(across(where(is.logical), ~ifelse(is.na(.), FALSE, .)))

cat("Contract data processed. Final shape:", nrow(contracts_final), "rows,", ncol(contracts_final), "columns\n")

# Data validation and summary
cat("\n=== CONTRACT DATA SUMMARY ===\n")
cat("Total contracts:", nrow(contracts_final), "\n")
cat("Teams:", length(unique(contracts_final$team)), "\n")
cat("Unique players:", length(unique(contracts_final$contractId)), "\n")

# Position breakdown
cat("\nPosition breakdown:\n")
position_summary <- contracts_final %>%
  count(position, sort = TRUE)
print(position_summary)

# Contract value distribution
cat("\nContract value distribution (AAV):\n")
value_summary <- contracts_final %>%
  summarise(
    min_aav = min(averageAnnualValue),
    q25_aav = quantile(averageAnnualValue, 0.25),
    median_aav = median(averageAnnualValue),
    q75_aav = quantile(averageAnnualValue, 0.75),
    max_aav = max(averageAnnualValue),
    mean_aav = round(mean(averageAnnualValue), 1)
  )
print(value_summary)

# Top contracts by position
cat("\nTop contracts by major positions:\n")
top_contracts <- contracts_final %>%
  filter(position %in% c("QB", "RB", "WR", "TE", "EDGE", "OT")) %>%
  group_by(position) %>%
  slice_max(averageAnnualValue, n = 3) %>%
  select(name, position, team, averageAnnualValue, tier) %>%
  arrange(position, desc(averageAnnualValue))
print(top_contracts)

# Export to CSV
output_file_csv <- "../assets/nfl_contract_data.csv"

cat("\nExporting contract data to", output_file_csv, "...\n")

# Export to CSV
write.csv(contracts_final, output_file_csv, row.names = FALSE)
cat("✅ CSV export complete! File saved as:", output_file_csv, "\n")

# Sample data preview
cat("\n=== SAMPLE CONTRACT DATA ===\n")
cat("First few records:\n")
sample_contracts <- contracts_final %>%
  head(5) %>%
  select(contractId, name, position, team, averageAnnualValue, yearsRemaining, tier)
print(sample_contracts)

cat("\n🎉 Contract data generation complete!\n")
cat("📊 Total contracts exported:", nrow(contracts_final), "NFL contracts\n")
cat("📁 File location: assets/nfl_contract_data.csv\n")
cat("🔧 Next step: Integrate contract data with trade analyzer\n")