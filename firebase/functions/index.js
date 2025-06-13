const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase only ONCE
if (!admin.apps.length) {
  admin.initializeApp();
}

// Import analytics aggregation functions
const analyticsAggregation = require('./analyticsAggregation');

// Export the functions
exports.dailyAnalyticsAggregation = analyticsAggregation.dailyAnalyticsAggregation;
exports.getAnalyticsData = analyticsAggregation.getAnalyticsData;

// Export the new function for historical matchups
exports.getHistoricalMatchups = analyticsAggregation.getHistoricalMatchups;
exports.getWrModelStats = analyticsAggregation.getWrModelStats;
exports.getPlayerSeasonStats = analyticsAggregation.getPlayerSeasonStats;
exports.getBettingData = analyticsAggregation.getBettingData;

exports.logMissingIndex = functions.https.onCall(async (data, context) => {
    const url = data.url;
    const timestamp = data.timestamp; // This will be an ISO string from Flutter

    if (!url || !timestamp) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'The function must be called with "url" and "timestamp" arguments.'
        );
    }

    try {
        const db = admin.firestore();
        const collectionRef = db.collection('missingIndexLogs'); // This is the new collection

        await collectionRef.add({
            url: url,
            timestamp: admin.firestore.Timestamp.fromDate(new Date(timestamp)), // Convert ISO string back to Timestamp
            loggedAt: admin.firestore.FieldValue.serverTimestamp(), // Firestore server timestamp
        });

        console.log('Missing index URL logged successfully:', url);
        return { success: true, message: 'Missing index URL logged successfully.' };
    } catch (error) {
        console.error('Error logging missing index:', error);
        throw new functions.https.HttpsError(
            'internal',
            'Failed to log missing index URL.',
            error.message
        );
    }
});