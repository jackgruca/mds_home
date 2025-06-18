const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
// IMPORTANT: Place your Firebase service account key JSON file in this directory.
// You can download this from your Firebase project settings:
// Project Settings > Service accounts > Generate new private key
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json'); // Assumes key is in the same directory
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com'; // Replace with your project's database URL if different
const COLLECTION_NAME = 'historicalGameData';
const INPUT_JSON_PATH = path.join(__dirname, './betting_data.json');

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
    console.error("Please run the 'get_betting_data.R' script first to generate this file.");
    process.exit(1);
}

// Initialize Firebase Admin SDK
const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: DATABASE_URL
});

const db = admin.firestore();
const gameData = JSON.parse(fs.readFileSync(INPUT_JSON_PATH, 'utf8'));

// --- DIAGNOSTIC LOG ---
console.log('--- Sample Record from JSON ---');
// Check if data exists and log the first record
if (gameData && gameData.length > 0) {
  console.log(gameData[0]);
} else {
  console.log('JSON file is empty or does not contain an array of game data.');
}
console.log('-----------------------------');
// --- END DIAGNOSTIC LOG ---

const collectionRef = db.collection(COLLECTION_NAME);

async function uploadGameData() {
    if (!gameData || gameData.length === 0) {
        console.log('No game data found in the JSON file. Exiting.');
        return;
    }

    console.log(`Found ${gameData.length} historical games to upload to the '${COLLECTION_NAME}' collection.`);
    console.log('This will overwrite existing documents with the same ID.');
    console.log('Data includes game results, betting lines, weather conditions, and venue information.');

    // Use a batched writer for efficient uploads
    let batch = db.batch();
    let operations = 0;
    const totalRecords = gameData.length;

    for (let i = 0; i < totalRecords; i++) {
        const record = gameData[i];
        
        // Use game_id as the document ID for consistency
        const docId = record.game_id;
        
        if (!docId) {
            console.warn(`Skipping record ${i + 1} - missing game_id:`, record);
            continue;
        }
        
        const docRef = collectionRef.doc(docId);
        
        // Set the data for the document. This will create or overwrite it.
        batch.set(docRef, record);
        operations++;

        // Firestore batches are limited to 500 operations.
        // We commit the batch and start a new one if the limit is reached.
        if (operations === 499) {
            console.log(`Committing batch ${Math.floor(i / 499) + 1}/${Math.ceil(totalRecords / 499)}...`);
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
    console.log(`Successfully uploaded ${totalRecords} historical games to Firestore.`);
    console.log('Each record includes game results, betting outcomes, weather data, and venue information.');
    console.log('---------------------------------');
}

uploadGameData().catch(error => {
    console.error('Error during upload:', error);
    process.exit(1);
}); 