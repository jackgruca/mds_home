const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function importTERankings() {
  try {
    console.log('Starting TE rankings import...');
    
    // Read the JSON file
    const rawData = fs.readFileSync('./te_rankings_enhanced.json', 'utf8');
    const teRankings = JSON.parse(rawData);
    
    console.log(`Found ${teRankings.length} TE ranking records`);
    
    // Clear existing data in batches
    console.log('Clearing existing te_rankings collection...');
    const existingDocs = await db.collection('te_rankings').get();
    
    if (existingDocs.docs.length > 0) {
      const deleteBatchSize = 100; // Smaller batch size for deletions
      let totalDeleted = 0;
      
      for (let i = 0; i < existingDocs.docs.length; i += deleteBatchSize) {
        const batch = db.batch();
        const docsToDelete = existingDocs.docs.slice(i, i + deleteBatchSize);
        
        docsToDelete.forEach((doc) => {
          batch.delete(doc.ref);
        });
        
        await batch.commit();
        totalDeleted += docsToDelete.length;
        console.log(`Deleted ${totalDeleted}/${existingDocs.docs.length} existing records`);
      }
    }
    
    // Process and upload data in batches
    const batchSize = 500;
    let totalProcessed = 0;
    
    for (let i = 0; i < teRankings.length; i += batchSize) {
      const batch = db.batch();
      const currentBatch = teRankings.slice(i, i + batchSize);
      
      for (const record of currentBatch) {
        // Create a unique document ID
        const docId = `${record.player_id || `te_${record.player_name}_${record.season}`}_${record.season}`;
        const docRef = db.collection('te_rankings').doc(docId);
        
        // Prepare the data with proper field mapping to match RankingService expectations
        const teData = {
          // Player identification - using RankingService expected field names
          player_id: record.player_id || `te_${record.player_name}_${record.season}`,
          player_name: record.player_name || '',
          posteam: record.team || '', // RankingService expects 'posteam'
          season: parseInt(record.season) || 0,
          position: 'TE',
          
          // Core performance metrics - using RankingService expected field names
          totalEPA: parseFloat(record.epa) || 0,
          numYards: parseInt(record.yards) || 0,
          totalTD: parseInt(record.touchdowns) || 0,
          numRec: parseInt(record.receptions) || 0,
          tgt_share: parseFloat(record.target_share) || 0,
          numGames: 15, // Estimated from context since not in enhanced data
          
          // Situational metrics
          conversion: parseFloat(record.red_zone_conversion) || 0,
          explosive_rate: parseFloat(record.explosive_rate) || 0,
          third_down_rate: parseFloat(record.third_down_rate) || 0,
          
          // Next Gen Stats
          avg_separation: parseFloat(record.avg_separation) || 0,
          avg_intended_air_yards: 0, // Not available in enhanced data
          catch_percentage: parseFloat(record.catch_percentage) || 0,
          yac_above_expected: parseFloat(record.yac_above_expected) || 0,
          
          // Ranking data
          myRankNum: parseInt(record.rank) || 999,
          tier: parseInt(record.tier) || 8,
          
          // Legacy field names for backward compatibility
          team: record.team || '',
          total_epa: parseFloat(record.epa) || 0,
          total_tds: parseInt(record.touchdowns) || 0,
          total_yards: parseInt(record.yards) || 0,
          total_receptions: parseInt(record.receptions) || 0,
          target_share: parseFloat(record.target_share) || 0,
          red_zone_conversion: parseFloat(record.red_zone_conversion) || 0,
          yards_per_game: parseFloat(record.yards_per_game) || 0,
          td_per_game: parseFloat(record.td_per_game) || 0,
          total_targets: parseInt(record.targets) || 0,
          
          // Timestamp
          last_updated: admin.firestore.FieldValue.serverTimestamp(),
        };
        
        batch.set(docRef, teData);
      }
      
      await batch.commit();
      totalProcessed += currentBatch.length;
      console.log(`Processed ${totalProcessed}/${teRankings.length} records`);
    }
    
    console.log('\n=== TE Rankings Import Summary ===');
    console.log(`Total records imported: ${totalProcessed}`);
    
    // Show some statistics
    const sampleDocs = await db.collection('te_rankings')
      .orderBy('myRankNum')
      .limit(10)
      .get();
    
    console.log('\nTop 10 TE rankings:');
    sampleDocs.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`${index + 1}. ${data.player_name} (${data.posteam} ${data.season}) - Rank: ${data.myRankNum}, Tier: ${data.tier}`);
    });
    
    // Summary by season
    const allDocs = await db.collection('te_rankings').get();
    const seasonSummary = {};
    
    allDocs.docs.forEach(doc => {
      const data = doc.data();
      const season = data.season;
      if (!seasonSummary[season]) {
        seasonSummary[season] = 0;
      }
      seasonSummary[season]++;
    });
    
    console.log('\nRecords by season:');
    Object.keys(seasonSummary).sort().forEach(season => {
      console.log(`${season}: ${seasonSummary[season]} TEs`);
    });
    
    console.log('\nTE rankings import completed successfully!');
    
  } catch (error) {
    console.error('Error importing TE rankings:', error);
    throw error;
  }
}

// Run the import
importTERankings()
  .then(() => {
    console.log('Import process finished');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Import failed:', error);
    process.exit(1);
  }); 