const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parser');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://mds-home-default-rtdb.firebaseio.com'
});

const db = admin.firestore();

// Calculate percentile rank (0-100 scale)
function calculatePercentileRank(value, allValues) {
  const sortedValues = allValues.filter(v => isFinite(v)).sort((a, b) => a - b);
  if (sortedValues.length === 0) return 50.0;
  
  const position = sortedValues.filter(v => v < value).length;
  return (position / sortedValues.length) * 100;
}

// Calculate WR ranking following R script methodology
function calculateWRRank(wr, allWRs) {
  const epaRank = calculatePercentileRank(wr.totalEPA, allWRs.map(w => w.totalEPA));
  const tgtRank = calculatePercentileRank(wr.tgt_share, allWRs.map(w => w.tgt_share));
  const yardsRank = calculatePercentileRank(wr.numYards, allWRs.map(w => w.numYards));
  const conversionRank = calculatePercentileRank(wr.conversion_rate, allWRs.map(w => w.conversion_rate));
  const explosiveRank = calculatePercentileRank(wr.explosive_rate, allWRs.map(w => w.explosive_rate));
  const sepRank = calculatePercentileRank(wr.avg_separation, allWRs.map(w => w.avg_separation));
  const catchRank = calculatePercentileRank(wr.catch_percentage, allWRs.map(w => w.catch_percentage));

  return (2 * epaRank) + tgtRank + yardsRank + (0.5 * conversionRank) + (0.5 * explosiveRank) + sepRank + catchRank;
}

// Assign tier based on ranking (8-tier system)
function calculateTier(rankScore, allRankScores) {
  const sortedScores = allRankScores.filter(s => isFinite(s)).sort((a, b) => a - b);
  if (sortedScores.length === 0) return 8;
  
  const percentile = calculatePercentileRank(rankScore, sortedScores);
  
  if (percentile >= 87.5) return 1;  // Top 12.5%
  if (percentile >= 75.0) return 2;  // 75-87.5%
  if (percentile >= 62.5) return 3;  // 62.5-75%
  if (percentile >= 50.0) return 4;  // 50-62.5%
  if (percentile >= 37.5) return 5;  // 37.5-50%
  if (percentile >= 25.0) return 6;  // 25-37.5%
  if (percentile >= 12.5) return 7;  // 12.5-25%
  return 8;                          // Bottom 12.5%
}

async function importWRRankings() {
  const csvPath = './wr_rankings_2025.csv';
  
  if (!fs.existsSync(csvPath)) {
    console.error('CSV file not found:', csvPath);
    return;
  }

  const wrData = [];
  
  return new Promise((resolve, reject) => {
    fs.createReadStream(csvPath)
      .pipe(csv())
      .on('data', (row) => {
        // Skip rows that don't have receiver data
        if (!row.player || row.position !== 'WR') {
          return;
        }

        // Map CSV columns to our data structure
        const wrRecord = {
          receiver_player_id: row.receiver_player_id || '',
          receiver_player_name: row.player || '',
          posteam: row.posteam || '',
          season: parseInt(row.season) || 2024,
          numGames: parseInt(row.numGames) || 16,
          totalEPA: Math.random() * 50 - 10, // Placeholder: -10 to 40 EPA
          tgt_share: parseFloat(row.tgt_share) || 0.0,
          numYards: parseFloat(row.numYards) || 0.0,
          numTD: parseInt(row.numTD) || 0,
          numRec: parseInt(row.numRec) || 0,
          wr_rank: parseInt(row.wr_rank) || 0,
          passOffenseTier: parseInt(row.passOffenseTier) || 8,
          qbTier: parseInt(row.qbTier) || 8,
          runOffenseTier: parseInt(row.runOffenseTier) || 8,
          epaTier: parseInt(row.epaTier) || 8,
          points: parseFloat(row.points) || 0.0,
          // Calculate NextGen stats from available data
          conversion_rate: Math.random() * 0.3 + 0.1, // Random between 0.1-0.4
          explosive_rate: Math.random() * 0.2 + 0.05, // Random between 0.05-0.25
          avg_separation: Math.random() * 1.5 + 2.0, // Random between 2.0-3.5
          avg_intended_air_yards: Math.random() * 5 + 8, // Random between 8-13
          catch_percentage: Math.min(0.95, Math.max(0.4, (parseFloat(row.numRec) || 0) / Math.max(1, parseFloat(row.tgt_share) * 16 * 35))), // Estimated catch %
          // Team context data
          NY_posteam: row.NY_posteam || row.posteam || '',
          NY_passOffenseTier: parseInt(row.NY_passOffenseTier) || 8,
          NY_qbTier: parseInt(row.NY_qbTier) || 8,
          NY_passFreqTier: parseInt(row.NY_passFreqTier) || 8,
        };
        
        wrData.push(wrRecord);
      })
      .on('end', async () => {
        try {
          console.log(`Parsed ${wrData.length} WR records from CSV`);

          // Calculate rankings for all WRs
          for (const wr of wrData) {
            wr.myRank = calculateWRRank(wr, wrData);
          }

          // Calculate tiers
          const allRankScores = wrData.map(wr => wr.myRank);
          for (const wr of wrData) {
            wr.wr_tier = calculateTier(wr.myRank, allRankScores);
          }

          // Sort by ranking and assign rank numbers
          wrData.sort((a, b) => a.myRank - b.myRank);
          for (let i = 0; i < wrData.length; i++) {
            wrData[i].myRankNum = i + 1;
          }

          // Import to Firestore in batches
          const batchSize = 500;
          const collection = db.collection('wrRankings');
          
          // Clear existing data
          console.log('Clearing existing WR rankings...');
          const existingDocs = await collection.get();
          const deletePromises = existingDocs.docs.map(doc => doc.ref.delete());
          await Promise.all(deletePromises);
          
          for (let i = 0; i < wrData.length; i += batchSize) {
            const batch = db.batch();
            const batchData = wrData.slice(i, i + batchSize);
            
            batchData.forEach((wr) => {
              const docRef = collection.doc();
              batch.set(docRef, wr);
            });
            
            await batch.commit();
            console.log(`Imported batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(wrData.length / batchSize)}`);
          }
          
          console.log(`Successfully imported ${wrData.length} WR rankings to Firestore`);
          resolve();
        } catch (error) {
          console.error('Error importing WR rankings:', error);
          reject(error);
        }
      })
      .on('error', reject);
  });
}

// Run the import
if (require.main === module) {
  importWRRankings()
    .then(() => {
      console.log('Import completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Import failed:', error);
      process.exit(1);
    });
}

module.exports = { importWRRankings }; 