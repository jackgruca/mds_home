const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
// IMPORTANT: Place your Firebase service account key JSON file in this directory.
// You can download this from your Firebase project settings:
// Project Settings > Service accounts > Generate new private key
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json'); // Assumes key is in the same directory
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com'; // Replace with your project's database URL if different
const COLLECTION_NAME = 'nflRosters';
const INPUT_JSON_PATH = path.join(__dirname, './roster_data.json');

// --- SCRIPT ---

// Check if service account key exists
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error('❌ Error: Service account key not found at:', SERVICE_ACCOUNT_PATH);
  console.error('Please download your Firebase service account key and place it in the data_processing directory.');
  console.error('You can get this from: Firebase Console > Project Settings > Service accounts > Generate new private key');
  process.exit(1);
}

// Check if roster data JSON exists
if (!fs.existsSync(INPUT_JSON_PATH)) {
  console.error('❌ Error: Roster data JSON not found at:', INPUT_JSON_PATH);
  console.error('Please run get_roster_data.R first to generate the roster data.');
  process.exit(1);
}

// Initialize Firebase Admin SDK
try {
  const serviceAccount = require(SERVICE_ACCOUNT_PATH);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: DATABASE_URL
  });
  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Error initializing Firebase Admin SDK:', error);
  process.exit(1);
}

const db = admin.firestore();

// Main upload function
async function uploadRosterData() {
  try {
    console.log('📁 Reading roster data from:', INPUT_JSON_PATH);
    
    // Read and parse the JSON file
    const jsonData = fs.readFileSync(INPUT_JSON_PATH, 'utf8');
    const rosterData = JSON.parse(jsonData);
    
    console.log('📊 Loaded', Object.keys(rosterData).length, 'roster records');
    
    // Get collection reference
    const collection = db.collection(COLLECTION_NAME);
    
    // Check if collection already has data
    const existingSnapshot = await collection.limit(1).get();
    if (!existingSnapshot.empty) {
      console.log('⚠️  Collection already contains data. This will add to existing data.');
      console.log('   If you want to replace all data, you should delete the collection first.');
    }
    
    // Batch write configuration
    const BATCH_SIZE = 500; // Firestore batch limit is 500
    const records = Object.entries(rosterData);
    const totalRecords = records.length;
    let uploadedCount = 0;
    let batchCount = 0;
    
    console.log('🚀 Starting upload process...');
    console.log(`   Total records to upload: ${totalRecords}`);
    console.log(`   Batch size: ${BATCH_SIZE}`);
    console.log(`   Estimated batches: ${Math.ceil(totalRecords / BATCH_SIZE)}`);
    
    // Process records in batches
    for (let i = 0; i < totalRecords; i += BATCH_SIZE) {
      const batch = db.batch();
      const batchRecords = records.slice(i, i + BATCH_SIZE);
      batchCount++;
      
      console.log(`📦 Processing batch ${batchCount} (${batchRecords.length} records)...`);
      
      for (const [recordId, recordData] of batchRecords) {
        // Create a document reference with auto-generated ID
        const docRef = collection.doc();
        
        // Prepare the data for Firestore
        const firestoreData = {
          ...recordData,
          // Add metadata
          uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
          recordId: recordId
        };
        
        // Add to batch
        batch.set(docRef, firestoreData);
      }
      
      try {
        // Commit the batch
        await batch.commit();
        uploadedCount += batchRecords.length;
        console.log(`✅ Batch ${batchCount} completed. Progress: ${uploadedCount}/${totalRecords} (${Math.round(uploadedCount/totalRecords*100)}%)`);
        
        // Add a small delay between batches to avoid overwhelming Firestore
        if (i + BATCH_SIZE < totalRecords) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
        
      } catch (batchError) {
        console.error(`❌ Error uploading batch ${batchCount}:`, batchError);
        throw batchError;
      }
    }
    
    console.log('\n🎉 Upload completed successfully!');
    console.log(`📊 Final statistics:`);
    console.log(`   Total records uploaded: ${uploadedCount}`);
    console.log(`   Collection name: ${COLLECTION_NAME}`);
    console.log(`   Database: ${DATABASE_URL}`);
    
    // Verify the upload by counting documents
    console.log('\n🔍 Verifying upload...');
    const verificationSnapshot = await collection.get();
    console.log(`✅ Verification complete: ${verificationSnapshot.size} documents found in collection`);
    
    if (verificationSnapshot.size !== uploadedCount) {
      console.log('⚠️  Warning: Document count mismatch. This might indicate partial upload or existing data.');
    }
    
    // Sample a few documents to verify data structure
    console.log('\n📝 Sample uploaded documents:');
    const sampleDocs = verificationSnapshot.docs.slice(0, 2);
    sampleDocs.forEach((doc, index) => {
      console.log(`   Sample ${index + 1}:`, {
        id: doc.id,
        full_name: doc.data().full_name,
        position: doc.data().position,
        team: doc.data().team,
        season: doc.data().season
      });
    });
    
  } catch (error) {
    console.error('❌ Upload failed:', error);
    throw error;
  }
}

// Run the upload
uploadRosterData()
  .then(() => {
    console.log('\n✨ All done! Your NFL roster data is now available in Firestore.');
    console.log('You can now use this data in your Flutter app.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Upload process failed:', error);
    process.exit(1);
  }); 