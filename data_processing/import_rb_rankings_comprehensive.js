const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function importRBRankings() {
  try {
    console.log('🚀 Starting RB rankings import...');
    
    // Read the JSON file
    const rawData = fs.readFileSync('rb_rankings_comprehensive.json', 'utf8');
    const rbData = JSON.parse(rawData);
    
    console.log(`📊 Found ${rbData.length} RB records to import`);
    
    // Clear existing data
    console.log('🗑️ Clearing existing RB rankings...');
    const existingDocs = await db.collection('rb_rankings').get();
    const batch = db.batch();
    
    existingDocs.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    if (existingDocs.docs.length > 0) {
      await batch.commit();
      console.log(`🗑️ Deleted ${existingDocs.docs.length} existing records`);
    }
    
    // Import new data in batches
    const batchSize = 500;
    let totalImported = 0;
    
    for (let i = 0; i < rbData.length; i += batchSize) {
      const batchData = rbData.slice(i, i + batchSize);
      const writeBatch = db.batch();
      
      batchData.forEach((item, index) => {
        const docId = `${item.player_id}_${item.season}`;
        const docRef = db.collection('rb_rankings').doc(docId);
        
        const rbRecord = {
          // Core identifiers
          player_id: item.player_id || '',
          player_name: item.player_name || '',
          team: item.team || '',
          season: parseInt(item.season) || 0,
          position: item.position || 'RB',
          
          // Core rankings
          my_rank: parseInt(item.my_rank) || 0,
          my_rank_score: parseFloat(item.my_rank_score) || 0,
          tier: parseInt(item.tier) || 8,
          
          // Raw stats for UI display
          total_epa: parseFloat(item.total_epa) || 0,
          total_tds: parseInt(item.total_tds) || 0,
          total_yards: parseFloat(item.total_yards) || 0,
          rush_share: parseFloat(item.rush_share) || 0,
          target_share: parseFloat(item.target_share) || 0,
          explosive_rate: parseFloat(item.explosive_rate) || 0,
          conversion_rate: parseFloat(item.conversion_rate) || 0,
          third_down_rate: parseFloat(item.third_down_rate) || 0,
          efficiency: parseFloat(item.efficiency) || 0,
          ryoe_per_att: parseFloat(item.ryoe_per_att) || 0,
          games: parseInt(item.games) || 0,
          
          // Percentile ranks (0-1 scale for density visualization)
          epa_rank: parseFloat(item.epa_rank) || 0,
          td_rank: parseFloat(item.td_rank) || 0,
          rush_share_rank: parseFloat(item.rush_share_rank) || 0,
          target_share_rank: parseFloat(item.target_share_rank) || 0,
          yards_rank: parseFloat(item.yards_rank) || 0,
          explosive_rank: parseFloat(item.explosive_rank) || 0,
          conversion_rank: parseFloat(item.conversion_rank) || 0,
          third_down_rank: parseFloat(item.third_down_rank) || 0,
          efficiency_rank: parseFloat(item.efficiency_rank) || 0,
          ryoe_rank: parseFloat(item.ryoe_rank) || 0,
          
          // Team context
          run_offense_tier: parseInt(item.run_offense_tier) || 8,
          pass_offense_tier: parseInt(item.pass_offense_tier) || 8,
          
          // Legacy fields for compatibility
          composite_rank_score: parseFloat(item.my_rank_score) || 0,
          myRankNum: parseInt(item.my_rank) || 0,
          
          // Timestamps
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        };
        
        writeBatch.set(docRef, rbRecord);
      });
      
      await writeBatch.commit();
      totalImported += batchData.length;
      console.log(`✅ Imported batch ${Math.floor(i/batchSize) + 1}: ${totalImported}/${rbData.length} records`);
    }
    
    console.log(`🎉 Successfully imported ${totalImported} RB ranking records`);
    
    // Verify import with sample data
    console.log('\n📋 Sample of imported data:');
    const sampleQuery = await db.collection('rb_rankings')
      .limit(5)
      .get();
    
    sampleQuery.docs.forEach(doc => {
      const data = doc.data();
      console.log(`${data.my_rank}. ${data.player_name} (${data.team}) - ${data.total_yards.toFixed(1)} YPG, ${data.total_tds} TDs, ${(data.rush_share * 100).toFixed(1)}% share`);
    });
    
    console.log('\n✅ RB rankings import completed successfully!');
    
  } catch (error) {
    console.error('❌ Error importing RB rankings:', error);
    throw error;
  }
}

// Run the import
importRBRankings()
  .then(() => {
    console.log('🏁 Import process finished');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Import failed:', error);
    process.exit(1);
  }); 