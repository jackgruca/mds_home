const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json');
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com';
const COLLECTION_NAME = 'playerGameLogs';
const INPUT_JSON_PATH = path.join(__dirname, './player_game_logs.json');

// --- SCRIPT ---

// Check if service account key exists
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`ERROR: Service account key not found at '${SERVICE_ACCOUNT_PATH}'`);
    console.error('Please download it from your Firebase project settings and place it in the directory.');
    process.exit(1);
}

// Check if input JSON exists
if (!fs.existsSync(INPUT_JSON_PATH)) {
    console.error(`ERROR: Input file not found at '${INPUT_JSON_PATH}'`);
    console.error("Please run the 'get_player_game_logs.R' script first to generate this file.");
    process.exit(1);
}

// Initialize Firebase Admin SDK
const serviceAccount = require(SERVICE_ACCOUNT_PATH);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: DATABASE_URL
});

const db = admin.firestore();
const data = JSON.parse(fs.readFileSync(INPUT_JSON_PATH, 'utf8'));

async function uploadBatchedData() {
    if (!data || data.length === 0) {
        console.log(`No data found in player_game_logs.json. Skipping.`);
        return;
    }

    const collectionRef = db.collection(COLLECTION_NAME);
    console.log(`Starting upload of ${data.length} records to '${COLLECTION_NAME}'...`);

    let batch = db.batch();
    let operations = 0;
    const totalRecords = data.length;

    for (let i = 0; i < totalRecords; i++) {
        const record = data[i];
        // Use the unique game_id field we created in the R script as the document ID
        const docId = record.game_id;
        if (!docId) {
            console.warn(`Skipping record at index ${i} due to missing 'game_id'.`);
            continue;
        }
        const docRef = collectionRef.doc(docId);
        batch.set(docRef, record);
        operations++;

        // Firestore batches are limited to 500 operations.
        // Commit the batch when it's full and start a new one.
        if (operations === 499) {
            console.log(`  Committing batch ${Math.ceil(i / 499)}/${Math.ceil(totalRecords / 499)}...`);
            await batch.commit();
            batch = db.batch();
            operations = 0;
        }
    }

    // Commit any remaining operations in the final batch
    if (operations > 0) {
        console.log(`  Committing final batch...`);
        await batch.commit();
    }

    console.log(`✅ Successfully uploaded ${totalRecords} records to '${COLLECTION_NAME}'.`);
}

uploadBatchedData().catch(error => {
    console.error('Upload failed:', error);
    process.exit(1);
}); 