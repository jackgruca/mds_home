#!/bin/bash

# Script to update CSV data from R output
# This replaces the Firebase upload process with local CSV updates

echo "🚀 Updating CSV data from R output..."

# Set directories
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DATA_DIR="$SCRIPT_DIR/../assets/data"
R_OUTPUT_DIR="$SCRIPT_DIR/r_output" # Adjust this to where your R scripts output files

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Function to copy and validate CSV file
update_csv() {
    local source_file="$1"
    local dest_file="$2"
    local description="$3"
    
    if [ -f "$source_file" ]; then
        echo "✅ Updating $description..."
        cp "$source_file" "$dest_file"
        
        # Validate CSV has content
        if [ -s "$dest_file" ]; then
            local line_count=$(wc -l < "$dest_file")
            echo "   → Updated with $line_count lines"
        else
            echo "   ⚠️  Warning: File is empty!"
        fi
    else
        echo "❌ Source file not found: $source_file"
        echo "   → Expected $description"
    fi
}

# Update player stats (example - adjust paths as needed)
# update_csv "$R_OUTPUT_DIR/player_stats.csv" "$DATA_DIR/player_stats_2024.csv" "Player Stats 2024"

# If you have the R output file, uncomment and adjust:
# update_csv "./player_stats.json" "$DATA_DIR/player_stats_2024.json" "Player Stats JSON"

# Update metadata
echo "📄 Updating metadata..."
cat > "$DATA_DIR/metadata.json" << EOF
{
  "version": "1.0.0",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
  "dataSource": "R Scripts",
  "updateScript": "update_csv_from_r.sh",
  "collections": [
    {
      "name": "playerSeasonStats",
      "filename": "player_stats_2024.csv",
      "updatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"
    }
  ]
}
EOF

echo "✨ CSV data update complete!"
echo ""
echo "Next steps:"
echo "1. Run your R script to generate new CSV files"
echo "2. Update the paths in this script to point to your R output"
echo "3. Run this script again to copy the updated data"
echo "4. Hot reload your Flutter app to see the changes"