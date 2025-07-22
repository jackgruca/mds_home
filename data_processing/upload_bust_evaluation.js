const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadBustEvaluationData() {
  try {
    console.log('🚀 Starting bust evaluation data upload...');

    // Load the JSON data files
    console.log('📁 Loading data files...');
    const playerData = JSON.parse(fs.readFileSync('bust_evaluation_data.json', 'utf8'));
    const timelineData = JSON.parse(fs.readFileSync('bust_evaluation_timeline.json', 'utf8'));
    const contextData = JSON.parse(fs.readFileSync('bust_evaluation_context.json', 'utf8'));

    console.log(`📊 Loaded ${playerData.length} players, ${timelineData.length} timeline records, ${contextData.length} context records`);

    // Upload main player data
    console.log('⬆️ Uploading player data...');
    let playerBatch = db.batch();
    let playerCount = 0;

    for (const player of playerData) {
      const docRef = db.collection('bust_evaluation').doc(player.gsis_id);
      playerBatch.set(docRef, {
        ...player,
        last_updated: admin.firestore.FieldValue.serverTimestamp()
      });
      
      playerCount++;
      if (playerCount % 500 === 0) {
        await playerBatch.commit();
        console.log(`  ✅ Uploaded ${playerCount} players`);
        playerBatch = db.batch(); // Create new batch
      }
    }

    if (playerCount % 500 !== 0) {
      await playerBatch.commit();
      console.log(`  ✅ Uploaded ${playerCount} players (final batch)`);
    }

    // Upload timeline data
    console.log('⬆️ Uploading timeline data...');
    let timelineBatch = db.batch();
    let timelineCount = 0;

    for (const record of timelineData) {
      const docRef = db.collection('bust_evaluation_timeline').doc(`${record.gsis_id}_${record.league_year}`);
      timelineBatch.set(docRef, {
        ...record,
        last_updated: admin.firestore.FieldValue.serverTimestamp()
      });
      
      timelineCount++;
      if (timelineCount % 500 === 0) {
        await timelineBatch.commit();
        console.log(`  ✅ Uploaded ${timelineCount} timeline records`);
        timelineBatch = db.batch(); // Create new batch
      }
    }

    if (timelineCount % 500 !== 0) {
      await timelineBatch.commit();
      console.log(`  ✅ Uploaded ${timelineCount} timeline records (final batch)`);
    }

    // Upload context data
    console.log('⬆️ Uploading context data...');
    const contextBatch = db.batch();
    let contextCount = 0;

    for (const context of contextData) {
      const docRef = db.collection('bust_evaluation_context').doc(`${context.position}_round${context.draft_round}`);
      contextBatch.set(docRef, {
        ...context,
        last_updated: admin.firestore.FieldValue.serverTimestamp()
      });
      
      contextCount++;
    }

    await contextBatch.commit();
    console.log(`  ✅ Uploaded ${contextCount} context records`);

    // Create metadata document
    console.log('📝 Creating metadata...');
    await db.collection('bust_evaluation_metadata').doc('info').set({
      total_players: playerData.length,
      total_timeline_records: timelineData.length,
      total_context_records: contextData.length,
      positions: ['QB', 'RB', 'WR', 'TE'],
      draft_rounds: [1, 2, 3, 4, 5, 6, 7],
      seasons_covered: '2010-2024',
      last_updated: admin.firestore.FieldValue.serverTimestamp(),
      bust_categories: ['Steal', 'Met Expectations', 'Disappointing', 'Bust', 'Insufficient Data']
    });

    console.log('✅ Bust evaluation data upload complete!');
    console.log(`📊 Summary:`);
    console.log(`  - Players: ${playerData.length}`);
    console.log(`  - Timeline records: ${timelineData.length}`);
    console.log(`  - Context records: ${contextData.length}`);

    // Log some sample data for verification
    console.log('🔍 Sample players by category:');
    const categoryStats = {};
    playerData.forEach(player => {
      if (!categoryStats[player.bust_category]) {
        categoryStats[player.bust_category] = [];
      }
      if (categoryStats[player.bust_category].length < 3) {
        categoryStats[player.bust_category].push(player.player_name);
      }
    });

    Object.entries(categoryStats).forEach(([category, players]) => {
      console.log(`  ${category}: ${players.join(', ')}`);
    });

  } catch (error) {
    console.error('❌ Error uploading bust evaluation data:', error);
    throw error;
  }
}

// Run the upload
uploadBustEvaluationData()
  .then(() => {
    console.log('🎉 Upload completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Upload failed:', error);
    process.exit(1);
  }); 