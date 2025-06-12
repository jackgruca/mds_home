// firebase/functions/analyticsAggregation.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Helper function to parse query values (numbers, booleans)
function parseQueryValue(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'string') {
    if (value.toLowerCase() === 'true') return true;
    if (value.toLowerCase() === 'false') return false;
    if (!isNaN(value) && value.trim() !== '' && value.indexOf('.') !== -1) {
        const num = parseFloat(value);
        if (!isNaN(num)) return num;
    } else if (!isNaN(value) && value.trim() !== '') {
        const num = parseInt(value, 10);
        if (!isNaN(num)) return num;
    }
  }
  return value; // Return as string if not obviously a number or boolean
}

exports.dailyAnalyticsAggregation = functions.runWith({
    timeoutSeconds: 300,  // Increase timeout to 5 minutes
    memory: '1GB'         // Increase memory allocation
})
.pubsub
.schedule('0 2 * * *')  // Run at 2 AM every day
.timeZone('America/New_York')
.onRun(async (context) => {
    const db = admin.firestore();
    
    try {
        console.log('Starting daily analytics aggregation...');
        
        // Process draft analytics in smaller batches to avoid timeout
        const batchSize = 50;
        let lastDoc = null;
        let processedCount = 0;
        let allAnalytics = [];
        
        // Update status to show we're starting
        await db.collection('precomputedAnalytics').doc('metadata').set({
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            inProgress: true,
            documentsProcessed: 0,
        }, {merge: true});
        
        // Process documents in batches to avoid connection timeout
        while (true) {
            let query = db.collection('draftAnalytics').limit(batchSize);
            if (lastDoc) {
                query = query.startAfter(lastDoc);
            }
            
            console.log(`Fetching batch of draft analytics (limit: ${batchSize})...`);
            const analyticsSnapshot = await query.get();
            
            if (analyticsSnapshot.empty) {
                console.log('No more documents to process');
                break;
            }
            
            // Collect documents from this batch
            analyticsSnapshot.forEach(doc => {
                allAnalytics.push(doc);
            });
            
            processedCount += analyticsSnapshot.size;
            console.log(`Processed ${processedCount} documents so far`);
            
            // Update the last document for pagination
            lastDoc = analyticsSnapshot.docs[analyticsSnapshot.docs.length - 1];
            
            // Update progress
            await db.collection('precomputedAnalytics').doc('metadata').set({
                documentsProcessed: processedCount,
                inProgress: true,
            }, {merge: true});
        }
        
        console.log(`Processing ${allAnalytics.length} total draft analytics documents`);
        
        // Skip further processing if no documents found
        if (allAnalytics.length === 0) {
            console.log('No analytics data to process');
            await db.collection('precomputedAnalytics').doc('metadata').set({
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                documentsProcessed: 0,
                inProgress: false,
            }, {merge: true});
            return null;
        }
        
        // Run all aggregations in parallel but with smaller batches
        const aggregationPromises = [
            aggregatePositionDistribution(allAnalytics),
            aggregateTeamNeeds(allAnalytics),
            aggregatePositionsByPick(allAnalytics),
            aggregatePlayersByPick(allAnalytics),
            aggregatePlayerDeviations(allAnalytics),
            // Add any other aggregation functions
            aggregateTeamPerformanceMetrics(allAnalytics),
            aggregatePickCorrelations(allAnalytics),
            aggregateHistoricalTrends(allAnalytics)
        ];
        
        // Wait for all aggregations to complete
        await Promise.all(aggregationPromises);
        
        // Update metadata with final stats
        await db.collection('precomputedAnalytics').doc('metadata').set({
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            documentsProcessed: processedCount,
            inProgress: false,
        }, {merge: true});
        
        console.log('Daily analytics aggregation completed successfully');
        return null;
    } catch (error) {
        console.error('Error in daily analytics aggregation:', error);
        
        // Update metadata to show the error
        await db.collection('precomputedAnalytics').doc('metadata').set({
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            error: error.toString(),
            inProgress: false,
        }, {merge: true});
        
        return null;
    }
});
    // Add this to analyticsAggregation.js

// Cached version that will be updated when the aggregation runs
let cachedAnalytics = null;
let cacheTimestamp = null;
const CACHE_EXPIRY_MS = 24 * 60 * 60 * 1000; // 24 hours

