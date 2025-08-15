const admin = require('firebase-admin');

// Initialize Firebase Admin (reuse existing connection if available)
if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://mds-home-default-rtdb.firebaseio.com'
  });
}

const db = admin.firestore();

// Sample RB data based on actual 2024 NFL players
const sampleRBData = [
  { player_name: 'Christian McCaffrey', posteam: 'SF', totalEPA: 15.2, rush_share: 0.65, numYards: 1459, conversion_rate: 0.42, explosive_rate: 0.18, tgt_share: 0.08, numRec: 30 },
  { player_name: 'Josh Jacobs', posteam: 'GB', totalEPA: 12.8, rush_share: 0.58, numYards: 1329, conversion_rate: 0.38, explosive_rate: 0.15, tgt_share: 0.06, numRec: 25 },
  { player_name: 'Derrick Henry', posteam: 'BAL', totalEPA: 11.9, rush_share: 0.62, numYards: 1407, conversion_rate: 0.45, explosive_rate: 0.22, tgt_share: 0.03, numRec: 12 },
  { player_name: 'Saquon Barkley', posteam: 'PHI', totalEPA: 13.1, rush_share: 0.61, numYards: 1838, conversion_rate: 0.41, explosive_rate: 0.19, tgt_share: 0.07, numRec: 33 },
  { player_name: 'Alvin Kamara', posteam: 'NO', totalEPA: 9.8, rush_share: 0.52, numYards: 1141, conversion_rate: 0.39, explosive_rate: 0.16, tgt_share: 0.12, numRec: 52 },
  { player_name: 'Jahmyr Gibbs', posteam: 'DET', totalEPA: 10.2, rush_share: 0.45, numYards: 1101, conversion_rate: 0.43, explosive_rate: 0.17, tgt_share: 0.09, numRec: 42 },
  { player_name: 'Joe Mixon', posteam: 'HOU', totalEPA: 8.9, rush_share: 0.55, numYards: 1173, conversion_rate: 0.37, explosive_rate: 0.14, tgt_share: 0.08, numRec: 31 },
  { player_name: 'Kenneth Walker III', posteam: 'SEA', totalEPA: 7.8, rush_share: 0.59, numYards: 1204, conversion_rate: 0.36, explosive_rate: 0.16, tgt_share: 0.05, numRec: 22 },
  { player_name: 'Bijan Robinson', posteam: 'ATL', totalEPA: 9.1, rush_share: 0.48, numYards: 1456, conversion_rate: 0.40, explosive_rate: 0.15, tgt_share: 0.11, numRec: 58 },
  { player_name: 'De\'Von Achane', posteam: 'MIA', totalEPA: 8.3, rush_share: 0.42, numYards: 906, conversion_rate: 0.44, explosive_rate: 0.21, tgt_share: 0.10, numRec: 48 },
  { player_name: 'Breece Hall', posteam: 'NYJ', totalEPA: 6.9, rush_share: 0.51, numYards: 1004, conversion_rate: 0.35, explosive_rate: 0.13, tgt_share: 0.09, numRec: 41 },
  { player_name: 'Jonathan Taylor', posteam: 'IND', totalEPA: 7.2, rush_share: 0.56, numYards: 1110, conversion_rate: 0.38, explosive_rate: 0.14, tgt_share: 0.04, numRec: 18 },
  { player_name: 'Aaron Jones', posteam: 'MIN', totalEPA: 8.1, rush_share: 0.49, numYards: 1138, conversion_rate: 0.39, explosive_rate: 0.16, tgt_share: 0.08, numRec: 37 },
  { player_name: 'Tony Pollard', posteam: 'TEN', totalEPA: 6.8, rush_share: 0.53, numYards: 1020, conversion_rate: 0.36, explosive_rate: 0.15, tgt_share: 0.07, numRec: 29 },
  { player_name: 'James Cook', posteam: 'BUF', totalEPA: 7.9, rush_share: 0.47, numYards: 1009, conversion_rate: 0.41, explosive_rate: 0.17, tgt_share: 0.06, numRec: 27 },
  { player_name: 'Kyren Williams', posteam: 'LA', totalEPA: 8.6, rush_share: 0.54, numYards: 1144, conversion_rate: 0.40, explosive_rate: 0.14, tgt_share: 0.05, numRec: 21 },
  { player_name: 'Rachaad White', posteam: 'TB', totalEPA: 6.2, rush_share: 0.46, numYards: 990, conversion_rate: 0.34, explosive_rate: 0.12, tgt_share: 0.08, numRec: 39 },
  { player_name: 'Rhamondre Stevenson', posteam: 'NE', totalEPA: 5.8, rush_share: 0.52, numYards: 892, conversion_rate: 0.33, explosive_rate: 0.11, tgt_share: 0.07, numRec: 32 },
  { player_name: 'Travis Etienne', posteam: 'JAX', totalEPA: 6.1, rush_share: 0.50, numYards: 980, conversion_rate: 0.35, explosive_rate: 0.13, tgt_share: 0.09, numRec: 41 },
  { player_name: 'David Montgomery', posteam: 'DET', totalEPA: 7.3, rush_share: 0.41, numYards: 775, conversion_rate: 0.39, explosive_rate: 0.12, tgt_share: 0.06, numRec: 28 },
];

async function importSampleRBData() {
  try {
    const collection = db.collection('rb_rankings');
    
    // Clear existing data
    console.log('Clearing existing RB rankings...');
    const existingDocs = await collection.get();
    const batch = db.batch();
    existingDocs.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // Calculate tiers and rankings
    const processedData = sampleRBData.map((rb, index) => ({
      ...rb,
      season: '2024',
      rb_tier: Math.ceil((index + 1) / 4), // 4 players per tier
      myRankNum: index + 1,
      rb_rank: index + 1,
    }));

    // Import new data
    for (let i = 0; i < processedData.length; i += 10) {
      const batch = db.batch();
      const chunk = processedData.slice(i, i + 10);
      
      chunk.forEach(rb => {
        const docRef = collection.doc();
        batch.set(docRef, rb);
      });
      
      await batch.commit();
      console.log(`Imported batch ${Math.floor(i / 10) + 1}/${Math.ceil(processedData.length / 10)}`);
    }

    console.log(`Successfully imported ${processedData.length} RB rankings to Firestore`);
  } catch (error) {
    console.error('Error importing RB rankings:', error);
  }
}

// Run the import
if (require.main === module) {
  importSampleRBData()
    .then(() => {
      console.log('RB import completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('RB import failed:', error);
      process.exit(1);
    });
}

module.exports = { importSampleRBData }; 