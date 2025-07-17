const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://sticktothemovie-default-rtdb.firebaseio.com"
  });
}

const db = admin.firestore();

async function importTERankings() {
  try {
    console.log('Starting TE rankings import...');
    
    // Read the proper TE rankings data
    const teRankingsData = JSON.parse(
      fs.readFileSync('/Users/jackgruca/Documents/GitHub/mds_home/data_processing/te_rankings_proper.json', 'utf8')
    );

    console.log(`Found ${teRankingsData.length} TE rankings records`);

    // Delete existing TE rankings
    console.log('Clearing existing TE rankings...');
    const existingQuery = await db.collection('rankings').where('position', '==', 'te').get();
    
    const batch = db.batch();
    existingQuery.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log(`Deleted ${existingQuery.docs.length} existing TE rankings`);

    // Import new TE rankings in batches
    const batchSize = 500;
    let totalImported = 0;

    for (let i = 0; i < teRankingsData.length; i += batchSize) {
      const batchData = teRankingsData.slice(i, i + batchSize);
      const importBatch = db.batch();

      batchData.forEach(te => {
        const docRef = db.collection('rankings').doc();
        const teData = {
          position: 'te',
          player_id: te.receiver_player_id,
          player_name: te.receiver_player_name,
          posteam: te.posteam,
          season: te.season,
          totalEPA: te.totalEPA,
          totalTD: te.totalTD,
          numGames: te.numGames,
          tgt_share: te.tgt_share,
          numYards: te.numYards,
          numTD: te.numTD,
          numRec: te.numRec,
          conversion: te.conversion,
          explosive_rate: te.explosive_rate,
          avg_separation: te.avg_separation,
          avg_intended_air_yards: te.avg_intended_air_yards,
          catch_percentage: te.catch_percentage,
          third_down_rate: te.third_down_rate,
          yac_above_expected: te.yac_above_expected,
          myRank: te.myRank,
          myRankNum: te.myRankNum,
          tier: te.qbTier,
          qbTier: te.qbTier,
          player_position: 'TE',
          importedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        importBatch.set(docRef, teData);
      });

      await importBatch.commit();
      totalImported += batchData.length;
      console.log(`Imported batch ${Math.ceil((i + 1) / batchSize)}: ${batchData.length} records (Total: ${totalImported})`);
    }

    console.log(`✅ Successfully imported ${totalImported} TE rankings`);
    
    // Verify the import
    const verifyQuery = await db.collection('rankings').where('position', '==', 'te').get();
    console.log(`✅ Verification: ${verifyQuery.docs.length} TE rankings now in database`);

  } catch (error) {
    console.error('❌ Error importing TE rankings:', error);
    throw error;
  }
}

// Run the import
importTERankings()
  .then(() => {
    console.log('TE rankings import completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('TE rankings import failed:', error);
    process.exit(1);
  });