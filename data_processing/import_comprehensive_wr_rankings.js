const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'nfl-draft-simulator-9265f'
});

const db = admin.firestore();

async function importWRRankings() {
  try {
    console.log('Starting WR rankings import...');
    
    // Read the comprehensive WR rankings JSON file
    const rawData = fs.readFileSync('./wr_rankings_comprehensive.json', 'utf8');
    const wrRankings = JSON.parse(rawData);
    
    console.log(`Found ${wrRankings.length} WR rankings to import`);
    
    // Clear existing data
    const existingQuery = await db.collection('wr_rankings_comprehensive').get();
    const batch = db.batch();
    
    existingQuery.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    if (existingQuery.docs.length > 0) {
      await batch.commit();
      console.log(`Deleted ${existingQuery.docs.length} existing WR rankings`);
    }
    
    // Import new data in batches
    const batchSize = 500;
    let imported = 0;
    
    for (let i = 0; i < wrRankings.length; i += batchSize) {
      const batch = db.batch();
      const batchData = wrRankings.slice(i, i + batchSize);
      
      batchData.forEach((wr, index) => {
        const docRef = db.collection('wr_rankings_comprehensive').doc();
        
        // Normalize the data to match expected fields
        const normalizedWR = {
          player_id: wr.player_id || wr.receiver_player_id || null,
          player_name: wr.player_name || wr.receiver_player_name || 'Unknown',
          posteam: wr.team || wr.posteam || 'UNK',
          season: wr.season || 2024,
          myRankNum: wr.rank || wr.myRankNum || (i + index + 1),
          qbTier: wr.tier || wr.qbTier || Math.ceil((wr.rank || wr.myRankNum || (i + index + 1)) / 4),
          numGames: wr.games || wr.numGames || 16,
          
          // Core WR stats from your R analysis
          totalEPA: wr.epa || wr.totalEPA || 0,
          tgt_share: wr.target_share || wr.tgt_share || 0,
          numYards: wr.yards || wr.numYards || 0,
          totalTD: wr.touchdowns || wr.totalTD || 0,
          numRec: wr.receptions || wr.numRec || 0,
          conversion: wr.conversion_rate || wr.conversion || 0,
          explosive_rate: wr.explosive_rate || 0,
          avg_separation: wr.separation || wr.avg_separation || 0,
          avg_intended_air_yards: wr.adot || wr.avg_intended_air_yards || 0,
          catch_percentage: wr.catch_percentage || 0,
          yac_above_expected: wr.yac_above_expected || 0,
          third_down_rate: wr.third_down_rate || 0,
          
          // Additional stats
          targets: wr.targets || 0,
          
          // Metadata
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        };
        
        batch.set(docRef, normalizedWR);
      });
      
      await batch.commit();
      imported += batchData.length;
      console.log(`Imported ${imported}/${wrRankings.length} WR rankings...`);
    }
    
    console.log(`✅ Successfully imported ${imported} WR rankings to Firestore`);
    
  } catch (error) {
    console.error('❌ Error importing WR rankings:', error);
    throw error;
  }
}

// Run the import
importWRRankings()
  .then(() => {
    console.log('Import completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Import failed:', error);
    process.exit(1);
  });