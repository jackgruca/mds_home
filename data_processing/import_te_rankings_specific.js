const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'nfl-draft-simulator-9265f'
});

const db = admin.firestore();

async function importTESpecificRankings() {
  try {
    console.log('Starting TE-specific rankings import...');
    
    // Read the comprehensive TE rankings JSON file
    const rawData = fs.readFileSync('./te_rankings_comprehensive.json', 'utf8');
    const teRankings = JSON.parse(rawData);
    
    console.log(`Found ${teRankings.length} TE rankings to import`);
    
    // Clear existing data in batches
    const existingQuery = await db.collection('te_rankings_comprehensive').get();
    
    if (existingQuery.docs.length > 0) {
      const deleteBatchSize = 500;
      for (let i = 0; i < existingQuery.docs.length; i += deleteBatchSize) {
        const batch = db.batch();
        const docsToDelete = existingQuery.docs.slice(i, i + deleteBatchSize);
        
        docsToDelete.forEach((doc) => {
          batch.delete(doc.ref);
        });
        
        await batch.commit();
      }
      console.log(`Deleted ${existingQuery.docs.length} existing TE rankings`);
    }
    
    // Filter and process only TE data
    const teOnlyData = teRankings.filter(te => 
      te.player_position === 'TE' || 
      te.position === 'TE' ||
      (te.player_name && te.receiver_player_name)
    );
    
    console.log(`Filtered to ${teOnlyData.length} TE-specific records`);
    
    // Import new data in batches
    const batchSize = 100;
    let imported = 0;
    
    for (let i = 0; i < teOnlyData.length; i += batchSize) {
      const batch = db.batch();
      const batchData = teOnlyData.slice(i, i + batchSize);
      
      batchData.forEach((te, index) => {
        const docRef = db.collection('te_rankings_comprehensive').doc();
        
        // Normalize the data to match TE-specific fields from R analysis
        const normalizedTE = {
          player_id: te.player_id || te.receiver_player_id || null,
          player_name: te.player_name || te.receiver_player_name || 'Unknown',
          posteam: te.team || te.posteam || 'UNK',
          season: te.season || 2024,
          myRankNum: te.rank || te.myRankNum || (i + index + 1),
          qbTier: te.tier || te.qbTier || Math.ceil((te.rank || te.myRankNum || (i + index + 1)) / 4),
          numGames: te.games || te.numGames || 16,
          
          // Core TE stats based on R analysis (TE-specific ranking formula)
          totalEPA: te.epa || te.totalEPA || 0,
          tgt_share: te.target_share || te.tgt_share || 0,
          numYards: (te.yards || te.numYards || 0) / (te.games || te.numGames || 16), // YPG
          totalTD: (te.touchdowns || te.totalTD || 0) / (te.games || te.numGames || 16), // TD per game
          numRec: te.receptions || te.numRec || 0,
          conversion: te.conversion_rate || te.conversion || 0,
          explosive_rate: te.explosive_rate || 0,
          avg_separation: te.separation || te.avg_separation || 0,
          avg_intended_air_yards: te.adot || te.avg_intended_air_yards || 0,
          catch_percentage: te.catch_percentage || 0,
          yac_above_expected: te.yac_above_expected || 0,
          third_down_rate: te.third_down_rate || 0,
          
          // TE-specific ranking components (weights from R code)
          EPA_rank: te.EPA_rank || 0,
          td_rank: te.td_rank || 0,
          tgt_rank: te.tgt_rank || 0,
          YPG_rank: te.YPG_rank || 0,
          conversion_rank: te.conversion_rank || 0,
          explosive_rank: te.explosive_rank || 0,
          sep_rank: te.sep_rank || 0,
          intended_air_rank: te.intended_air_rank || 0,
          catch_rank: te.catch_rank || 0,
          third_down_rank: te.third_down_rank || 0,
          yacOE_rank: te.yacOE_rank || 0,
          
          // TE composite rank calculation (from R code)
          myRank: (
            0.25 * (te.tgt_rank || 0) +
            0.25 * (te.YPG_rank || 0) +
            0.15 * (te.EPA_rank || 0) +
            0.1 * (te.yacOE_rank || 0) +
            0.1 * (te.third_down_rank || 0) +
            0.05 * (te.td_rank || 0) +
            0.05 * (te.explosive_rank || 0) +
            0.05 * (te.sep_rank || 0)
          ),
          
          // Additional stats
          targets: te.targets || 0,
          
          // Metadata
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        };
        
        batch.set(docRef, normalizedTE);
      });
      
      await batch.commit();
      imported += batchData.length;
      console.log(`Imported ${imported}/${teOnlyData.length} TE rankings...`);
    }
    
    console.log(`✅ Successfully imported ${imported} TE-specific rankings to Firestore`);
    
  } catch (error) {
    console.error('❌ Error importing TE rankings:', error);
    throw error;
  }
}

// Run the import
importTESpecificRankings()
  .then(() => {
    console.log('TE-specific import completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('TE-specific import failed:', error);
    process.exit(1);
  });