const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json');
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com';
const WR_RANKINGS_COLLECTION = 'wr_rankings_comprehensive';
const INPUT_JSON_PATH = path.join(__dirname, './wr_rankings.json');

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
    console.error("Please run the 'wr_rankings.R' script first to generate this file.");
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

// --- DIAGNOSTIC LOG ---
console.log('--- Sample Records from JSON ---');
console.log('Total WR Rankings:', data.length);
console.log('Sample record:', data.length > 0 ? data[0] : 'No data');
console.log('----------------------------------');

async function uploadBatchedData(collection, data, collectionName, idField1, idField2) {
    if (!data || data.length === 0) {
        console.log(`No ${collectionName} found. Skipping.`);
        return;
    }

    console.log(`Uploading ${data.length} ${collectionName} records...`);
    
    let batch = db.batch();
    let operations = 0;
    const totalRecords = data.length;

    for (let i = 0; i < totalRecords; i++) {
        const record = data[i];
        
        // Create document ID based on provided fields (player_id and season)
        const docId = `${record[idField1]}_${record[idField2]}`;
        const docRef = collection.doc(docId);
        
        batch.set(docRef, record);
        operations++;

        // Firestore batches are limited to 500 operations
        if (operations === 499) {
            console.log(`  Committing batch ${Math.floor(i / 499) + 1}/${Math.ceil(totalRecords / 499)}...`);
            await batch.commit();
            batch = db.batch();
            operations = 0;
        }
    }

    // Commit any remaining operations
    if (operations > 0) {
        console.log(`  Committing final batch...`);
        await batch.commit();
    }

    console.log(`✅ Successfully uploaded ${totalRecords} ${collectionName} records.`);
}

async function uploadWRData() {
    console.log('=== WR RANKINGS UPLOAD ===');
    console.log(`WR Rankings: ${data.length} records`);
    console.log('');

    try {
        // Upload WR Rankings
        const wrCollection = db.collection(WR_RANKINGS_COLLECTION);
        await uploadBatchedData(wrCollection, data, 'WR Rankings', 'receiver_player_id', 'season');

        console.log('');
        console.log('🎉 ALL UPLOADS COMPLETE!');
        console.log('WR Rankings: Comprehensive WR metrics and tier classifications');
        console.log('Collection: wr_rankings_comprehensive');
        console.log('===========================================');

    } catch (error) {
        console.error('Error during upload:', error);
        throw error;
    }
}

uploadWRData().catch(error => {
    console.error('Upload failed:', error);
    process.exit(1);
});