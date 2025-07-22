const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://mds-home-default-rtdb.firebaseio.com'
});

const db = admin.firestore();

async function testRBData() {
  try {
    console.log('🔍 Testing RB rankings data in Firebase...');

    // Get a few sample records
    const snapshot = await db.collection('rb_rankings')
      .where('season', '==', 2024)
      .limit(5)
      .get();

    if (snapshot.empty) {
      console.log('❌ No RB rankings found for 2024');
      return;
    }

    console.log(`\n📊 Found ${snapshot.docs.length} sample records for 2024:`);
    
    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n${index + 1}. ${data.player_name || 'Unknown'} (${data.team || 'Unknown'})`);
      console.log(`   - myRankNum: ${data.myRankNum}`);
      console.log(`   - tier: ${data.tier}`);
      console.log(`   - yards: ${data.yards}`);
      console.log(`   - total_yards: ${data.total_yards}`);
      console.log(`   - touchdowns: ${data.touchdowns}`);
      console.log(`   - total_tds: ${data.total_tds}`);
      console.log(`   - epa: ${data.epa}`);
      console.log(`   - total_epa: ${data.total_epa}`);
      console.log(`   - rush_share: ${data.rush_share}`);
      console.log(`   - target_share: ${data.target_share}`);
      console.log(`   - explosive_rate: ${data.explosive_rate}`);
      console.log(`   - conversion_rate: ${data.conversion_rate}`);
      console.log(`   - games: ${data.games}`);
      console.log(`   - attempts: ${data.attempts}`);
    });

    // Check field availability across all records
    console.log('\n🔍 Checking field availability across all RB rankings...');
    const allSnapshot = await db.collection('rb_rankings').limit(100).get();
    
    const fieldCounts = {};
    const fieldValues = {};
    
    allSnapshot.docs.forEach(doc => {
      const data = doc.data();
      Object.keys(data).forEach(field => {
        if (!fieldCounts[field]) {
          fieldCounts[field] = 0;
          fieldValues[field] = [];
        }
        fieldCounts[field]++;
        if (fieldValues[field].length < 3 && data[field] != null) {
          fieldValues[field].push(data[field]);
        }
      });
    });

    console.log('\n📋 Field availability summary:');
    const sortedFields = Object.keys(fieldCounts).sort();
    sortedFields.forEach(field => {
      const count = fieldCounts[field];
      const samples = fieldValues[field].slice(0, 3);
      console.log(`   ${field}: ${count} records, samples: [${samples.join(', ')}]`);
    });

    console.log('\n✅ RB data test completed!');

  } catch (error) {
    console.error('❌ Error testing RB data:', error);
  } finally {
    process.exit(0);
  }
}

testRBData(); 