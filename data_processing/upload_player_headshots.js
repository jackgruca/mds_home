// data_processing/upload_player_headshots.js

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const db = admin.firestore();

// Configuration
const INPUT_FILE = 'player_headshots.json';
const COLLECTION_NAME = 'playerHeadshots';
const BATCH_SIZE = 500; // Firestore batch limit

console.log('🏈 NFL Player Headshots Upload Script');
console.log('=' * 50);

async function uploadPlayerHeadshots() {
  try {
    // Check if input file exists
    if (!fs.existsSync(INPUT_FILE)) {
      throw new Error(`Input file ${INPUT_FILE} not found. Please run get_player_headshots.R first.`);
    }

    console.log(`📁 Reading data from ${INPUT_FILE}...`);
    const rawData = fs.readFileSync(INPUT_FILE, 'utf8');
    const headshotData = JSON.parse(rawData);
    
    const playerIds = Object.keys(headshotData);
    console.log(`📊 Found ${playerIds.length} player records to upload`);

    // Validate data structure
    console.log('🔍 Validating data structure...');
    const samplePlayer = headshotData[playerIds[0]];
    const requiredFields = ['player_id', 'full_name', 'headshot_url', 'position', 'team'];
    const missingFields = requiredFields.filter(field => !(field in samplePlayer));
    
    if (missingFields.length > 0) {
      throw new Error(`Missing required fields in data: ${missingFields.join(', ')}`);
    }
    console.log('✅ Data structure validation passed');

    // Show sample data
    console.log('\n📋 Sample player record:');
    console.log(`   Name: ${samplePlayer.full_name}`);
    console.log(`   Position: ${samplePlayer.position}`);
    console.log(`   Team: ${samplePlayer.team}`);
    console.log(`   Headshot URL: ${samplePlayer.headshot_url.substring(0, 50)}...`);

    // Upload in batches
    console.log(`\n🚀 Starting upload in batches of ${BATCH_SIZE}...`);
    const totalBatches = Math.ceil(playerIds.length / BATCH_SIZE);
    let uploadCount = 0;
    let errorCount = 0;

    for (let i = 0; i < totalBatches; i++) {
      const batchStart = i * BATCH_SIZE;
      const batchEnd = Math.min(batchStart + BATCH_SIZE, playerIds.length);
      const batchPlayerIds = playerIds.slice(batchStart, batchEnd);
      
      console.log(`\n📦 Processing batch ${i + 1}/${totalBatches} (${batchPlayerIds.length} records)...`);
      
      const batch = db.batch();
      
      for (const playerId of batchPlayerIds) {
        try {
          const playerData = headshotData[playerId];
          
          // Validate player data
          if (!playerData.player_id || !playerData.headshot_url) {
            console.log(`⚠️  Skipping invalid record: ${playerData.full_name || 'Unknown'}`);
            errorCount++;
            continue;
          }

          // Use player_id as document ID for efficient lookups
          const docRef = db.collection(COLLECTION_NAME).doc(playerData.player_id);
          
          // Prepare document data
          const documentData = {
            // Core player info
            player_id: playerData.player_id,
            full_name: playerData.full_name || '',
            first_name: playerData.first_name || '',
            last_name: playerData.last_name || '',
            position: playerData.position || '',
            team: playerData.team || '',
            season: playerData.season || 0,
            
            // Headshot URL
            headshot_url: playerData.headshot_url,
            
            // Lookup keys for flexible searching
            lookup_name: playerData.lookup_name || playerData.full_name.toLowerCase(),
            lookup_name_no_punct: playerData.lookup_name_no_punct || '',
            lookup_key: playerData.lookup_key || '',
            
            // Additional player info (if available)
            jersey_number: playerData.jersey_number || null,
            height: playerData.height || '',
            weight: playerData.weight || null,
            college: playerData.college || '',
            years_exp: playerData.years_exp || null,
            birth_date: playerData.birth_date || '',
            
            // Metadata
            data_source: playerData.data_source || 'nflreadr',
            last_updated: admin.firestore.Timestamp.fromDate(new Date(playerData.last_updated || new Date())),
            processing_notes: playerData.processing_notes || '',
            
            // Upload metadata
            uploaded_at: admin.firestore.Timestamp.now(),
            upload_batch: i + 1
          };

          batch.set(docRef, documentData);
          uploadCount++;
          
        } catch (error) {
          console.error(`❌ Error preparing record for ${playerId}:`, error.message);
          errorCount++;
        }
      }
      
      // Commit batch
      try {
        await batch.commit();
        console.log(`✅ Batch ${i + 1} uploaded successfully (${batchPlayerIds.length} records)`);
      } catch (error) {
        console.error(`❌ Error uploading batch ${i + 1}:`, error.message);
        errorCount += batchPlayerIds.length;
      }
      
      // Small delay between batches to avoid rate limiting
      if (i < totalBatches - 1) {
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }

    // Upload summary
    console.log('\n' + '=' * 50);
    console.log('🎉 Upload Complete!');
    console.log(`✅ Successfully uploaded: ${uploadCount} records`);
    console.log(`❌ Errors encountered: ${errorCount} records`);
    console.log(`📊 Total processed: ${uploadCount + errorCount} records`);
    console.log(`🏟️  Collection: ${COLLECTION_NAME}`);
    console.log(`📅 Upload completed at: ${new Date().toISOString()}`);

    // Create indexes for efficient querying
    console.log('\n🔍 Creating database indexes...');
    await createIndexes();
    
    // Verify upload
    console.log('\n🔍 Verifying upload...');
    await verifyUpload();
    
    console.log('\n✨ All done! Player headshots are ready for use in the Flutter app.');
    
  } catch (error) {
    console.error('💥 Upload failed:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

async function createIndexes() {
  try {
    // Note: Firestore indexes are typically created through the Firebase Console
    // or firestore.indexes.json file. This is just for documentation.
    console.log('📝 Recommended indexes to create in Firebase Console:');
    console.log('   1. Collection: playerHeadshots, Fields: lookup_name (Ascending)');
    console.log('   2. Collection: playerHeadshots, Fields: position (Ascending), team (Ascending)');
    console.log('   3. Collection: playerHeadshots, Fields: team (Ascending), position (Ascending)');
    console.log('   4. Collection: playerHeadshots, Fields: lookup_name_no_punct (Ascending)');
    console.log('✅ Index recommendations logged');
  } catch (error) {
    console.error('⚠️ Error with index setup:', error.message);
  }
}

async function verifyUpload() {
  try {
    // Get total count
    const snapshot = await db.collection(COLLECTION_NAME).count().get();
    const totalCount = snapshot.data().count;
    
    console.log(`📊 Verification: ${totalCount} documents in ${COLLECTION_NAME} collection`);
    
    // Test a few queries
    console.log('🧪 Testing sample queries...');
    
    // Test 1: Get a random player
    const randomPlayerSnapshot = await db.collection(COLLECTION_NAME).limit(1).get();
    if (!randomPlayerSnapshot.empty) {
      const randomPlayer = randomPlayerSnapshot.docs[0].data();
      console.log(`   ✅ Sample player: ${randomPlayer.full_name} (${randomPlayer.position})`);
    }
    
    // Test 2: Count by position
    const qbSnapshot = await db.collection(COLLECTION_NAME)
      .where('position', '==', 'QB')
      .count()
      .get();
    console.log(`   ✅ Quarterbacks in database: ${qbSnapshot.data().count}`);
    
    // Test 3: Test lookup query
    const lookupSnapshot = await db.collection(COLLECTION_NAME)
      .where('lookup_name', '>=', 'aaron')
      .where('lookup_name', '<', 'aaron\uf8ff')
      .limit(1)
      .get();
    if (!lookupSnapshot.empty) {
      const lookupPlayer = lookupSnapshot.docs[0].data();
      console.log(`   ✅ Lookup test: Found ${lookupPlayer.full_name}`);
    }
    
    console.log('✅ Verification complete - database is ready!');
    
  } catch (error) {
    console.error('⚠️ Verification failed:', error.message);
  }
}

// Handle script termination
process.on('SIGINT', () => {
  console.log('\n\n⚠️ Upload interrupted by user');
  process.exit(0);
});

process.on('unhandledRejection', (error) => {
  console.error('💥 Unhandled rejection:', error);
  process.exit(1);
});

// Run the upload
if (require.main === module) {
  uploadPlayerHeadshots()
    .then(() => {
      console.log('\n🎊 Script completed successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Script failed:', error.message);
      process.exit(1);
    });
}

module.exports = { uploadPlayerHeadshots };