// Function to load data into cache
async function loadAnalyticsCache() {
    const db = admin.firestore();
    
    try {
        console.log('Loading analytics data into cache...');
        
        // Get metadata to check last update time
        const metadataDoc = await db.collection('precomputedAnalytics').doc('metadata').get();
        
        if (!metadataDoc.exists) {
            console.log('No metadata document found');
            return false;
        }
        
        const metadata = metadataDoc.data();
        
        // Check if we already have fresh cached data
        if (cachedAnalytics && cacheTimestamp && 
            metadata.lastUpdated && 
            cacheTimestamp.toMillis() >= metadata.lastUpdated.toMillis()) {
            console.log('Cache is already up-to-date');
            return true;
        }
        
        // Load all precomputed analytics documents
        const docs = await db.collection('precomputedAnalytics').get();
        
        const analyticsData = {};
        
        docs.forEach(doc => {
            analyticsData[doc.id] = doc.data();
        });
        
        // Update the cache
        cachedAnalytics = analyticsData;
        cacheTimestamp = metadata.lastUpdated;
        
        console.log('Analytics cache updated successfully');
        return true;
    } catch (error) {
        console.error('Error loading analytics cache:', error);
        return false;
    }
}

// API endpoint to get analytics data
exports.getAnalyticsData = functions.https.onCall(async (data, context) => {
    try {
        // Check if cache is still valid
        const now = new Date();
        const cacheExpired = !cacheTimestamp || 
            (now.getTime() - cacheTimestamp.toMillis()) > CACHE_EXPIRY_MS;
            
        // Load/refresh cache if needed
        if (!cachedAnalytics || cacheExpired) {
            const success = await loadAnalyticsCache();
            
            if (!success) {
                return { 
                    error: 'Failed to load analytics data',
                    cacheStatus: 'error'
                };
            }
        }
        
        // Get requested data type
        const { dataType, filters } = data || {};
        
        if (!dataType) {
            return {
                data: null,
                metadata: {
                    lastUpdated: cacheTimestamp,
                    availableTypes: Object.keys(cachedAnalytics)
                },
                cacheStatus: 'valid'
            };
        }
        
        // Return requested data from cache
        if (cachedAnalytics[dataType]) {
            // Apply any filters if specified
            let filteredData = cachedAnalytics[dataType];
            
            if (filters) {
                // Handle common filter cases
                if (dataType === 'teamNeeds' && filters.team) {
                    filteredData = {
                        needs: { [filters.team]: cachedAnalytics[dataType].needs[filters.team] },
                        year: cachedAnalytics[dataType].year
                    };
                }
                // Add more filter handling as needed
            }
            
            return {
                data: filteredData,
                metadata: {
                    lastUpdated: cacheTimestamp,
                    dataType
                },
                cacheStatus: 'valid'
            };
        }
        
        return {
            error: `Data type '${dataType}' not found`,
            availableTypes: Object.keys(cachedAnalytics),
            cacheStatus: 'valid'
        };
    } catch (error) {
        console.error('Error in getAnalyticsData:', error);
        
        return {
            error: 'Server error while retrieving analytics data',
            cacheStatus: 'error'
        };
    }
});

