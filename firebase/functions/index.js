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
exports.getBettingData = analyticsAggregation.getBettingData;

exports.logIndexRequest = analyticsAggregation.logIndexRequest;