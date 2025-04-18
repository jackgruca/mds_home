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

// Add this to firebase/functions/index.js

// Function to get analytics processing status
exports.getAnalyticsProcessingStatus = functions.https.onCall(async (data, context) => {
  try {
    const db = admin.firestore();
    
    // Get the metadata document
    const metadataDoc = await db.collection('precomputedAnalytics').doc('metadata').get();
    
    if (!metadataDoc.exists) {
      return {
        status: 'unknown',
        message: 'No metadata document found'
      };
    }
    
    const metadata = metadataDoc.data();
    
    // Check if processing is in progress
    if (metadata.inProgress) {
      return {
        status: 'processing',
        message: `Processing in progress: ${metadata.documentsProcessed || 0} documents processed`,
        documentsProcessed: metadata.documentsProcessed || 0,
        lastUpdated: metadata.lastUpdated ? metadata.lastUpdated.toDate().toISOString() : null
      };
    }
    
    // Check if there was an error
    if (metadata.error) {
      return {
        status: 'error',
        message: `Error: ${metadata.error}`,
        lastUpdated: metadata.lastUpdated ? metadata.lastUpdated.toDate().toISOString() : null
      };
    }
    
    // Check if data exists
    const positionDistDoc = await db.collection('precomputedAnalytics').doc('positionDistribution').get();
    
    if (!positionDistDoc.exists) {
      return {
        status: 'incomplete',
        message: 'Core data documents are missing'
      };
    }
    
    // All looks good
    return {
      status: 'ready',
      message: 'Analytics data is ready',
      lastUpdated: metadata.lastUpdated ? metadata.lastUpdated.toDate().toISOString() : null,
      documentsProcessed: metadata.documentsProcessed || 0
    };
  } catch (error) {
    console.error('Error getting analytics status:', error);
    return {
      status: 'error',
      message: `Error retrieving status: ${error.message}`,
    };
  }
});