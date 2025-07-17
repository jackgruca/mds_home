const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'nfl-draft-simulator-9265f'
});

const db = admin.firestore();

async function importRBRankings() {
  try {
    console.log('Starting RB rankings import...');
    
    // Read the comprehensive RB rankings JSON file
    const rawData = fs.readFileSync('./rb_rankings_comprehensive.json', 'utf8');
    const rbRankings = JSON.parse(rawData);
    
    console.log(`Found ${rbRankings.length} RB rankings to import`);
    
    // Clear existing data
    const existingQuery = await db.collection('rb_rankings_comprehensive').get();
    const batch = db.batch();
    
    existingQuery.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    if (existingQuery.docs.length > 0) {
      await batch.commit();
      console.log(`Deleted ${existingQuery.docs.length} existing RB rankings`);
    }
    
    // Import new data in batches
    const batchSize = 500;
    let imported = 0;
    
    for (let i = 0; i < rbRankings.length; i += batchSize) {
      const batch = db.batch();
      const batchData = rbRankings.slice(i, i + batchSize);
      
      batchData.forEach((rb, index) => {
        const docRef = db.collection('rb_rankings_comprehensive').doc();
        
        // Normalize the data to match expected fields
        const normalizedRB = {
          player_id: rb.player_id || null,
          player_name: rb.player_name || 'Unknown',
          posteam: rb.team || rb.posteam || 'UNK',
          season: rb.season || 2024,
          myRankNum: rb.rank || (i + index + 1),
          qbTier: rb.tier || Math.ceil((rb.rank || (i + index + 1)) / 4),
          numGames: rb.games || 16,
          
          // Core RB stats from your R analysis
          totalEPA: rb.epa || 0,
          run_share: rb.rush_share || 0,
          YPG: rb.yards || 0,
          tgt_share: rb.target_share || 0,
          totalTD: rb.touchdowns || 0,
          conversion: rb.conversion_rate || 0,
          explosive_rate: rb.explosive_rate || 0,
          avg_eff: rb.efficiency || 0,
          avg_RYOE_perAtt: rb.ryoe_per_att || 0,
          third_down_rate: rb.third_down_rate || 0,
          
          // Additional stats
          rush_attempts: rb.attempts || 0,
          numRec: rb.receptions || 0,
          
          // Metadata
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        };
        
        batch.set(docRef, normalizedRB);
      });
      
      await batch.commit();
      imported += batchData.length;
      console.log(`Imported ${imported}/${rbRankings.length} RB rankings...`);
    }
    
    console.log(`✅ Successfully imported ${imported} RB rankings to Firestore`);
    
  } catch (error) {
    console.error('❌ Error importing RB rankings:', error);
    throw error;
  }
}

// Run the import
importRBRankings()
  .then(() => {
    console.log('Import completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Import failed:', error);
    process.exit(1);
  });