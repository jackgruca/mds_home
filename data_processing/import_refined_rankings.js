const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://mds-home-default-rtdb.firebaseio.com'
});

const db = admin.firestore();

async function importRefinedRankings() {
  try {
    console.log('🚀 Starting import of refined NFL rankings...');
    
    // Load the enhanced ranking data
    const qbData = JSON.parse(fs.readFileSync('qb_rankings_enhanced.json', 'utf8'));
    const wrData = JSON.parse(fs.readFileSync('wr_rankings_enhanced.json', 'utf8'));
    const rbData = JSON.parse(fs.readFileSync('rb_rankings_enhanced.json', 'utf8'));
    const teData = JSON.parse(fs.readFileSync('te_rankings_enhanced.json', 'utf8'));
    
    console.log('📊 Data loaded:');
    console.log(`  QB Rankings: ${qbData.length} player-seasons`);
    console.log(`  WR Rankings: ${wrData.length} player-seasons`);
    console.log(`  RB Rankings: ${rbData.length} player-seasons`);
    console.log(`  TE Rankings: ${teData.length} player-seasons`);
    
    // Clear existing collections first
    console.log('\n🗑️ Clearing existing ranking collections...');
    await clearCollection('qbRankings');
    await clearCollection('wrRankings');
    await clearCollection('rb_rankings');
    await clearCollection('te_rankings');
    
    // Import QB Rankings (restored original logic)
    console.log('\n🏈 Importing QB rankings with restored original methodology...');
    await importInBatches(qbData, 'qbRankings', (qb) => ({
      ...qb,
      position: 'QB',
      myRankNum: qb.rank,
      posteam: qb.team,
      epaTier: qb.tier,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    }));
    console.log(`✅ Imported ${qbData.length} QB rankings`);
    
    // Import WR Rankings (corrected target share + user weights)
    console.log('\n🎯 Importing WR rankings with corrected target share...');
    await importInBatches(wrData, 'wrRankings', (wr) => ({
      ...wr,
      position: 'WR',
      posteam: wr.team,
      numYards: wr.yards || 0,
      numTD: wr.touchdowns || 0,
      numRec: wr.receptions || 0,
      myRankNum: wr.rank,
      epaTier: wr.tier,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    }));
    console.log(`✅ Imported ${wrData.length} WR rankings`);
    
    // Import RB Rankings (corrected rush share + user weights)
    console.log('\n🏃 Importing RB rankings with corrected rush share...');
    await importInBatches(rbData, 'rb_rankings', (rb) => ({
      ...rb,
      position: 'RB',
      posteam: rb.team,
      numYards: rb.yards || 0,
      numTD: rb.touchdowns || 0,
      numRec: rb.receptions || 0,
      myRankNum: rb.rank,
      epaTier: rb.tier,
      totalEPA: rb.epa || 0,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    }));
    console.log(`✅ Imported ${rbData.length} RB rankings`);
    
    // Import TE Rankings (user-specified weights)
    console.log('\n🎪 Importing TE rankings with user-specified weights...');
    await importInBatches(teData, 'te_rankings', (te) => ({
      ...te,
      position: 'TE',
      posteam: te.team,
      numYards: te.yards || 0,
      numTD: te.touchdowns || 0,
      numRec: te.receptions || 0,
      myRankNum: te.rank,
      epaTier: te.tier,
      totalEPA: te.epa || 0,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    }));
    console.log(`✅ Imported ${teData.length} TE rankings`);
    
    console.log('\n🎉 Import completed successfully!');
    console.log('\n📋 Summary of fixes implemented:');
    console.log('✅ QB Rankings: Restored original proven methodology');
    console.log('✅ Target Share: Fixed calculation using actual team passing attempts');
    console.log('✅ Rush Share: Fixed calculation using actual team rushing attempts');
    console.log('✅ Position Weights: Updated per user specifications:');
    console.log('   - WR: yards (35%), TD (25%), target share (25%), EPA (15%)');
    console.log('   - RB: EPA (25%), yards (20%), TD (20%), rush share (15%), explosive (10%), conversion (10%)');
    console.log('   - TE: yards (30%), TD (25%), EPA (25%), conversion rate (20%)');
    
    // Display sample 2024 data to verify
    console.log('\n🏆 Sample 2024 Top Rankings:');
    const sample2024QB = qbData.filter(qb => qb.season === 2024 && qb.rank <= 5);
    const sample2024WR = wrData.filter(wr => wr.season === 2024 && wr.rank <= 5);
    const sample2024RB = rbData.filter(rb => rb.season === 2024 && rb.rank <= 5);
    const sample2024TE = teData.filter(te => te.season === 2024 && te.rank <= 5);
    
    console.log('Top 5 QBs 2024:', sample2024QB.map(qb => `${qb.player_name} (${qb.team})`).join(', '));
    console.log('Top 5 WRs 2024:', sample2024WR.map(wr => `${wr.player_name} (${wr.team})`).join(', '));
    console.log('Top 5 RBs 2024:', sample2024RB.map(rb => `${rb.player_name} (${rb.team})`).join(', '));
    console.log('Top 5 TEs 2024:', sample2024TE.map(te => `${te.player_name} (${te.team})`).join(', '));
    
  } catch (error) {
    console.error('❌ Error during import:', error);
  } finally {
    process.exit(0);
  }
}

async function clearCollection(collectionName) {
  try {
    const snapshot = await db.collection(collectionName).get();
    console.log(`   Clearing ${snapshot.size} documents from ${collectionName}...`);
    
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    if (snapshot.size > 0) {
      await batch.commit();
    }
    console.log(`   ✅ Cleared ${collectionName}`);
  } catch (error) {
    console.log(`   ⚠️ Note: ${collectionName} may not exist yet (${error.message})`);
  }
}

async function importInBatches(data, collectionName, transformFn) {
  const batchSize = 500;
  const totalBatches = Math.ceil(data.length / batchSize);
  
  for (let i = 0; i < totalBatches; i++) {
    const batch = db.batch();
    const startIdx = i * batchSize;
    const endIdx = Math.min(startIdx + batchSize, data.length);
    const batchData = data.slice(startIdx, endIdx);
    
    batchData.forEach(item => {
      const docRef = db.collection(collectionName).doc();
      batch.set(docRef, transformFn(item));
    });
    
    await batch.commit();
    console.log(`   Batch ${i + 1}/${totalBatches} complete (${batchData.length} records)`);
  }
}

// Run the import
importRefinedRankings(); 