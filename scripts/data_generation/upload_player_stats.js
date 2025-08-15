const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
// IMPORTANT: Place your Firebase service account key JSON file in this directory.
// You can download this from your Firebase project settings:
// Project Settings > Service accounts > Generate new private key
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json'); // Assumes key is in the same directory
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com'; // Replace with your project's database URL if different
const COLLECTION_NAME = 'playerSeasonStats';
const INPUT_JSON_PATH = path.join(__dirname, './player_stats.json');

// --- SCRIPT ---

// Check if service account key exists
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`ERROR: Service account key not found at '${SERVICE_ACCOUNT_PATH}'`);
    console.error('Please download it from your Firebase project settings and place it in the same directory as this script.');
    process.exit(1);
}

// Check if input JSON exists
if (!fs.existsSync(INPUT_JSON_PATH)) {
    console.error(`ERROR: Input file not found at '${INPUT_JSON_PATH}'`);
    console.error("Please run the 'get_player_season_stats.R' script first to generate this file.");
    process.exit(1);
}

// Initialize Firebase Admin SDK
const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: DATABASE_URL
});

const db = admin.firestore();
const stats = JSON.parse(fs.readFileSync(INPUT_JSON_PATH, 'utf8'));

// --- DIAGNOSTIC LOG ---
console.log('--- Sample Record from JSON ---');
// Check if stats exist and log the first record
if (stats && stats.length > 0) {
  console.log(stats[0]);
} else {
  console.log('JSON file is empty or does not contain an array of stats.');
}
console.log('-----------------------------');
// --- END DIAGNOSTIC LOG ---

const collectionRef = db.collection(COLLECTION_NAME);

async function uploadStats() {
    if (!stats || stats.length === 0) {
        console.log('No stats found in the JSON file. Exiting.');
        return;
    }

    console.log(`Found ${stats.length} records to upload to the '${COLLECTION_NAME}' collection.`);
    console.log('This will overwrite existing documents with the same ID.');
    console.log('Data now includes NFL NextGen stats for passing, rushing, and receiving.');

    // Use a batched writer for efficient uploads
    let batch = db.batch();
    let operations = 0;
    const totalRecords = stats.length;

    for (let i = 0; i < totalRecords; i++) {
        const record = stats[i];
        
        // Create a custom document ID based on player_id and season for consistency
        const docId = `${record.player_id}_${record.season}`;
        const docRef = collectionRef.doc(docId);
        
        // Set the data for the document. This will create or overwrite it.
        batch.set(docRef, record);
        operations++;

        // Firestore batches are limited to 500 operations.
        // We commit the batch and start a new one if the limit is reached.
        if (operations === 499) {
            console.log(`Committing batch ${i + 1}/${totalRecords}...`);
            await batch.commit();
            batch = db.batch(); // Start a new batch
            operations = 0;
        }
    }

    // Commit any remaining operations in the last batch
    if (operations > 0) {
        console.log('Committing final batch...');
        await batch.commit();
    }

    console.log('---------------------------------');
    console.log('✅ Upload complete!');
    console.log(`Successfully uploaded ${totalRecords} records to Firestore.`);
    console.log('Each record now includes traditional stats and NextGen stats where available.');
    console.log('---------------------------------');
}

uploadStats().catch(error => {
    console.error('Error during upload:', error);
    process.exit(1);
}); 