const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json');
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com';
const COLLECTION_NAME = 'bettingData';
const INPUT_JSON_PATH = path.join(__dirname, './betting_data.json');

// --- SCRIPT ---

// Check if service account key exists
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`ERROR: Service account key not found at '${SERVICE_ACCOUNT_PATH}'`);
    console.error('Please download it from your Firebase project settings and place it in the `data_processing` directory.');
    process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: DATABASE_URL
});

const db = admin.firestore();

// Read the JSON file
let bettingData;
try {
    const jsonData = fs.readFileSync(INPUT_JSON_PATH, 'utf8');
    bettingData = JSON.parse(jsonData);
} catch (error) {
    console.error(`Error reading or parsing ${INPUT_JSON_PATH}:`, error);
    process.exit(1);
}

if (!Array.isArray(bettingData)) {
    console.error('Error: The parsed JSON data is not an array. Please ensure it is a JSON array of objects.');
    process.exit(1);
}

// Function to upload data in batches
async function uploadInBatches() {
    console.log(`Starting upload of ${bettingData.length} records to the '${COLLECTION_NAME}' collection...`);
    
    // Firestore allows a maximum of 500 operations in a single batch.
    const batchSize = 500;
    let successfulUploads = 0;

    for (let i = 0; i < bettingData.length; i += batchSize) {
        const batch = db.batch();
        const chunk = bettingData.slice(i, i + batchSize);
        
        chunk.forEach(record => {
            // Use game_id as the document ID
            if (record.game_id) {
                const docRef = db.collection(COLLECTION_NAME).doc(record.game_id);
                batch.set(docRef, record);
            } else {
                console.warn('Skipping record without game_id:', record);
            }
        });
        
        try {
            await batch.commit();
            successfulUploads += chunk.length;
            console.log(`Successfully uploaded batch ${Math.floor(i / batchSize) + 1} of ${Math.ceil(bettingData.length / batchSize)}.`);
        } catch (error) {
            console.error(`Error committing batch ${Math.floor(i / batchSize) + 1}:`, error);
        }
    }

    console.log(`\nUpload complete. ${successfulUploads} records were processed.`);
}

uploadInBatches().catch(error => {
    console.error('An unexpected error occurred during the upload process:', error);
}); 