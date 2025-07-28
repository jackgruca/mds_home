#!/usr/bin/env python3
import csv
import json

# Read CSV and convert to JSON
with open('assets/data/sample_game_stats.csv', 'r') as csvfile:
    reader = csv.DictReader(csvfile)
    data = list(reader)

# Filter for positions we want
positions = ['QB', 'RB', 'WR', 'TE']
filtered_data = [row for row in data if row.get('position') in positions]

print(f"Total records: {len(data)}")
print(f"Filtered records: {len(filtered_data)}")
print(f"Positions found: {set(row.get('position', 'Unknown') for row in data)}")

# Save as JSON
with open('assets/data/game_stats_sample.json', 'w') as jsonfile:
    json.dump(filtered_data, jsonfile, indent=2)

print("Converted CSV to JSON successfully!")