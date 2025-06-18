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
exports.getHistoricalGameData = analyticsAggregation.getHistoricalGameData;

exports.logMissingIndex = functions.https.onCall(async (data, context) => {
    const url = data.url;
    const timestamp = data.timestamp; // This will be an ISO string from Flutter
    const screenName = data.screenName || 'Unknown Screen';

    if (!url) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'The function must be called with at least a "url" argument.'
        );
    }

    try {
        const db = admin.firestore();
        // Use the existing collection name 'admin_index_requests' that's already in your system
        const collectionRef = db.collection('admin_index_requests');

        await collectionRef.add({
            indexUrl: url,
            queryDetails: JSON.stringify(data.queryDetails || {}),
            screen: screenName,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending',
            errorDetails: data.errorMessage || 'No error details provided',
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