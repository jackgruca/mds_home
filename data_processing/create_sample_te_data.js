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

// Sample TE data based on actual 2024 NFL players
const sampleTEData = [
  { player_name: 'Travis Kelce', posteam: 'KC', totalEPA: 12.8, tgt_share: 0.18, numYards: 823, conversion_rate: 0.44, explosive_rate: 0.16, avg_separation: 2.8, catch_percentage: 0.89 },
  { player_name: 'George Kittle', posteam: 'SF', totalEPA: 11.2, tgt_share: 0.16, numYards: 1020, conversion_rate: 0.42, explosive_rate: 0.18, avg_separation: 2.6, catch_percentage: 0.87 },
  { player_name: 'Mark Andrews', posteam: 'BAL', totalEPA: 10.1, tgt_share: 0.15, numYards: 673, conversion_rate: 0.39, explosive_rate: 0.14, avg_separation: 2.4, catch_percentage: 0.82 },
  { player_name: 'Trey McBride', posteam: 'ARI', totalEPA: 9.8, tgt_share: 0.19, numYards: 825, conversion_rate: 0.41, explosive_rate: 0.12, avg_separation: 2.7, catch_percentage: 0.85 },
  { player_name: 'Sam LaPorta', posteam: 'DET', totalEPA: 9.2, tgt_share: 0.14, numYards: 889, conversion_rate: 0.43, explosive_rate: 0.15, avg_separation: 2.5, catch_percentage: 0.86 },
  { player_name: 'Brock Bowers', posteam: 'LV', totalEPA: 8.9, tgt_share: 0.17, numYards: 1194, conversion_rate: 0.40, explosive_rate: 0.13, avg_separation: 2.9, catch_percentage: 0.91 },
  { player_name: 'Evan Engram', posteam: 'JAX', totalEPA: 7.1, tgt_share: 0.16, numYards: 630, conversion_rate: 0.38, explosive_rate: 0.11, avg_separation: 2.3, catch_percentage: 0.80 },
  { player_name: 'Kyle Pitts', posteam: 'ATL', totalEPA: 6.8, tgt_share: 0.13, numYards: 667, conversion_rate: 0.36, explosive_rate: 0.14, avg_separation: 2.8, catch_percentage: 0.78 },
  { player_name: 'Dallas Goedert', posteam: 'PHI', totalEPA: 7.3, tgt_share: 0.12, numYards: 441, conversion_rate: 0.40, explosive_rate: 0.13, avg_separation: 2.4, catch_percentage: 0.83 },
  { player_name: 'David Njoku', posteam: 'CLE', totalEPA: 6.9, tgt_share: 0.14, numYards: 882, conversion_rate: 0.37, explosive_rate: 0.12, avg_separation: 2.5, catch_percentage: 0.81 },
  { player_name: 'T.J. Hockenson', posteam: 'MIN', totalEPA: 6.2, tgt_share: 0.13, numYards: 494, conversion_rate: 0.39, explosive_rate: 0.10, avg_separation: 2.3, catch_percentage: 0.84 },
  { player_name: 'Jake Ferguson', posteam: 'DAL', totalEPA: 5.8, tgt_share: 0.11, numYards: 423, conversion_rate: 0.35, explosive_rate: 0.09, avg_separation: 2.2, catch_percentage: 0.79 },
  { player_name: 'Jonnu Smith', posteam: 'MIA', totalEPA: 7.4, tgt_share: 0.15, numYards: 623, conversion_rate: 0.41, explosive_rate: 0.15, avg_separation: 2.6, catch_percentage: 0.85 },
  { player_name: 'Pat Freiermuth', posteam: 'PIT', totalEPA: 5.9, tgt_share: 0.12, numYards: 523, conversion_rate: 0.36, explosive_rate: 0.11, avg_separation: 2.1, catch_percentage: 0.77 },
  { player_name: 'Hunter Henry', posteam: 'NE', totalEPA: 5.1, tgt_share: 0.13, numYards: 547, conversion_rate: 0.34, explosive_rate: 0.08, avg_separation: 2.3, catch_percentage: 0.76 },
  { player_name: 'Cade Otton', posteam: 'TB', totalEPA: 5.7, tgt_share: 0.12, numYards: 511, conversion_rate: 0.37, explosive_rate: 0.10, avg_separation: 2.4, catch_percentage: 0.80 },
  { player_name: 'Tucker Kraft', posteam: 'GB', totalEPA: 6.1, tgt_share: 0.10, numYards: 355, conversion_rate: 0.38, explosive_rate: 0.12, avg_separation: 2.2, catch_percentage: 0.82 },
  { player_name: 'Dalton Kincaid', posteam: 'BUF', totalEPA: 4.8, tgt_share: 0.11, numYards: 356, conversion_rate: 0.33, explosive_rate: 0.09, avg_separation: 2.1, catch_percentage: 0.75 },
  { player_name: 'Cole Kmet', posteam: 'CHI', totalEPA: 4.2, tgt_share: 0.10, numYards: 473, conversion_rate: 0.32, explosive_rate: 0.08, avg_separation: 2.0, catch_percentage: 0.74 },
  { player_name: 'Isaiah Likely', posteam: 'BAL', totalEPA: 5.3, tgt_share: 0.09, numYards: 411, conversion_rate: 0.36, explosive_rate: 0.11, avg_separation: 2.3, catch_percentage: 0.79 },
];

async function importSampleTEData() {
  try {
    const collection = db.collection('te_rankings');
    
    // Clear existing data
    console.log('Clearing existing TE rankings...');
    const existingDocs = await collection.get();
    const batch = db.batch();
    existingDocs.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // Calculate tiers and rankings
    const processedData = sampleTEData.map((te, index) => ({
      ...te,
      season: '2024',
      te_tier: Math.ceil((index + 1) / 4), // 4 players per tier
      myRankNum: index + 1,
      te_rank: index + 1,
    }));

    // Import new data
    for (let i = 0; i < processedData.length; i += 10) {
      const batch = db.batch();
      const chunk = processedData.slice(i, i + 10);
      
      chunk.forEach(te => {
        const docRef = collection.doc();
        batch.set(docRef, te);
      });
      
      await batch.commit();
      console.log(`Imported batch ${Math.floor(i / 10) + 1}/${Math.ceil(processedData.length / 10)}`);
    }

    console.log(`Successfully imported ${processedData.length} TE rankings to Firestore`);
  } catch (error) {
    console.error('Error importing TE rankings:', error);
  }
}

// Run the import
if (require.main === module) {
  importSampleTEData()
    .then(() => {
      console.log('TE import completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('TE import failed:', error);
      process.exit(1);
    });
}

module.exports = { importSampleTEData }; 