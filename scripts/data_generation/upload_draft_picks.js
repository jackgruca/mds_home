const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
// IMPORTANT: Place your Firebase service account key JSON file in this directory.
// You can download this from your Firebase project settings:
// Project Settings > Service accounts > Generate new private key
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json'); // Assumes key is in the same directory
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com'; // Replace with your project's database URL if different
const COLLECTION_NAME = 'draftPicks';
const INPUT_JSON_PATH = path.join(__dirname, './draft_picks.json');

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
    console.error("Please run the 'get_draft_picks.R' script first to generate this file.");
    process.exit(1);
}

// Initialize Firebase Admin SDK
const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: DATABASE_URL
});

const db = admin.firestore();
const draftPicks = JSON.parse(fs.readFileSync(INPUT_JSON_PATH, 'utf8'));

// --- DIAGNOSTIC LOG ---
console.log('--- Sample Record from JSON ---');
// Check if draft picks exist and log the first record
if (draftPicks && draftPicks.length > 0) {
  console.log(draftPicks[0]);
  console.log('\n--- Data Structure ---');
  console.log('Available fields:', Object.keys(draftPicks[0]).join(', '));
} else {
  console.log('JSON file is empty or does not contain an array of draft picks.');
}
console.log('-----------------------------');
// --- END DIAGNOSTIC LOG ---

const collectionRef = db.collection(COLLECTION_NAME);

async function uploadDraftPicks() {
    if (!draftPicks || draftPicks.length === 0) {
        console.log('No draft picks found in the JSON file. Exiting.');
        return;
    }

    console.log(`Found ${draftPicks.length} draft pick records to upload to the '${COLLECTION_NAME}' collection.`);
    console.log('This will overwrite existing documents with the same ID.');
    console.log('Document ID format: {year}_{round}_{pick}');

    // Show year range
    const years = [...new Set(draftPicks.map(pick => pick.year))].sort();
    console.log(`Years covered: ${Math.min(...years)} to ${Math.max(...years)}`);

    // Use a batched writer for efficient uploads
    let batch = db.batch();
    let operations = 0;
    let totalRecords = draftPicks.length;
    let successCount = 0;
    let errorCount = 0;

    for (let i = 0; i < totalRecords; i++) {
        const record = draftPicks[i];
        
        try {
            // Create a document ID based on year, round, and pick for uniqueness and sorting
            const docId = `${record.year}_${record.round}_${String(record.pick).padStart(3, '0')}`;
            const docRef = collectionRef.doc(docId);
            
            // Ensure all fields are properly formatted for Firestore
            const cleanRecord = {
                year: parseInt(record.year),
                round: parseInt(record.round),
                pick: parseInt(record.pick),
                player: String(record.player || ''),
                position: String(record.position || 'Unknown'),
                school: String(record.school || 'Unknown'),
                team: String(record.team || 'Unknown'),
                pick_id: String(record.pick_id || docId),
                last_updated: record.last_updated ? new Date(record.last_updated) : new Date()
            };
            
            // Set the data for the document. This will create or overwrite it.
            batch.set(docRef, cleanRecord);
            operations++;
            successCount++;

            // Firestore batches are limited to 500 operations.
            // We commit the batch and start a new one if the limit is reached.
            if (operations === 499) {
                console.log(`Committing batch ${Math.floor(i / 499) + 1}... (${i + 1}/${totalRecords})`);
                await batch.commit();
                batch = db.batch(); // Start a new batch
                operations = 0;
            }
        } catch (error) {
            console.error(`Error processing record ${i + 1}:`, error);
            console.error('Record data:', record);
            errorCount++;
        }
    }

    // Commit any remaining operations in the last batch
    if (operations > 0) {
        console.log('Committing final batch...');
        await batch.commit();
    }

    console.log('---------------------------------');
    console.log('✅ Upload complete!');
    console.log(`Successfully uploaded: ${successCount} records`);
    if (errorCount > 0) {
        console.log(`❌ Errors encountered: ${errorCount} records`);
    }
    console.log(`Total processed: ${totalRecords} records`);
    console.log('Data includes: year, round, pick, player, position, school, team');
    console.log('Collection:', COLLECTION_NAME);
    console.log('---------------------------------');

    // Create indexes if they don't exist (informational message)
    console.log('💡 Recommended Firestore indexes for optimal query performance:');
    console.log('   - year (descending), round (ascending), pick (ascending)');
    console.log('   - team (ascending), year (descending)');
    console.log('   - position (ascending), year (descending)');
    console.log('   Add these in the Firebase Console under Firestore > Indexes');
}

uploadDraftPicks().catch(error => {
    console.error('Error during upload:', error);
    process.exit(1);
});