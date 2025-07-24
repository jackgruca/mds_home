const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json');
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com';
const PASS_OFFENSE_COLLECTION = 'pass_offense_rankings';
const INPUT_JSON_PATH = path.join(__dirname, './pass_offense_rankings.json');

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
    console.error("Please run the 'pass_offense_rankings.R' script first to generate this file.");
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
console.log('Pass Offense Rankings:', data.length > 0 ? data[0] : 'No data');
console.log('Total records:', data.length);
console.log('----------------------------------');

async function uploadPassOffenseRankings() {
    const batch = db.batch();
    let uploadCount = 0;

    try {
        // First, clear existing data (optional - comment out if you want to keep historical data)
        console.log('Clearing existing pass offense rankings...');
        const existingDocs = await db.collection(PASS_OFFENSE_COLLECTION).get();
        existingDocs.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        // Upload new data
        console.log('Uploading pass offense rankings...');
        data.forEach((ranking, index) => {
            // Create document ID from team and season
            const docId = `${ranking.posteam}_${ranking.season}`;
            const docRef = db.collection(PASS_OFFENSE_COLLECTION).doc(docId);
            
            batch.set(docRef, {
                ...ranking,
                uploadedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            uploadCount++;
        });

        // Commit the batch
        await batch.commit();
        console.log(`✅ Successfully uploaded ${uploadCount} pass offense rankings to Firebase!`);
        
        // Verify upload
        const verification = await db.collection(PASS_OFFENSE_COLLECTION).limit(5).get();
        console.log(`✅ Verification: Found ${verification.size} documents in collection`);
        
        if (verification.size > 0) {
            console.log('Sample uploaded document:', verification.docs[0].data());
        }

    } catch (error) {
        console.error('❌ Error uploading data:', error);
        process.exit(1);
    }
}

// Execute the upload
uploadPassOffenseRankings().then(() => {
    console.log('Upload completed successfully!');
    process.exit(0);
}).catch(error => {
    console.error('Upload failed:', error);
    process.exit(1);
});