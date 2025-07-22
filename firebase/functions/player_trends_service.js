const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Ensure Firebase is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const getMedian = (arr) => {
    if (arr.length === 0) return 0;
    const sorted = [...arr].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    if (sorted.length % 2 === 0) {
        return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
};

/**
 * Calculates player trends based on a rolling window vs. full season stats.
 *
 * @param {object} data - The data passed to the function from the client.
 * @param {string} data.position - The player position to filter by (e.g., 'RB', 'WR').
 * @param {number} data.weeks - The number of recent weeks for the rolling window (e.g., 3).
 * @param {number} data.season - The season to analyze (e.g., 2023).
 */
exports.getPlayerTrends = functions.runWith({
    timeoutSeconds: 60,
    memory: '512MB'
  }).https.onCall(async (data, context) => {
    try {
        const { position, weeks, season = 2023 } = data;
        if (!position || !weeks) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters: position, weeks.');
        }

        const gameLogsSnapshot = await db.collection('playerGameLogs')
            .where('season', '==', season)
            .where('position', '==', position)
            .get();

        if (gameLogsSnapshot.empty) {
            return [];
        }

        const playersData = {};
        gameLogsSnapshot.forEach(doc => {
            const log = doc.data();
            if (!playersData[log.player_id]) {
                playersData[log.player_id] = {
                    player_id: log.player_id,
                    player_name: log.player_name,
                    position: log.position,
                    team: log.team,
                    logs: []
                };
            }
            playersData[log.player_id].logs.push(log);
        });

        const allWeeks = gameLogsSnapshot.docs.map(doc => doc.data().week).filter(w => w != null);
        if (allWeeks.length === 0) return [];
        const maxWeek = Math.max(...allWeeks);
        const startWeek = Math.max(1, maxWeek - weeks + 1);

        const results = [];
        for (const playerId in playersData) {
            const player = playersData[playerId];

            const recentLogs = player.logs.filter(log => log.week >= startWeek && log.week <= maxWeek);
            if (recentLogs.length === 0) continue;

            const gamesPlayed = recentLogs.length;
            const touches = recentLogs.map(l => (Number(l.carries) || 0) + (Number(l.targets) || 0));
            const pprPoints = recentLogs.map(l => Number(l.fantasy_points_ppr) || 0);

            const totalTouches = touches.reduce((sum, val) => sum + val, 0);
            const totalPPR = pprPoints.reduce((sum, val) => sum + val, 0);
            
            const avgTouches = totalTouches / gamesPlayed;
            const avgPPR = totalPPR / gamesPlayed;

            const medianTouches = getMedian(touches);
            const medianPPR = getMedian(pprPoints);

            results.push({
                playerId: player.player_id,
                playerName: player.player_name,
                position: player.position,
                team: player.team,
                gamesPlayed,
                avgTouches: parseFloat(avgTouches.toFixed(2)),
                medianTouches: parseFloat(medianTouches.toFixed(2)),
                avgPPR: parseFloat(avgPPR.toFixed(2)),
                medianPPR: parseFloat(medianPPR.toFixed(2)),
            });
        }

        results.sort((a, b) => b.avgPPR - a.avgPPR);
        return results;

    } catch (error) {
        console.error("Critical error in getPlayerTrends:", error);
        throw new functions.https.HttpsError('internal', 'An unexpected error occurred in getPlayerTrends.', error.message);
    }
}); 