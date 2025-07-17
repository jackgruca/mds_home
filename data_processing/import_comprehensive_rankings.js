const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://mds-home-default-rtdb.firebaseio.com"
});

const db = admin.firestore();

// Function to clean data and remove undefined values
function cleanData(obj) {
  const cleaned = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value !== undefined && value !== null && value !== '') {
      if (typeof value === 'number' && (isNaN(value) || !isFinite(value))) {
        // Skip NaN and infinite values
        continue;
      }
      cleaned[key] = value;
    }
  }
  return cleaned;
}

// Function to clear collection in batches
async function clearCollection(collectionName) {
  const collection = db.collection(collectionName);
  const query = collection.orderBy('__name__').limit(500);
  
  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject);
  });
}

async function deleteQueryBatch(query, resolve, reject) {
  try {
    const snapshot = await query.get();
    
    if (snapshot.size === 0) {
      resolve();
      return;
    }
    
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    
    // Recurse on the next batch
    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch (error) {
    reject(error);
  }
}

// Function to import data in batches
async function importDataInBatches(collectionName, data) {
  console.log(`Importing ${collectionName}...`);
  
  let batch = db.batch();
  let batchCount = 0;
  let totalImported = 0;
  let batchNumber = 1;
  
  for (let i = 0; i < data.length; i++) {
    const item = data[i];
    const cleanedItem = cleanData(item);
    
    // Only import if we have required fields
    if (cleanedItem.player_name && cleanedItem.team && cleanedItem.season) {
      const docRef = db.collection(collectionName).doc();
      batch.set(docRef, cleanedItem);
      batchCount++;
      totalImported++;
    }
    
    // Commit batch when we reach 400 items (staying under 500 limit) or at the end
    if (batchCount === 400 || i === data.length - 1) {
      if (batchCount > 0) {
        await batch.commit();
        console.log(`  Batch ${batchNumber}: Imported ${batchCount} ${collectionName} (Total: ${totalImported})`);
        batchNumber++;
      }
      batch = db.batch();
      batchCount = 0;
    }
  }
  
  console.log(`✅ Imported ${totalImported} ${collectionName} total`);
  return totalImported;
}

async function importRankings() {
  try {
    console.log('Starting comprehensive rankings import...');

    // Load the JSON data
    const qbRankings = JSON.parse(fs.readFileSync('qb_rankings_comprehensive.json', 'utf8'));
    const wrRankings = JSON.parse(fs.readFileSync('wr_rankings_comprehensive.json', 'utf8'));
    const teRankings = JSON.parse(fs.readFileSync('te_rankings_comprehensive.json', 'utf8'));
    const rbRankings = JSON.parse(fs.readFileSync('rb_rankings_comprehensive.json', 'utf8'));

    console.log(`Loaded data:`);
    console.log(`- QB Rankings: ${qbRankings.length} records`);
    console.log(`- WR Rankings: ${wrRankings.length} records`);
    console.log(`- TE Rankings: ${teRankings.length} records`);
    console.log(`- RB Rankings: ${rbRankings.length} records`);

    // Clear existing collections in batches
    console.log('Clearing existing collections...');
    
    const collections = ['qb_rankings', 'wr_rankings', 'te_rankings', 'rb_rankings'];
    for (const collection of collections) {
      console.log(`Clearing ${collection}...`);
      await clearCollection(collection);
      console.log(`✅ Cleared ${collection} collection`);
    }

    // Import all data
    await importDataInBatches('qb_rankings', qbRankings);
    await importDataInBatches('wr_rankings', wrRankings);
    await importDataInBatches('te_rankings', teRankings);
    await importDataInBatches('rb_rankings', rbRankings);

    console.log('🎉 All comprehensive rankings imported successfully!');
    
    console.log('\n📊 Import Summary:');
    console.log(`- QB Rankings: ${qbRankings.length} records loaded, imported successfully`);
    console.log(`- WR Rankings: ${wrRankings.length} records loaded, imported successfully`);
    console.log(`- TE Rankings: ${teRankings.length} records loaded, imported successfully`);
    console.log(`- RB Rankings: ${rbRankings.length} records loaded, imported successfully`);
    console.log('\n✅ All data has been successfully imported to Firebase!');
    console.log('Note: You may need to create Firebase indexes for complex queries in the app.');

  } catch (error) {
    console.error('Error importing rankings:', error);
  } finally {
    process.exit(0);
  }
}

importRankings(); 