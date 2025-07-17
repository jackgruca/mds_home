const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parser');

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

// Function to safely parse numeric values
function parseNumeric(value) {
  if (value === '' || value === null || value === undefined) return null;
  const parsed = parseFloat(value);
  return isNaN(parsed) ? null : parsed;
}

// Function to process CSV row
function processWRPrediction(row) {
  return cleanData({
    receiver_player_id: row.receiver_player_id || null,
    player: row.player || null,
    player_name: row.player_name || row.receiver_player_name || row.player || null,
    posteam: row.posteam || null,
    season: parseNumeric(row.season) || 2024,
    position: row.position || 'WR',
    
    // 2024 Historical Stats
    numGames: parseNumeric(row.numGames),
    tgt_share: parseNumeric(row.tgt_share),
    numYards: parseNumeric(row.numYards),
    numTD: parseNumeric(row.numTD),
    numRec: parseNumeric(row.numRec),
    wr_rank: parseNumeric(row.wr_rank),
    playerYear: parseNumeric(row.playerYear),
    passOffenseTier: parseNumeric(row.passOffenseTier),
    qbTier: parseNumeric(row.qbTier),
    runOffenseTier: parseNumeric(row.runOffenseTier),
    points: parseNumeric(row.points),
    epaTier: parseNumeric(row.epaTier),
    
    // 2025 Projections (NY_ prefix)
    NY_posteam: row.NY_posteam || null,
    NY_numGames: parseNumeric(row.NY_numGames),
    NY_tgtShare: parseNumeric(row.NY_tgtShare),
    NY_seasonYards: parseNumeric(row.NY_seasonYards),
    NY_wr_rank: parseNumeric(row.NY_wr_rank),
    NY_playerYear: parseNumeric(row.NY_playerYear),
    NY_passOffenseTier: parseNumeric(row.NY_passOffenseTier),
    NY_qbTier: parseNumeric(row.NY_qbTier),
    NY_points: parseNumeric(row.NY_points),
    NY_passFreqTier: parseNumeric(row.NY_passFreqTier),
    
    // Calculate composite rank for 2025 projections
    projected_season: 2025,
    projected_rank: parseNumeric(row.NY_wr_rank) || 999,
    projected_points: parseNumeric(row.NY_points) || 0,
    projected_yards: parseNumeric(row.NY_seasonYards) || 0,
    projected_target_share: parseNumeric(row.NY_tgtShare) || 0,
    
    // Metadata
    data_type: 'prediction',
    last_updated: new Date().toISOString(),
  });
}

// Function to clear collection in batches
async function clearCollection(collectionName) {
  const batchSize = 100;
  let totalDeleted = 0;
  
  while (true) {
    const snapshot = await db.collection(collectionName).limit(batchSize).get();
    
    if (snapshot.empty) {
      break;
    }
    
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    totalDeleted += snapshot.size;
    
    console.log(`Deleted ${snapshot.size} documents from ${collectionName}. Total: ${totalDeleted}`);
  }
  
  console.log(`✅ Cleared ${totalDeleted} documents from ${collectionName}`);
}

// Function to import data in batches
async function importDataInBatches(collectionName, data) {
  const batchSize = 100;
  let imported = 0;
  
  for (let i = 0; i < data.length; i += batchSize) {
    const batch = db.batch();
    const batchData = data.slice(i, i + batchSize);
    
    for (const item of batchData) {
      const docRef = db.collection(collectionName).doc();
      batch.set(docRef, item);
    }
    
    await batch.commit();
    imported += batchData.length;
    console.log(`Imported ${imported}/${data.length} documents to ${collectionName}`);
  }
  
  console.log(`✅ Successfully imported ${imported} documents to ${collectionName}`);
}

async function main() {
  try {
    console.log('🚀 Starting 2025 WR Predictions import...');
    
    // Read and process CSV data
    const wrPredictions = [];
    
    await new Promise((resolve, reject) => {
      fs.createReadStream('2025_wr_predictions.csv')
        .pipe(csv())
        .on('data', (row) => {
          const processedRow = processWRPrediction(row);
          if (processedRow.player_name) { // Only include rows with player names
            wrPredictions.push(processedRow);
          }
        })
        .on('end', resolve)
        .on('error', reject);
    });
    
    console.log(`📊 Processed ${wrPredictions.length} WR predictions`);
    
    // Clear existing predictions collection
    console.log('🧹 Clearing existing WR predictions...');
    await clearCollection('wr_predictions_2025');
    
    // Import new predictions
    console.log('📥 Importing WR predictions...');
    await importDataInBatches('wr_predictions_2025', wrPredictions);
    
    console.log('🎉 2025 WR Predictions import completed successfully!');
    
    console.log('\n📊 Import Summary:');
    console.log(`- WR Predictions: ${wrPredictions.length} records imported`);
    console.log('\n✅ All data has been successfully imported to Firebase!');
    
    // Show sample of imported data
    const sampleData = wrPredictions.slice(0, 5);
    console.log('\n📋 Sample imported data:');
    sampleData.forEach((player, index) => {
      console.log(`${index + 1}. ${player.player_name} (${player.posteam}) - 2025 Proj: ${player.projected_points} pts, ${player.projected_yards} yds`);
    });

  } catch (error) {
    console.error('Error importing WR predictions:', error);
  } finally {
    process.exit(0);
  }
}

main(); 