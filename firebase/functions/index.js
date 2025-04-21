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

// Add a manually callable function to trigger analytics
exports.manualTriggerAnalytics = functions.https.onCall(async (data, context) => {
  try {
    console.log('Manual analytics trigger requested');
    
    // Call the analytics aggregation function directly
    await analyticsAggregation.dailyAnalyticsAggregation();
    
    return {
      success: true, 
      message: 'Analytics aggregation completed successfully'
    };
  } catch (error) {
    console.error('Error running manual analytics aggregation:', error);
    
    // Return error but don't throw to prevent cascading errors
    return {
      success: false,
      error: error.message || 'Unknown error',
      stack: error.stack
    };
  }
});