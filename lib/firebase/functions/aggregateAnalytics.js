// firebase/functions/aggregateAnalytics.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.dailyAnalyticsAggregation = functions.pubsub
    .schedule('0 2 * * *')  // Run at 2 AM every day
    .timeZone('America/New_York')
    .onRun(async (context) => {
        const db = admin.firestore();
        
        try {
            console.log('Starting daily analytics aggregation...');
            
            // Get all draft analytics documents
            const analyticsSnapshot = await db.collection('draftAnalytics').get();
            console.log(`Processing ${analyticsSnapshot.size} draft analytics documents`);
            
            if (analyticsSnapshot.empty) {
                console.log('No analytics data to process');
                return null;
            }
            
            // Process position distribution
            const positionDistribution = await aggregatePositionDistribution(analyticsSnapshot);
            
            // Process team needs
            const teamNeeds = await aggregateTeamNeeds(analyticsSnapshot);
            
            // Process positions by pick
            const positionsByPick = await aggregatePositionsByPick(analyticsSnapshot);
            
            // Process players by pick
            const playersByPick = await aggregatePlayersByPick(analyticsSnapshot);
            
            // Process player deviations
            const playerDeviations = await aggregatePlayerDeviations(analyticsSnapshot);
            
            // Update metadata
            await db.collection('precomputedAnalytics').doc('metadata').set({
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                documentsProcessed: analyticsSnapshot.size,
            });
            
            console.log('Daily analytics aggregation completed successfully');
            return null;
        } catch (error) {
            console.error('Error in daily analytics aggregation:', error);
            return null;
        }
    });

