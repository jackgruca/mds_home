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

// Add new HTTP-callable function for direct triggering
exports.dailyAnalyticsAggregation = functions.runWith({
    timeoutSeconds: 540,  // Increase timeout to 9 minutes
    memory: '2GB'         // Increase memory from 256MB to 2GB
})
.pubsub
.schedule('0 2 * * *')  // Run at 2 AM every day
.timeZone('America/New_York')
.onRun(async (context) => {
    const db = admin.firestore();
    
    try {
        console.log('Starting daily analytics aggregation...');
        
        // Process draft analytics in smaller batches to avoid timeout
        const batchSize = 25;
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