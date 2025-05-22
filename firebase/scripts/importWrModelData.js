const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parser');

// IMPORTANT: Path to your service account key JSON file
const serviceAccount = require('./serviceAccountKey.json'); // Make sure this path is correct

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const collectionName = 'wrModelStats'; // New collection name
const csvFilePath = './wr_model_db.csv'; // Path to your new CSV file

const records = [];

// Helper: Convert value to int, float, or leave as string/null
function parseValue(key, value) {
  if (value === 'NA' || value === '') return null;
  // Int fields
  const intFields = [
    'season', 'numGames', 'seasonYards', 'wr_rank', 'playerYear', 'passOffenseTier', 'qbTier', 'numTD', 'numRec',
    'runOffenseTier', 'numRushTD', 'seasonRushYards', 'height', 'weight', 'draft_number', 'draftround', 'entry_year',
    'bench', 'broad_jump', 'targets', 'receptions', 'air_yards', 'total_yac', 'total_epa', 'explosive_plays', 'total_yards', 'first_downs', 'red_zone_targets'
  ];
  // Float fields
  const floatFields = [
    'tgtShare', 'runShare', 'points', 'forty', 'vertical', 'cone', 'shuttle',
    'avg_epa', 'aDOT', 'explosive_rate', 'yac_per_reception', 'avg_cpoe', 'catch_rate_over_expected', 'explosive_yards_share'
  ];
  if (intFields.includes(key)) {
    const intVal = parseInt(value, 10);
    return isNaN(intVal) ? null : intVal;
  }
  if (floatFields.includes(key)) {
    const floatVal = parseFloat(value);
    return isNaN(floatVal) ? null : floatVal;
  }
  if (key === 'birth_date') {
    const date = new Date(value);
    return isNaN(date.getTime()) ? null : admin.firestore.Timestamp.fromDate(date);
  }
  return value;
}

fs.createReadStream(csvFilePath)
  .pipe(csv())
  .on('data', (data) => {
    // Remove the first unnamed column if present (e.g., "" or index column)
    const processed = {};
    for (const key in data) {
      if (key === '' || key === undefined) continue;
      processed[key] = parseValue(key, data[key]);
    }
    // Only push if receiver_player_id and season are present
    if (processed['receiver_player_id'] && processed['season']) {
      records.push(processed);
    }
  })
  .on('end', async () => {
    console.log(`CSV file successfully processed. Found ${records.length} records.`);
    if (records.length === 0) {
      console.log('No records to import.');
      return;
    }
    // Sanity check first record structure after processing
    if (records.length > 0) {
      console.log('Sample processed record:', JSON.stringify(records[0], null, 2));
    }
    const batchSize = 400;
    for (let i = 0; i < records.length; i += batchSize) {
      const batch = db.batch();
      const end = Math.min(i + batchSize, records.length);
      console.log(`Preparing batch from ${i} to ${end - 1}`);
      for (let j = i; j < end; j++) {
        const record = records[j];
        if (Object.keys(record).length === 0) {
          console.warn(`Skipping empty record at index ${j}`);
          continue;
        }
        // Use a unique doc ID to allow overwrites and prevent duplicates
        const docId = `${record.receiver_player_id}_${record.season}`;
        const docRef = db.collection(collectionName).doc(docId);
        batch.set(docRef, record);
      }
      try {
        await batch.commit();
        console.log(`Batch ${Math.floor(i / batchSize) + 1} committed successfully.`);
      } catch (error) {
        console.error(`Error committing batch ${Math.floor(i / batchSize) + 1}: `, error);
      }
    }
    console.log(`All records have been uploaded to Firestore collection "${collectionName}".`);
  })
  .on('error', (error) => {
    console.error('Error reading CSV file:', error);
  }); 