async function aggregateTeamPerformanceMetrics(analyticsSnapshot) {
    const db = admin.firestore();
    
    // Track team-specific metrics
    const teamMetrics = {};
    
    analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        const picks = data.picks || [];
        const trades = data.trades || [];
        
        // Skip documents without picks
        if (picks.length === 0) return;
        
        // Process each team's picks
        const teamPicks = {};
        
        // Group picks by team
        picks.forEach((pick) => {
            const team = pick.actualTeam;
            if (!teamPicks[team]) teamPicks[team] = [];
            teamPicks[team].push(pick);
        });
        
        // Calculate team-specific metrics
        for (const [team, teamPickList] of Object.entries(teamPicks)) {
            if (!teamMetrics[team]) {
                teamMetrics[team] = {
                    drafts: 0,
                    avgPickValue: 0,
                    totalPicks: 0,
                    picksByRound: {},
                    positionDistribution: {},
                    averageRound1Pick: 0,
                    tradeUpFrequency: 0,
                    tradeDownFrequency: 0
                };
            }
            
            // Increment draft count
            teamMetrics[team].drafts++;
            
            // Count positions
            teamPickList.forEach((pick) => {
                const position = pick.position;
                teamMetrics[team].positionDistribution[position] = 
                    (teamMetrics[team].positionDistribution[position] || 0) + 1;
                
                // Track picks by round
                const round = pick.round;
                teamMetrics[team].picksByRound[round] = 
                    (teamMetrics[team].picksByRound[round] || 0) + 1;
                
                // Track round 1 positions
                if (round === "1") {
                    teamMetrics[team].averageRound1Pick += pick.pickNumber;
                }
                
                // Track pick value (difference between pick and rank)
                teamMetrics[team].avgPickValue += (pick.pickNumber - pick.playerRank);
                teamMetrics[team].totalPicks++;
            });
        }
        
        // Process trades
        trades.forEach((trade) => {
            const offering = trade.teamOffering;
            const receiving = trade.teamReceiving;
            
            if (teamMetrics[offering]) {
                teamMetrics[offering].tradeUpFrequency++;
            }
            
            if (teamMetrics[receiving]) {
                teamMetrics[receiving].tradeDownFrequency++;
            }
        });
    });
    
    // Finalize calculations
    for (const [team, metrics] of Object.entries(teamMetrics)) {
        // Calculate averages
        if (metrics.totalPicks > 0) {
            metrics.avgPickValue = metrics.avgPickValue / metrics.totalPicks;
        }
        
        if (metrics.picksByRound["1"] > 0) {
            metrics.averageRound1Pick = metrics.averageRound1Pick / metrics.picksByRound["1"];
        }
        
        // Convert frequencies to percentages
        metrics.tradeUpFrequency = metrics.tradeUpFrequency / metrics.drafts;
        metrics.tradeDownFrequency = metrics.tradeDownFrequency / metrics.drafts;
        
        // Format position distribution as percentages
        const totalPositions = Object.values(metrics.positionDistribution).reduce((a, b) => a + b, 0);
        
        for (const [position, count] of Object.entries(metrics.positionDistribution)) {
            metrics.positionDistribution[position] = {
                count,
                percentage: `${((count / totalPositions) * 100).toFixed(1)}%`
            };
        }
    }
    
    // Store in Firestore
    await db.collection('precomputedAnalytics').doc('teamPerformance').set({
        metrics: teamMetrics,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Team performance metrics aggregation completed');
    return teamMetrics;
}

// Add this function to analyticsAggregation.js

async function aggregatePickCorrelations(analyticsSnapshot) {
    const db = admin.firestore();
    
    // Track correlations between players
    const playerCorrelations = {};
    
    analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        const picks = data.picks || [];
        
        // Skip documents without enough picks
        if (picks.length < 2) return;
        
        // Track all pairs of players in this draft
        for (let i = 0; i < picks.length; i++) {
            const player1 = picks[i];
            
            for (let j = i + 1; j < picks.length; j++) {
                const player2 = picks[j];
                
                // Create keys for both players
                const key1 = `${player1.playerName}|${player1.position}`;
                const key2 = `${player2.playerName}|${player2.position}`;
                
                // Ensure alphabetical order for consistent keys
                const [firstKey, secondKey] = [key1, key2].sort();
                const pairKey = `${firstKey}___${secondKey}`;
                
                if (!playerCorrelations[pairKey]) {
                    playerCorrelations[pairKey] = {
                        player1: {
                            name: firstKey.split('|')[0],
                            position: firstKey.split('|')[1]
                        },
                        player2: {
                            name: secondKey.split('|')[0],
                            position: secondKey.split('|')[1]
                        },
                        count: 0
                    };
                }
                
                playerCorrelations[pairKey].count++;
            }
        }
    });
    
    // Filter for significant correlations (more than 2 occurrences)
    const significantCorrelations = Object.values(playerCorrelations)
        .filter(corr => corr.count > 2)
        .sort((a, b) => b.count - a.count);
    
    // Group by positions
    const positionCorrelations = {};
    
    significantCorrelations.forEach(corr => {
        const posKey = `${corr.player1.position}___${corr.player2.position}`;
        
        if (!positionCorrelations[posKey]) {
            positionCorrelations[posKey] = {
                position1: corr.player1.position,
                position2: corr.player2.position,
                count: 0,
                examples: []
            };
        }
        
        positionCorrelations[posKey].count++;
        
        // Add as example if we don't have many examples yet
        if (positionCorrelations[posKey].examples.length < 5) {
            positionCorrelations[posKey].examples.push({
                player1: corr.player1.name,
                player2: corr.player2.name,
                count: corr.count
            });
        }
    });
    
    // Store in Firestore
    await db.collection('precomputedAnalytics').doc('pickCorrelations').set({
        playerCorrelations: significantCorrelations.slice(0, 100), // Top 100 correlations
        positionCorrelations: Object.values(positionCorrelations)
            .sort((a, b) => b.count - a.count),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Pick correlations aggregation completed');
    return {
        playerCorrelations: significantCorrelations.slice(0, 100),
        positionCorrelations: Object.values(positionCorrelations)
    };
}

// Add this function to analyticsAggregation.js

async function aggregateHistoricalTrends(analyticsSnapshot) {
    const db = admin.firestore();
    
    // Track trends by timestamp
    const trends = {
        positionTrends: {},
        tradeTrends: {
            tradeFrequency: {},
            averageValueDifferential: {}
        },
        top10Players: {}
    };
    
    // Group documents by month
    const documentsByMonth = {};
    
    analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        
        // Skip documents without timestamp or picks
        if (!data.timestamp || !data.picks || data.picks.length === 0) return;
        
        const timestamp = data.timestamp.toDate();
        const monthKey = `${timestamp.getFullYear()}-${(timestamp.getMonth() + 1).toString().padStart(2, '0')}`;
        
        if (!documentsByMonth[monthKey]) {
            documentsByMonth[monthKey] = [];
        }
        
        documentsByMonth[monthKey].push(data);
    });
    
    // Process data by month
    for (const [month, documents] of Object.entries(documentsByMonth)) {
        // Initialize month trends
        trends.positionTrends[month] = {};
        trends.tradeTrends.tradeFrequency[month] = 0;
        trends.tradeTrends.averageValueDifferential[month] = 0;
        trends.top10Players[month] = {};
        
        // Count all picks in this month
        let totalPicks = 0;
        let totalTrades = 0;
        let totalValueDiff = 0;
        
        // Player frequency counter
        const playerFrequency = {};
        
        documents.forEach(doc => {
            const picks = doc.picks || [];
            const trades = doc.trades || [];
            
            // Count positions
            picks.forEach(pick => {
                const position = pick.position;
                trends.positionTrends[month][position] = 
                    (trends.positionTrends[month][position] || 0) + 1;
                
                totalPicks++;
                
                // Track player frequency
                const playerKey = `${pick.playerName}|${pick.position}`;
                playerFrequency[playerKey] = (playerFrequency[playerKey] || 0) + 1;
            });
            
            // Count trades
            trades.forEach(trade => {
                totalTrades++;
                totalValueDiff += Math.abs(trade.valueOffered - trade.targetValue);
            });
        });
        
        // Calculate trade metrics
        trends.tradeTrends.tradeFrequency[month] = 
            totalTrades / documents.length; // Trades per draft
            
        if (totalTrades > 0) {
            trends.tradeTrends.averageValueDifferential[month] = 
                totalValueDiff / totalTrades;
        }
        
        // Convert position counts to percentages
        for (const [position, count] of Object.entries(trends.positionTrends[month])) {
            trends.positionTrends[month][position] = {
                count,
                percentage: totalPicks > 0 ? (count / totalPicks) * 100 : 0
            };
        }
        
        // Find top 10 players for this month
        const topPlayers = Object.entries(playerFrequency)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 10)
            .map(([key, count]) => {
                const [name, position] = key.split('|');
                return {
                    name,
                    position,
                    count,
                    percentage: totalPicks > 0 ? 
                        `${((count / documents.length) * 100).toFixed(1)}%` : '0%'
                };
            });
            
        trends.top10Players[month] = topPlayers;
    }
    
    // Store in Firestore
    await db.collection('precomputedAnalytics').doc('historicalTrends').set({
        trends,
        months: Object.keys(documentsByMonth).sort(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Historical trends aggregation completed');
    return trends;
}

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

// New function to fetch historical matchups with filtering
exports.getHistoricalMatchups = functions.https.onCall(async (data, context) => {
    const db = admin.firestore();
    console.log('getHistoricalMatchups called with full request data:', JSON.stringify(data, null, 2));

    const filters = data.filters || {};
    const limit = data.limit ? parseInt(data.limit, 10) : 25; // Default limit for pagination
    // FORCING primary orderBy to 'gameID' for unique cursor generation.
    const orderByField = 'gameID'; 
    const orderDirection = data.orderDirection === 'asc' ? 'asc' : 'desc'; // Use client-provided direction for stability
    const cursor = data.cursor; // The cursor for keyset pagination

    let query = db.collection('historicalMatchups');

    console.log('Applying filters:', JSON.stringify(filters, null, 2));
    for (const fieldKey in filters) {
        if (Object.prototype.hasOwnProperty.call(filters, fieldKey)) {
            const filterValue = filters[fieldKey];
            if (filterValue !== null && filterValue !== undefined && filterValue !== '') {
                const parsedValue = parseQueryValue(filterValue);
                console.log(`  -> Querying: ${fieldKey} == ${parsedValue} (original value: '${filterValue}', type: ${typeof parsedValue})`);
                query = query.where(fieldKey, '==', parsedValue);
            }
        }
    }

    try {
        // Optimized way to get total count for filtered query
        const countSnapshot = await query.count().get();
        const totalRecords = countSnapshot.data().count;
        console.log(`Total records found for filters: ${totalRecords}`);

        // Applying fixed orderBy: 'gameID' and documentId for guaranteed unique cursor pagination.
        console.log(`Applying fixed orderBy: ${orderByField} ${orderDirection}, then documentId`);
        query = query.orderBy(orderByField, orderDirection)
                     .orderBy(admin.firestore.FieldPath.documentId(), orderDirection);

        // Apply cursor-based pagination
        if (cursor) {
            console.log(`Applying startAfter cursor: ${JSON.stringify(cursor)}`);
            query = query.startAfter(...cursor);
        }

        query = query.limit(limit);

        const snapshot = await query.get();

        if (snapshot.empty) {
            console.log('No matching documents found for the current page/limit.');
            return {
                data: [],
                totalRecords: totalRecords,
                nextCursor: null, // No next page
                message: 'No documents found for the current page/criteria.'
            };
        }

        const matchups = snapshot.docs.map(doc => {
            const docData = doc.data();
            for (const key in docData) {
                if (docData[key] instanceof admin.firestore.Timestamp) {
                    docData[key] = docData[key].toDate().toISOString(); 
                }
            }
            return { id: doc.id, ...docData }; // Include document ID for the cursor
        });

        let nextCursor = null;
        // Determine nextCursor: if we fetched a full page, the last document is the cursor for the next page
        // This also handles the case where the last page has fewer than 'limit' documents.
        if (snapshot.docs.length === limit) {
            const lastDoc = snapshot.docs[snapshot.docs.length - 1];
            // EXPLICITLY use 'gameID' and documentId for the nextCursor to guarantee uniqueness.
            const gameIdValue = lastDoc.get('gameID');
            const docIdValue = lastDoc.id;

            console.log(`Debug: lastDoc values - gameID: ${gameIdValue}, documentId: ${docIdValue}`);
            
            // The cursor MUST contain the values for all orderBy fields in order.
            nextCursor = [gameIdValue, docIdValue]; // Now a 2-element cursor using gameID
            console.log(`Generated nextCursor: ${JSON.stringify(nextCursor)}`);
        } else {
            console.log('Fewer docs than limit, indicating last page. nextCursor will be null.');
        }

        console.log(`Returning ${matchups.length} documents for current page.`);
        return {
            data: matchups,
            totalRecords: totalRecords,
            nextCursor: nextCursor, // Send the cursor for the next page
            message: `Successfully fetched ${matchups.length} records.`
        };

    } catch (error) {
        console.error('Error in getHistoricalMatchups Cloud Function:', error);
        // --- SUREFIRE FIX: Log index request directly from the backend ---
        if (error.code === 'failed-precondition' && error.message) {
            console.log("!!! FAILED PRECONDITION DETECTED. Logging index request automatically. !!!");
            const db = admin.firestore();
            // Extract the URL from the error message
            const urlRegex = /(https:\/\/[^\s]+)/;
            const match = error.message.match(urlRegex);
            const indexUrl = match ? match[0] : 'Could not parse URL from error.';

            // Create a simple description of the query that failed
            const queryDetailsString = Object.entries(filters)
                .map(([key, value]) => `${key} == ${value}`)
                .join(', ');

            try {
                await db.collection('admin_index_requests').add({
                    indexUrl: indexUrl,
                    queryDetails: queryDetailsString,
                    screen: 'HistoricalDataScreen',
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    status: 'pending',
                    errorDetails: error.message,
                });
                console.log("--- SUCCESSFULLY LOGGED index request to Firestore. ---");
            } catch (loggingError) {
                console.error("!!! CRITICAL: FAILED TO LOG THE INDEX REQUEST. !!!", loggingError);
            }
        }
        // --- END FIX ---
        throw new functions.https.HttpsError('internal', `Failed to fetch historical matchups: ${error.message}`, error.details || {originalError: error.toString()});
    }
});

exports.getWrModelStats = functions.https.onCall(async (data, context) => {
  try {
    const db = admin.firestore();
    let query = db.collection('wrModelStats');

    console.log('getWrModelStats called with data:', JSON.stringify(data, null, 2));

    // Apply filters if provided
    if (data.filters && typeof data.filters === 'object') {
      Object.entries(data.filters).forEach(([field, value]) => {
        const parsedValue = parseQueryValue(value);
        console.log(`Applying filter: ${field} == ${parsedValue}`);
        if (parsedValue !== null) {
          query = query.where(field, '==', parsedValue);
        }
      });
    }

    // Get total count for pagination (Firestore count() is efficient)
    const totalSnapshot = await query.count().get();
    const totalRecords = totalSnapshot.data().count;
    console.log('Total records for query:', totalRecords);

    // Apply sorting if provided, and always add documentId as secondary sort for stable pagination
    let orderByField = data.orderBy || 'season'; // Default sort field
    const orderDirection = data.orderDirection === 'asc' ? 'asc' : 'desc';
    console.log(`Applying orderBy: ${orderByField} ${orderDirection}, then documentId`);
    query = query.orderBy(orderByField, orderDirection).orderBy(admin.firestore.FieldPath.documentId(), orderDirection);

    // Apply cursor-based pagination
    if (data.cursor) {
      // The cursor will be an array: [orderByFieldValue, documentId]
      console.log(`Applying startAfter cursor: ${JSON.stringify(data.cursor)}`);
      query = query.startAfter(...data.cursor);
    }

    if (data.limit) {
      query = query.limit(data.limit);
    }

    // Execute query
    const snapshot = await query.get();
    if (snapshot.empty) {
      console.warn('No documents found for wrModelStats query.');
      return {
        data: [],
        totalRecords: totalRecords,
        nextCursor: null, // No next page
        message: 'No WR model stats found for the current query.'
      };
    }
    const results = snapshot.docs.map(doc => {
      const docData = doc.data();
      // Convert any Firestore Timestamps to ISO strings
      Object.keys(data).forEach(key => {
        if (data[key] instanceof admin.firestore.Timestamp) {
          data[key] = data[key].toDate().toISOString();
        }
      });
      return { id: doc.id, ...docData }; // Include document ID for the cursor
    });

    let nextCursor = null;
    // Determine nextCursor: if we fetched a full page, the last document is the cursor for the next page
    if (snapshot.docs.length === data.limit) {
        const lastDoc = snapshot.docs[snapshot.docs.length - 1];
        nextCursor = [lastDoc.get(orderByField), lastDoc.id];
        console.log(`Generated nextCursor: ${JSON.stringify(nextCursor)}`);
    } else {
        console.log('Fewer docs than limit, indicating last page. nextCursor will be null.');
    }

    console.log(`Returning ${results.length} WR model records.`);
    return {
      data: results,
      totalRecords: totalRecords,
      nextCursor: nextCursor // Send the cursor for the next page
    };
  } catch (error) {
    console.error('Error in getWrModelStats:', error);
    // --- SUREFIRE FIX: Log index request directly from the backend ---
    if (error.code === 'failed-precondition' && error.message) {
        console.log("!!! FAILED PRECONDITION DETECTED. Logging index request automatically. !!!");
        const db = admin.firestore();
        const urlRegex = /(https:\/\/[^\s]+)/;
        const match = error.message.match(urlRegex);
        const indexUrl = match ? match[0] : 'Could not parse URL from error.';

        const queryDetailsString = Object.entries(data.filters || {})
            .map(([key, value]) => `${key} == ${value}`)
            .join(', ');

        try {
            await db.collection('admin_index_requests').add({
                indexUrl: indexUrl,
                queryDetails: queryDetailsString,
                screen: 'WRModelScreen',
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                status: 'pending',
                errorDetails: error.message,
            });
            console.log("--- SUCCESSFULLY LOGGED index request to Firestore. ---");
        } catch (loggingError) {
            console.error("!!! CRITICAL: FAILED TO LOG THE INDEX REQUEST. !!!", loggingError);
        }
    }
    // --- END FIX ---
    throw new functions.https.HttpsError(
      'internal',
      `Failed to fetch WR Model data: ${error.message}`,
      error
    );
  }
});