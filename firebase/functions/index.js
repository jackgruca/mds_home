const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Check if the app is already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Import our analytics aggregation function
const analyticsAggregation = require('./analyticsAggregation');

// Export the functions
exports.dailyAnalyticsAggregation = analyticsAggregation.dailyAnalyticsAggregation;
exports.getAnalyticsData = analyticsAggregation.getAnalyticsData;