// Helper functions for aggregation
async function aggregatePositionDistribution(analyticsSnapshot) {
    const db = admin.firestore();
    
    // Overall position counts
    const positionCounts = {};
    let totalPicks = 0;
    
    // Team-specific position counts
    const teamPositionCounts = {};
    
    analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        const picks = data.picks || [];
        
        picks.forEach((pick) => {
            const position = pick.position;
            const team = pick.actualTeam;
            
            // Overall counts
            positionCounts[position] = (positionCounts[position] || 0) + 1;
            // firebase/functions/aggregateAnalytics.js (continued)

            totalPicks++;
            
            // Team-specific counts
            if (!teamPositionCounts[team]) {
                teamPositionCounts[team] = {};
            }
            teamPositionCounts[team][position] = (teamPositionCounts[team][position] || 0) + 1;
        });
    });
    
    // Format overall position distribution
    const overallDistribution = {
        total: totalPicks,
        positions: {}
    };
    
    for (const [position, count] of Object.entries(positionCounts)) {
        overallDistribution.positions[position] = {
            count: count,
            percentage: `${((count / totalPicks) * 100).toFixed(1)}%`
        };
    }
    
    // Format team-specific position distributions
    const teamDistributions = {};
    
    for (const [team, positions] of Object.entries(teamPositionCounts)) {
        const teamTotal = Object.values(positions).reduce((sum, count) => sum + count, 0);
        
        teamDistributions[team] = {
            total: teamTotal,
            positions: {}
        };
        
        for (const [position, count] of Object.entries(positions)) {
            teamDistributions[team].positions[position] = {
                count: count,
                percentage: `${((count / teamTotal) * 100).toFixed(1)}%`
            };
        }
    }
    
    // Store in Firestore
    await db.collection('precomputedAnalytics').doc('positionDistribution').set({
        overall: overallDistribution,
        byTeam: teamDistributions,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Position distribution aggregation completed');
    return overallDistribution;
}

async function aggregateTeamNeeds(analyticsSnapshot) {
    const db = admin.firestore();
    
    // Track teams and their early round position selections
    const teamPositionCounts = {};
    const teamDraftCounts = {};
    
    analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        const picks = data.picks || [];
        
        picks.forEach((pick) => {
            const round = parseInt(pick.round) || 0;
            
            // Only consider early rounds (1-3)
            if (round > 3) return;
            
            const position = pick.position;
            const team = pick.actualTeam;
            
            // Initialize data structures if needed
            if (!teamPositionCounts[team]) {
                teamPositionCounts[team] = {};
            }
            if (!teamDraftCounts[team]) {
                teamDraftCounts[team] = 0;
            }
            
            // Apply round weighting: Round 1 = 3x, Round 2 = 2x, Round 3 = 1x
            const roundWeight = 4 - round; // 3, 2, 1 for rounds 1, 2, 3
            
            // Count position for this team with round weighting
            teamPositionCounts[team][position] = (teamPositionCounts[team][position] || 0) + roundWeight;
            
            // Increment total count for this team
            teamDraftCounts[team] = (teamDraftCounts[team] || 0) + 1;
        });
    });
    
    // Convert to consensus needs (top positions for each team)
    const teamNeeds = {};
    
    for (const [team, positionCounts] of Object.entries(teamPositionCounts)) {
        // Convert position counts to sorted list
        const positions = Object.entries(positionCounts)
            .sort((a, b) => b[1] - a[1])
            .map(entry => entry[0]);
        
        // Take top 5 positions as team needs
        teamNeeds[team] = positions.slice(0, 5);
    }
    
    // Store in Firestore
    await db.collection('precomputedAnalytics').doc('teamNeeds').set({
        needs: teamNeeds,
        year: new Date().getFullYear(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Team needs aggregation completed');
    return { needs: teamNeeds };
}

async function aggregatePositionsByPick(analyticsSnapshot) {
    const db = admin.firestore();
    
    // Store positions by pick for all rounds together and for each round
    const results = {
        all: aggregatePositionPickData(analyticsSnapshot),
        byRound: {}
    };
    
    // Separate rounds 1-7
    for (let round = 1; round <= 7; round++) {
        results.byRound[round] = aggregatePositionPickData(analyticsSnapshot, round);
    }
    
    // Store overall positions by pick
    await db.collection('precomputedAnalytics').doc('positionsByPick').set({
        data: results.all,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Store round-specific positions by pick
    for (let round = 1; round <= 7; round++) {
        await db.collection('precomputedAnalytics').doc(`positionsByPickRound${round}`).set({
            data: results.byRound[round],
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    
    console.log('Positions by pick aggregation completed');
    return results;
}

function aggregatePositionPickData(analyticsSnapshot, specificRound = null) {
    // Map of pick number to position counts
    const pickPositionCounts = {};
    const pickTotals = {};
    const pickRounds = {};
    
    analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        const picks = data.picks || [];
        
        picks.forEach((pick) => {
            const round = parseInt(pick.round) || 0;
            
            // Filter by round if specified
            if (specificRound !== null && round !== specificRound) {
                return;
            }
            
            const pickNumber = pick.pickNumber;
            const position = pick.position;
            
            // Initialize data structures if needed
            if (!pickPositionCounts[pickNumber]) {
                pickPositionCounts[pickNumber] = {};
            }
            if (!pickTotals[pickNumber]) {
                pickTotals[pickNumber] = 0;
            }
            
            // Count position for this pick
            pickPositionCounts[pickNumber][position] = (pickPositionCounts[pickNumber][position] || 0) + 1;
            
            // Increment total count for this pick
            pickTotals[pickNumber] = (pickTotals[pickNumber] || 0) + 1;
            
            // Store round for this pick
            pickRounds[pickNumber] = pick.round;
        });
    });
    
    // Convert to final format with percentage calculations
    const result = [];
    
    for (const [pickNumber, positionCounts] of Object.entries(pickPositionCounts)) {
        const totalForPick = pickTotals[pickNumber] || 0;
        
        if (totalForPick === 0) continue;
        
        // Convert position counts to sorted list with percentages
        const positions = Object.entries(positionCounts)
            .map(([position, count]) => ({
                position,
                count,
                percentage: `${((count / totalForPick) * 100).toFixed(1)}%`
            }))
            .sort((a, b) => b.count - a.count);
        
        result.push({
            pick: parseInt(pickNumber),
            round: pickRounds[pickNumber] || '?',
            positions,
            totalDrafts: totalForPick
        });
    }
    
    // Sort by pick number
    result.sort((a, b) => a.pick - b.pick);
    
    return result;
}

async function aggregatePlayersByPick(analyticsSnapshot) {
    const db = admin.firestore();
    
    // Store players by pick for all rounds together and for each round
    const results = {
        all: aggregatePlayerPickData(analyticsSnapshot),
        byRound: {}
    };
    
    // Separate rounds 1-7
    for (let round = 1; round <= 7; round++) {
        results.byRound[round] = aggregatePlayerPickData(analyticsSnapshot, round);
    }
    
    // Store overall players by pick
    await db.collection('precomputedAnalytics').doc('playersByPick').set({
        data: results.all,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Store round-specific players by pick
    for (let round = 1; round <= 7; round++) {
        await db.collection('precomputedAnalytics').doc(`playersByPickRound${round}`).set({
            data: results.byRound[round],
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
    }
    
    console.log('Players by pick aggregation completed');
    return results;
}

function aggregatePlayerPickData(analyticsSnapshot, specificRound = null) {
    // Map of pick number to player counts
    const pickPlayerCounts = {};
    const pickTotals = {};
    
    analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        const picks = data.picks || [];
        
        picks.forEach((pick) => {
            const round = parseInt(pick.round) || 0;
            
            // Filter by round if specified
            if (specificRound !== null && round !== specificRound) {
                return;
            }
            
            const pickNumber = pick.pickNumber;
            const playerName = pick.playerName;
            const position = pick.position;
            const school = pick.school;
            const playerRank = pick.playerRank;
            
            // Initialize data structures if needed
            if (!pickPlayerCounts[pickNumber]) {
                pickPlayerCounts[pickNumber] = {};
            }
            if (!pickTotals[pickNumber]) {
                pickTotals[pickNumber] = 0;
            }
            
            // Create a unique key for player+position
            const playerKey = `${playerName}|${position}`;
            
            // Create or update player entry
            if (!pickPlayerCounts[pickNumber][playerKey]) {
                pickPlayerCounts[pickNumber][playerKey] = {
                    player: playerName,
                    position,
                    school,
                    rank: playerRank,
                    count: 0
                };
            }
            
            // Increment count for this player
            pickPlayerCounts[pickNumber][playerKey].count += 1;
            
            // Increment total count for this pick
            pickTotals[pickNumber] = (pickTotals[pickNumber] || 0) + 1;
        });
    });
    
    // Convert to final format with top 3 players per pick
    const result = [];
    
    for (const [pickNumber, playerCounts] of Object.entries(pickPlayerCounts)) {
        const totalForPick = pickTotals[pickNumber] || 0;
        
        if (totalForPick === 0) continue;
        
        // Convert player counts to list with percentages
        const players = Object.values(playerCounts)
            .map(data => ({
                player: data.player,
                position: data.position,
                school: data.school,
                rank: data.rank,
                count: data.count,
                percentage: `${((data.count / totalForPick) * 100).toFixed(1)}%`
            }))
            .sort((a, b) => b.count - a.count);
        
        // Take top 3 players (or all if less than 3)
        const topPlayers = players.slice(0, 3);
        
        result.push({
            pick: parseInt(pickNumber),
            players: topPlayers,
            totalDrafts: totalForPick
        });
    }
    
    // Sort by pick number
    result.sort((a, b) => a.pick - b.pick);
    
    return result;
}

async function aggregatePlayerDeviations(analyticsSnapshot) {
    const db = admin.firestore();
    
    // Calculate rank deviations
    const playerDeviations = {};
    
    analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        const picks = data.picks || [];
        
        picks.forEach((pick) => {
            // Calculate the deviation (positive means picked later than rank)
            const deviation = pick.pickNumber - pick.playerRank;
            
            // Use player name and position as key
            const key = `${pick.playerName}|${pick.position}`;
            
            if (!playerDeviations[key]) {
                playerDeviations[key] = {
                    name: pick.playerName,
                    position: pick.position,
                    deviations: [],
                    school: pick.school
                };
            }
            
            playerDeviations[key].deviations.push(deviation);
        });
    });
    
    // Calculate average deviations
    const averageDeviations = [];
    const byPosition = {};
    
    for (const [key, data] of Object.entries(playerDeviations)) {
        // Skip players with less than 3 data points
        if (data.deviations.length < 3) continue;
        
        const sum = data.deviations.reduce((a, b) => a + b, 0);
        const average = sum / data.deviations.length;
        
        const playerData = {
            name: data.name,
            position: data.position,
            avgDeviation: average.toFixed(1),
            sampleSize: data.deviations.length,
            school: data.school
        };
        
        averageDeviations.push(playerData);
        
        // Group by position
        if (!byPosition[data.position]) {
            byPosition[data.position] = [];
        }
        byPosition[data.position].push(playerData);
    }
    
    // Sort by absolute deviation value (largest first)
    averageDeviations.sort((a, b) => 
        Math.abs(parseFloat(b.avgDeviation)) - Math.abs(parseFloat(a.avgDeviation))
    );
    
    // Sort position-specific lists
    for (const position in byPosition) {
        byPosition[position].sort((a, b) => 
            Math.abs(parseFloat(b.avgDeviation)) - Math.abs(parseFloat(a.avgDeviation))
        );
    }
    
    // Store in Firestore
    await db.collection('precomputedAnalytics').doc('playerDeviations').set({
        players: averageDeviations,
        byPosition,
        sampleSize: analyticsSnapshot.size,
        positionSampleSizes: Object.fromEntries(
            Object.entries(byPosition).map(([pos, data]) => [pos, data.length])
        ),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Player deviations aggregation completed');
    return { players: averageDeviations, byPosition };
}