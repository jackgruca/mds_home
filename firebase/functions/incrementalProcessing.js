// firebase/functions/incrementalProcessing.js (new file)

// Process position trends with batching and resumability
async function processDraftPositionTrends(db) {
    // Get last processed timestamp
    const metadataDoc = await db.collection('precomputedAnalytics').doc('metadata').get();
    const metadata = metadataDoc.exists ? metadataDoc.data() : {};
    const lastProcessed = metadata.lastProcessedTimestamp || new Date(0);
    
    // Update status
    await db.collection('precomputedAnalytics').doc('metadata').set({
      jobStatus: { positions: 'processing' }
    }, {merge: true});
    
    try {
      // Get new drafts since last processing
      let query = db.collection('draftAnalytics')
        .where('timestamp', '>', lastProcessed)
        .orderBy('timestamp')
        .limit(100);
      
      let lastDoc = null;
      let hasMoreData = true;
      let batchCount = 0;
      let processedCount = 0;
      
      // Initialize position counts structure
      const positionCounts = {};
      const roundPositionCounts = {};
      
      // Initialize with existing data if available
      const existingDistDoc = await db.collection('precomputedAnalytics').doc('positionDistribution').get();
      if (existingDistDoc.exists) {
        const existingData = existingDistDoc.data();
        Object.assign(positionCounts, existingData.overall?.positions || {});
      }
      
      // Process in batches with continuation
      while (hasMoreData) {
        // Apply cursor if continuing
        if (lastDoc) {
          query = db.collection('draftAnalytics')
            .where('timestamp', '>', lastProcessed)
            .orderBy('timestamp')
            .startAfter(lastDoc)
            .limit(100);
        }
        
        const snapshot = await query.get();
        batchCount++;
        
        if (snapshot.empty) {
          hasMoreData = false;
          break;
        }
        
        // Process this batch
        snapshot.forEach(doc => {
          const data = doc.data();
          const picks = data.picks || [];
          
          picks.forEach(pick => {
            const position = pick.position;
            const round = pick.round;
            const pickNumber = pick.pickNumber;
            
            // Skip invalid data
            if (!position || !round || !pickNumber) return;
            
            // Add to global position counts
            if (!positionCounts[position]) {
              positionCounts[position] = { count: 0 };
            }
            positionCounts[position].count += 1;
            
            // Add to round-specific counts
            if (!roundPositionCounts[round]) {
              roundPositionCounts[round] = {};
            }
            if (!roundPositionCounts[round][pickNumber]) {
              roundPositionCounts[round][pickNumber] = {};
            }
            if (!roundPositionCounts[round][pickNumber][position]) {
              roundPositionCounts[round][pickNumber][position] = 0;
            }
            roundPositionCounts[round][pickNumber][position] += 1;
          });
          
          processedCount++;
        });
        
        // Update lastDoc for continuation
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        
        // Update progress
        await db.collection('precomputedAnalytics').doc('metadata').set({
          positionsProgress: {
            batchesProcessed: batchCount,
            documentsProcessed: processedCount,
            inProgress: true,
            lastBatchTime: admin.firestore.FieldValue.serverTimestamp()
          }
        }, {merge: true});
        
        // Pause briefly to avoid overwhelming Firestore
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      // Calculate position percentages
      const totalPicks = Object.values(positionCounts).reduce((sum, pos) => sum + pos.count, 0);
      
      Object.keys(positionCounts).forEach(pos => {
        positionCounts[pos].percentage = `${((positionCounts[pos].count / totalPicks) * 100).toFixed(1)}%`;
      });
      
      // Save global position distribution
      await db.collection('precomputedAnalytics').doc('positionDistribution').set({
        overall: {
          total: totalPicks,
          positions: positionCounts
        },
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      }, {merge: true});
      
      // Process and save round-specific position data
      for (const [round, pickData] of Object.entries(roundPositionCounts)) {
        // Convert to the format you have in your position_trends collection
        const formattedData = formatRoundPositionData(pickData, round);
        
        // Save to round-specific document
        await db.collection('position_trends').doc(`round_${round}`).set({
          positions: formattedData,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
        
        // Also save to precomputedAnalytics for API access
        await db.collection('precomputedAnalytics').doc(`positionsByPickRound${round}`).set({
          data: formattedData,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
      }
      
      // Update metadata with last processed timestamp
      await db.collection('precomputedAnalytics').doc('metadata').set({
        lastProcessedTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        jobStatus: { positions: 'completed' }
      }, {merge: true});
      
      return { success: true, processed: processedCount };
    } catch (error) {
      console.error('Error processing position trends:', error);
      
      // Update error status
      await db.collection('precomputedAnalytics').doc('metadata').set({
        jobStatus: { 
          positions: 'failed',
          error: error.toString()
        }
      }, {merge: true});
      
      throw error;
    }
  }
  
  // Helper to format position data in the right structure
  function formatRoundPositionData(pickData, round) {
    const result = [];
    
    for (const [pickNumber, positions] of Object.entries(pickData)) {
      // Get total picks for this position
      const totalForPick = Object.values(positions).reduce((sum, count) => sum + count, 0);
      
      // Format positions with counts and percentages
      const formattedPositions = Object.entries(positions).map(([position, count]) => ({
        position,
        count,
        percentage: `${((count / totalForPick) * 100).toFixed(1)}%`
      })).sort((a, b) => b.count - a.count);
      
      // Add to result
      result.push({
        pick: parseInt(pickNumber),
        round: round.toString(),
        positions: formattedPositions,
        totalDrafts: totalForPick
      });
    }
    
    // Sort by pick number
    return result.sort((a, b) => a.pick - b.pick);
  }
  
  // Similar implementations for other processing functions
  // Exclude these for brevity but following same pattern
  
  // Export all functions
  module.exports = {
    processDraftPositionTrends,
    processTeamNeeds,
    processPlayerDeviations,
    processPickCorrelations,
    clearExpiredCacheEntries
  };