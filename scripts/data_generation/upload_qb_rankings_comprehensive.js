const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json');
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com';
const QB_RANKINGS_COLLECTION = 'qb_rankings_comprehensive';
const INPUT_JSON_PATH = path.join(__dirname, './qb_rankings.json');

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
    console.error("Please run the 'qb_rankings.R' script first to generate this file.");
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
console.log('Total QB Rankings:', data.length);
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

async function uploadQBData() {
    console.log('=== QB RANKINGS UPLOAD ===');
    console.log(`QB Rankings: ${data.length} records`);
    console.log('');

    try {
        // Upload QB Rankings
        const qbCollection = db.collection(QB_RANKINGS_COLLECTION);
        await uploadBatchedData(qbCollection, data, 'QB Rankings', 'passer_player_id', 'season');

        console.log('');
        console.log('🎉 ALL UPLOADS COMPLETE!');
        console.log('QB Rankings: Comprehensive QB metrics and tier classifications');
        console.log('Collection: qb_rankings_comprehensive');
        console.log('===========================================');

    } catch (error) {
        console.error('Error during upload:', error);
        throw error;
    }
}

uploadQBData().catch(error => {
    console.error('Upload failed:', error);
    process.exit(1);
});