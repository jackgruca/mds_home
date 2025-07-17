const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function importEnhancedRankings() {
  try {
    console.log('🚀 Starting enhanced rankings import...');
    
    // Clear existing collections
    console.log('🗑️  Clearing existing collections...');
    await clearCollection('qb_rankings');
    await clearCollection('wr_rankings');
    await clearCollection('te_rankings');
    await clearCollection('rb_rankings');
    
    // Import QB Rankings
    console.log('📊 Importing QB Rankings...');
    const qbData = JSON.parse(fs.readFileSync('qb_rankings_enhanced.json', 'utf8'));
    await importToCollection('qb_rankings', qbData);
    
    // Import WR Rankings
    console.log('📊 Importing WR Rankings...');
    const wrData = JSON.parse(fs.readFileSync('wr_rankings_enhanced.json', 'utf8'));
    await importToCollection('wr_rankings', wrData);
    
    // Import TE Rankings
    console.log('📊 Importing TE Rankings...');
    const teData = JSON.parse(fs.readFileSync('te_rankings_enhanced.json', 'utf8'));
    await importToCollection('te_rankings', teData);
    
    // Import RB Rankings
    console.log('📊 Importing RB Rankings...');
    const rbData = JSON.parse(fs.readFileSync('rb_rankings_enhanced.json', 'utf8'));
    await importToCollection('rb_rankings', rbData);
    
    console.log('✅ All enhanced rankings imported successfully!');
    
  } catch (error) {
    console.error('❌ Error importing enhanced rankings:', error);
  }
}

async function clearCollection(collectionName) {
  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();
  
  if (snapshot.empty) {
    console.log(`   Collection ${collectionName} is already empty`);
    return;
  }
  
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log(`   Cleared ${snapshot.size} documents from ${collectionName}`);
}

async function importToCollection(collectionName, data) {
  const collectionRef = db.collection(collectionName);
  const batchSize = 500;
  
  for (let i = 0; i < data.length; i += batchSize) {
    const batch = db.batch();
    const batchData = data.slice(i, i + batchSize);
    
    batchData.forEach(item => {
      // Create a unique document ID
      const docId = `${item.player_name}_${item.team}_${item.season}`.replace(/[^a-zA-Z0-9]/g, '_');
      const docRef = collectionRef.doc(docId);
      
      // Convert numeric fields to proper types
      const processedItem = {
        ...item,
        season: parseInt(item.season),
        rank: parseInt(item.rank),
        tier: parseInt(item.tier),
        // Convert numeric fields
        epa: item.epa ? parseFloat(item.epa) : null,
        yards: item.yards ? parseFloat(item.yards) : null,
        yards_per_game: item.yards_per_game ? parseFloat(item.yards_per_game) : null,
        touchdowns: item.touchdowns ? parseInt(item.touchdowns) : null,
        td_per_game: item.td_per_game ? parseFloat(item.td_per_game) : null,
        targets: item.targets ? parseInt(item.targets) : null,
        receptions: item.receptions ? parseInt(item.receptions) : null,
        target_share: item.target_share ? parseFloat(item.target_share) : null,
        red_zone_conversion: item.red_zone_conversion ? parseFloat(item.red_zone_conversion) : null,
        explosive_rate: item.explosive_rate ? parseFloat(item.explosive_rate) : null,
        avg_separation: item.avg_separation ? parseFloat(item.avg_separation) : null,
        catch_percentage: item.catch_percentage ? parseFloat(item.catch_percentage) : null,
        yac_above_expected: item.yac_above_expected ? parseFloat(item.yac_above_expected) : null,
        third_down_rate: item.third_down_rate ? parseFloat(item.third_down_rate) : null,
        // RB specific fields
        rush_attempts: item.rush_attempts ? parseInt(item.rush_attempts) : null,
        rush_share: item.rush_share ? parseFloat(item.rush_share) : null,
        ryoe_per_att: item.ryoe_per_att ? parseFloat(item.ryoe_per_att) : null,
        efficiency: item.efficiency ? parseFloat(item.efficiency) : null,
        // QB specific fields
        myRank: item.myRank ? parseFloat(item.myRank) : null
      };
      
      batch.set(docRef, processedItem);
    });
    
    await batch.commit();
    console.log(`   Imported batch ${Math.floor(i/batchSize) + 1} for ${collectionName} (${batchData.length} items)`);
  }
  
  console.log(`   ✅ ${collectionName}: ${data.length} documents imported`);
}

// Run the import
importEnhancedRankings().then(() => {
  console.log('🎉 Enhanced rankings import completed!');
  process.exit(0);
}).catch(error => {
  console.error('💥 Import failed:', error);
  process.exit(1);
}); 