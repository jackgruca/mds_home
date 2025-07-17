const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'nfl-draft-simulator-9265f'
});

const db = admin.firestore();

async function importTERankings() {
  try {
    console.log('Starting TE rankings import...');
    
    // Read the comprehensive TE rankings JSON file
    const rawData = fs.readFileSync('./te_rankings_comprehensive.json', 'utf8');
    const teRankings = JSON.parse(rawData);
    
    console.log(`Found ${teRankings.length} TE rankings to import`);
    
    // Clear existing data
    const existingQuery = await db.collection('te_rankings_comprehensive').get();
    const batch = db.batch();
    
    existingQuery.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    if (existingQuery.docs.length > 0) {
      await batch.commit();
      console.log(`Deleted ${existingQuery.docs.length} existing TE rankings`);
    }
    
    // Import new data in batches
    const batchSize = 500;
    let imported = 0;
    
    for (let i = 0; i < teRankings.length; i += batchSize) {
      const batch = db.batch();
      const batchData = teRankings.slice(i, i + batchSize);
      
      batchData.forEach((te, index) => {
        const docRef = db.collection('te_rankings_comprehensive').doc();
        
        // Normalize the data to match expected fields
        const normalizedTE = {
          player_id: te.player_id || te.receiver_player_id || null,
          player_name: te.player_name || te.receiver_player_name || 'Unknown',
          posteam: te.team || te.posteam || 'UNK',
          season: te.season || 2024,
          myRankNum: te.rank || te.myRankNum || (i + index + 1),
          qbTier: te.tier || te.qbTier || Math.ceil((te.rank || te.myRankNum || (i + index + 1)) / 4),
          numGames: te.games || te.numGames || 16,
          
          // Core TE stats from your R analysis (same as WR but with TE-specific weighting)
          totalEPA: te.epa || te.totalEPA || 0,
          tgt_share: te.target_share || te.tgt_share || 0,
          numYards: te.yards || te.numYards || 0,
          totalTD: te.touchdowns || te.totalTD || 0,
          numRec: te.receptions || te.numRec || 0,
          conversion: te.conversion_rate || te.conversion || 0,
          explosive_rate: te.explosive_rate || 0,
          avg_separation: te.separation || te.avg_separation || 0,
          avg_intended_air_yards: te.adot || te.avg_intended_air_yards || 0,
          catch_percentage: te.catch_percentage || 0,
          yac_above_expected: te.yac_above_expected || 0,
          third_down_rate: te.third_down_rate || 0,
          
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
      console.log(`Imported ${imported}/${teRankings.length} TE rankings...`);
    }
    
    console.log(`✅ Successfully imported ${imported} TE rankings to Firestore`);
    
  } catch (error) {
    console.error('❌ Error importing TE rankings:', error);
    throw error;
  }
}

// Run the import
importTERankings()
  .then(() => {
    console.log('Import completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Import failed:', error);
    process.exit(1);
  });