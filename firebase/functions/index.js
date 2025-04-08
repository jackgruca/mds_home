const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Import our analytics aggregation function
const analyticsAggregation = require('./analyticsAggregation');

// Export the functions
exports.dailyAnalyticsAggregation = analyticsAggregation.dailyAnalyticsAggregation;
exports.getAnalyticsData = analyticsAggregation.getAnalyticsData;
