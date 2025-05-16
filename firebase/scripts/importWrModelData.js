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
let idCounter = 1; // For the first unnamed column, if needed, though Firestore will generate IDs

// Function to sanitize keys (remove/replace invalid characters for Firestore field names)
function sanitizeKey(key) {
  if (!key) return '';
  return key.replace(/[^a-zA-Z0-9_]/g, '_'); // Replace invalid chars with underscore
}

// Function to process each row
function processRecord(record) {
  const processed = {};
  for (const key in record) {
    const sanitized = sanitizeKey(key);
    if (!sanitized && key !== '') continue; // Skip empty original keys, but allow the first auto-generated one if not empty

    let value = record[key];

    // Handle "NA" or empty strings for specific types
    if (value === 'NA' || value === '') {
      // For numeric fields, decide if they should be null, 0, or skipped
      // For boolean fields, decide if they should be null, false, or skipped
      // Based on wr_model_db.csv structure:
      if (['season', 'numGames', 'seasonYards', 'wr_rank', 'playerYear', 'passOffenseTier', 'qbTier', 'numTD', 'numRec', 'runOffenseTier', 'numRushTD', 'seasonRushYards'].includes(sanitized)) {
        value = null; // Or 0 if that's more appropriate for your use case
      } else if (['tgtShare', 'runShare', 'points'].includes(sanitized)) {
        value = null; // Or 0.0
      } else {
        value = null; // Default to null for other empty/NA string fields
      }
    }

    // Type conversions
    if (value !== null) {
      if (['season', 'numGames', 'seasonYards', 'wr_rank', 'playerYear', 'passOffenseTier', 'qbTier', 'numTD', 'numRec', 'runOffenseTier', 'numRushTD', 'seasonRushYards'].includes(sanitized)) {
        const intVal = parseInt(value, 10);
        processed[sanitized] = isNaN(intVal) ? null : intVal;
      } else if (['tgtShare', 'runShare', 'points'].includes(sanitized)) {
        const floatVal = parseFloat(value);
        processed[sanitized] = isNaN(floatVal) ? null : floatVal;
      } else {
        processed[sanitized] = value; // Default to string
      }
    } else {
      processed[sanitized] = null;
    }
  }
  // The first column "" from CSV is ignored as we are not using it for specific ID.
  // Firestore will auto-generate document IDs.
  // If you had a unique ID in the CSV you wanted to use, you'd set it here.
  // e.g., if 'receiver_player_id' and 'season' make a unique combo:
  // const docId = `${processed.receiver_player_id}_${processed.season}`;
  // return { id: docId, data: processed };
  return processed;
}

fs.createReadStream(csvFilePath)
  .pipe(csv({
    mapHeaders: ({ header, index }) => sanitizeKey(header.trim()), // Sanitize headers directly
    mapValues: ({ header, index, value }) => value === 'NA' || value === '' ? null : value // Handle NA early
  }))
  .on('data', (data) => {
    // The first column "" is often an artifact of CSV export (like row numbers).
    // csv-parser might read it as a key (e.g. '_1' or an empty string if not sanitized).
    // We ensure it's handled by processRecord or ignored if the key becomes empty.
    const recordToPush = processRecord(data);
    // Remove the empty key if it was generated from the first unnamed column
    delete recordToPush[''];
    if (Object.keys(recordToPush).length > 0) { // Ensure record is not empty
        records.push(recordToPush);
    }
  })
  .on('end', async () => {
    console.log('CSV file successfully processed. Found ${records.length} records.');
    if (records.length === 0) {
      console.log('No records to import.');
      return;
    }

    // Sanity check first record structure after processing
    if (records.length > 0) {
        console.log('Sample processed record:', JSON.stringify(records[0], null, 2));
    }

    const batchSize = 400; // Firestore batch limit is 500 operations
    for (let i = 0; i < records.length; i += batchSize) {
      const batch = db.batch();
      const end = Math.min(i + batchSize, records.length);
      console.log(`Preparing batch from ${i} to ${end -1}`);

      for (let j = i; j < end; j++) {
        const record = records[j];
        if (Object.keys(record).length === 0) {
            console.warn(`Skipping empty record at index ${j}`);
            continue;
        }
        // Let Firestore auto-generate document IDs
        const docRef = db.collection(collectionName).doc();
        batch.set(docRef, record);
      }

      try {
        await batch.commit();
        console.log(`Batch ${Math.floor(i / batchSize) + 1} committed successfully.`);
      } catch (error) {
        console.error(`Error committing batch ${Math.floor(i / batchSize) + 1}: `, error);
        // Potentially add retry logic or save failed records
      }
      // Optional: Add a small delay to avoid hitting rate limits, though usually not needed for a one-time import.
      // await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log('All records have been uploaded to Firestore collection "${collectionName}".');
  })
  .on('error', (error) => {
    console.error('Error reading CSV file:', error);
  }); 