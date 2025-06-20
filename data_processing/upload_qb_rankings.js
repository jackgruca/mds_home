const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
// IMPORTANT: Place your Firebase service account key JSON file in this directory.
// You can download this from your Firebase project settings:
// Project Settings > Service accounts > Generate new private key
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json'); // Assumes key is in the same directory
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com'; // Replace with your project's database URL if different
const QB_RANKINGS_COLLECTION = 'qbRankings';
const TEAM_QB_TIERS_COLLECTION = 'teamQbTiers';
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
    console.error("Please run the 'get_qb_rankings.R' script first to generate this file.");
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

// Extract individual QB rankings and team QB tiers from the new data structure
const qbRankings = data.individual_qb_rankings || [];
const teamQbTiers = data.team_qb_tiers || [];

// --- DIAGNOSTIC LOG ---
console.log('--- Sample Records from JSON ---');
console.log('Individual QB Rankings:', qbRankings.length > 0 ? qbRankings[0] : 'No data');
console.log('Team QB Tiers:', teamQbTiers.length > 0 ? teamQbTiers[0] : 'No data');
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
        
        // Create document ID based on provided fields
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
    console.log('=== QB RANKINGS & TEAM TIERS UPLOAD ===');
    console.log(`Individual QB Rankings: ${qbRankings.length} records`);
    console.log(`Team QB Tiers: ${teamQbTiers.length} records`);
    console.log('');

    try {
        // Upload Individual QB Rankings
        const qbCollection = db.collection(QB_RANKINGS_COLLECTION);
        await uploadBatchedData(qbCollection, qbRankings, 'Individual QB Rankings', 'player_id', 'season');

        // Upload Team QB Tiers
        const teamCollection = db.collection(TEAM_QB_TIERS_COLLECTION);
        await uploadBatchedData(teamCollection, teamQbTiers, 'Team QB Tiers', 'team', 'season');

        console.log('');
        console.log('🎉 ALL UPLOADS COMPLETE!');
        console.log('Individual QB Rankings: Comprehensive QB metrics and tier classifications');
        console.log('Team QB Tiers: Team-level QB situation rankings with weighted averages');
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