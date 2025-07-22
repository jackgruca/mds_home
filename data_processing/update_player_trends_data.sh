#!/bin/bash

# Update Player Trends Data - Multi-Year Support
# This script fetches and uploads player game logs for the past 5 years

echo "🚀 Starting Player Trends Data Update (2020-2024)"
echo "================================================="

# Step 1: Fetch multi-year player game logs
echo "📊 Step 1: Fetching player game logs for 2020-2024..."
Rscript get_player_game_logs.R

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to fetch player game logs"
    exit 1
fi

echo "✅ Player game logs fetched successfully"

# Step 2: Upload to Firestore
echo "📤 Step 2: Uploading player game logs to Firestore..."
node upload_player_game_logs.js

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to upload player game logs"
    exit 1
fi

echo "✅ Player game logs uploaded successfully"

echo ""
echo "🎉 Player Trends Data Update Complete!"
echo "✨ The Player Trends screen now has access to data from 2020-2024"
echo "📱 Users can now select different years in the dropdown"
echo "=================================================" 