const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parser');

// --- START CONFIGURATION ---
// 1. Replace with the path to your Firebase service account key JSON file
// e.g., const serviceAccount = require('./serviceAccountKey.json');
const serviceAccount = require('./serviceAccountKey.json'); // IMPORTANT: Update this path

// 2. Replace with the path to your CSV file
const csvFilePath = './historical_nfl_matchups.csv'; // IMPORTANT: Update this path if your CSV is elsewhere, e.g., '../../assets/data/historical_nfl_matchups.csv'

// 3. Name of the Firestore collection to import data into
const collectionName = 'historicalMatchups';
// --- END CONFIGURATION ---

// Initialize Firebase Admin SDK
try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  if (error.code === 'app/duplicate-app') {
    console.warn("Firebase app already initialized. Using existing app.");
    admin.app(); // Get the already initialized app
  } else {
    console.error("Firebase Admin SDK initialization error:", error);
    process.exit(1);
  }
}

const db = admin.firestore();
const results = [];

// Check if CSV file exists
if (!fs.existsSync(csvFilePath)) {
  console.error(`Error: CSV file not found at ${csvFilePath}`);
  console.error("Please ensure the path in 'csvFilePath' is correct.");
  process.exit(1);
}

fs.createReadStream(csvFilePath)
  .pipe(csv())
  .on('data', (data) => results.push(data))
  .on('end', async () => {
    if (results.length === 0) {
      console.log("No data found in CSV file. Exiting.");
      return;
    }
    console.log(`CSV file successfully processed. Found ${results.length} records.`);
    console.log(`Starting import to Firestore collection: ${collectionName}`);

    const batchSize = 450; // Firestore batch write limit is 500 operations.
    let batch = db.batch();
    let operationsInBatch = 0;
    let totalImportedCount = 0;

    for (let i = 0; i < results.length; i++) {
      const record = results[i];
      const processedRecord = {};

      // Process each field: try to convert to number, handle NA/empty strings, parse dates
      for (const keyInRecord in record) {
        // Ensure we are processing own properties and not from prototype chain
        if (Object.prototype.hasOwnProperty.call(record, keyInRecord)) {
            let value = record[keyInRecord];

            // Sanitize key (Firestore field names cannot contain certain characters like '.' or be empty)
            let sanitizedKey = keyInRecord.replace(/\./g, '_').trim();
            if (sanitizedKey === '') {
                // Skip empty keys or assign a placeholder if necessary
                // For now, we skip if the original key was also empty or just problematic
                if (keyInRecord.trim() === '') continue;
                sanitizedKey = '_empty_key_'; // Placeholder for keys that become empty after sanitization but weren't originally
            }

            if (value === 'NA' || value === '' || value === undefined) {
              processedRecord[sanitizedKey] = null;
            } else if (!isNaN(value) && value.trim() !== '') { // Check if it's a number
              processedRecord[sanitizedKey] = Number(value);
            } else if (sanitizedKey === 'Date' && value) { // Convert 'Date' field to Firestore Timestamp
                const dateParts = value.split('-');
                if (dateParts.length === 3) {
                    const year = parseInt(dateParts[0], 10);
                    const month = parseInt(dateParts[1], 10) -1; // JS months are 0-indexed
                    const day = parseInt(dateParts[2], 10);
                    if (!isNaN(year) && !isNaN(month) && !isNaN(day)) {
                         processedRecord[sanitizedKey] = admin.firestore.Timestamp.fromDate(new Date(Date.UTC(year, month, day)));
                    } else {
                        processedRecord[sanitizedKey] = value; // fallback to string if parsing fails
                    }
                } else {
                     processedRecord[sanitizedKey] = value; // fallback if not YYYY-MM-DD
                }
            }
            else {
              processedRecord[sanitizedKey] = value;
            }
        }
      }
      
      // Remove the empty key that might come from the first unnamed CSV column if it exists
      if (Object.prototype.hasOwnProperty.call(processedRecord, '')) {
          delete processedRecord[''];
      }
       if (Object.prototype.hasOwnProperty.call(processedRecord, '_empty_key_') && !results[i]['']){
          // if _empty_key_ was a placeholder for a truly empty original key, remove it or handle as needed
          // this check is a bit redundant if empty keys are skipped above
       }

      if (Object.keys(processedRecord).length === 0) {
        // Skip record if it's empty after processing (e.g. was just an empty line in CSV or only unnamed columns)
        totalImportedCount++; // Account for it in total processed if desired, or just skip silently
        console.warn(`Record at index ${i} is empty after processing. Skipping.`);
        continue;
      }

      const docRef = db.collection(collectionName).doc(); // Auto-generate document ID
      batch.set(docRef, processedRecord);
      operationsInBatch++;
      totalImportedCount++;

      if (operationsInBatch >= batchSize || i === results.length - 1) {
        if (operationsInBatch === 0) { // Nothing to commit (e.g. last records were empty)
            if ( i === results.length -1) break; // end of loop
            else continue; // continue to next iteration if not end of loop
        }
        try {
          await batch.commit();
          console.log(`Batch of ${operationsInBatch} records committed. Total records processed so far: ${totalImportedCount}`);
          batch = db.batch(); // Reset batch
          operationsInBatch = 0;
        } catch (error) {
          console.error(`Error committing batch (around record index ${i - operationsInBatch + 1} to ${i}):`, error);
          if (i < results.length -1) {
             batch = db.batch(); 
             operationsInBatch = 0;
          } else {
            console.error("Error on final batch. Some records may not have been imported.");
            process.exit(1); 
          }
        }
      }
    }
    console.log(`Import finished. ${totalImportedCount} records processed. Check logs for committed batches and any errors.`);
  })
  .on('error', (error) => {
    console.error('Error reading or parsing CSV file:', error);
    process.exit(1);
  }); 